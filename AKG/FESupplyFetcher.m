//
//  FESupplyFetcher.m
//  AKG
//
//  Created by Fabian Ehlert on 11.03.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "FESupplyFetcher.h"

#import "SupplyItem.h"
#import "SupplyHelper.h"

#import "Course.h"

#import "TFHpple.h"

@interface FESupplyFetcher ()

// ReadWrite copy properties of the readonly properties
@property (assign, nonatomic, readwrite) NSInteger todaySection;
@property (assign, nonatomic, readwrite) NSInteger tomorrowSection;

@property (strong, nonatomic, readwrite) NSArray *supplyArray;
@property (strong, nonatomic) NSArray *fullArray;

@end

@implementation FESupplyFetcher

+ (instancetype)sharedFetcher
{
    static FESupplyFetcher *fetcher;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fetcher = [[FESupplyFetcher alloc] init];
        fetcher.todaySection = -1;
        fetcher.tomorrowSection = -1;
    });
    return fetcher;
}


#pragma mark - Supply

- (void)loadSavedData
{
    NSUserDefaults *groupDefaults = [NSUserDefaults standardUserDefaults];
    NSData *savedData = [groupDefaults objectForKey:@"SUPPLY_DATA"];
    if (savedData) {
        NSMutableArray *mutableSavedArray = [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchiveObjectWithData:savedData]];
        self.fullArray = [NSArray arrayWithArray:mutableSavedArray];
        
        // Filter by date and lesson
        self.fullArray = [self.fullArray sortedArrayUsingComparator:^NSComparisonResult(SupplyItem *obj1, SupplyItem *obj2) {
            return [obj1.stunde caseInsensitiveCompare:obj2.stunde];
        }];
        
        self.fullArray = [self.fullArray sortedArrayUsingComparator:^NSComparisonResult(SupplyItem *obj1, SupplyItem *obj2) {
            return [obj1.datum compare:obj2.datum];
        }];
        
        self.supplyArray = [FESupplyFetcher filterArray:self.fullArray];
        
        self.todaySection = -1;
        self.tomorrowSection = -1;
        
        [self informDelegateAboutChangesOfType:FESupplyFetcherDataTypeOffline succeeded:YES];
        return;
    }
    [self informDelegateAboutChangesOfType:FESupplyFetcherDataTypeOffline succeeded:NO];
}

- (void)fetchNewData
{
    [self fetchSupplyData];
}


#pragma mark - Supply: Load

+ (NSURL *)supplyURLForWeek:(NSUInteger)week
{
    NSDateComponents *dateComponents;
    
    if (week == 0) {
        dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitWeekOfYear fromDate:[NSDate date]];
    } else if (week == 1) {
        dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitWeekOfYear fromDate:[NSDate dateWithTimeIntervalSinceNow:60*60*24*7]];
    }
    
    NSInteger calendarweek = [dateComponents weekOfYear];
    
    NSString *currentWeekString;
    
    if (calendarweek < 10) {
        currentWeekString = [NSString stringWithFormat:@"0%ld", (long)calendarweek];
    } else if (calendarweek >= 10) {
        currentWeekString = [NSString stringWithFormat:@"%ld", (long)calendarweek];
    }
    NSString *urlString = [NSString stringWithFormat:@"http://akg-bensheim.de/akgweb2011/content/Vertretung/w/%@/w00000.htm", currentWeekString];
    
    NSLog(@"url= %@", urlString);
    
    return [NSURL URLWithString:urlString];
}

- (void)fetchSupplyData
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSData *parseResultWeek0 = [[NSData alloc] initWithContentsOfURL:[FESupplyFetcher supplyURLForWeek:0]];
    NSData *parseResultWeek1 = [[NSData alloc] initWithContentsOfURL:[FESupplyFetcher supplyURLForWeek:1]];
    
    NSMutableArray *supplyArray = [[NSMutableArray alloc] init];
    
    if (!parseResultWeek0 && !parseResultWeek1) {
        self.supplyArray = @[];
        [self informDelegateAboutChangesOfType:FESupplyFetcherDataTypeOnline succeeded:NO];
        [FESupplyFetcher saveContext];
        return;
    } else if (parseResultWeek0 != nil && parseResultWeek1 == nil) {
        TFHpple *path0 = [[TFHpple alloc] initWithHTMLData:parseResultWeek0];
        
        NSArray *rawSupplyArray0 = [path0 searchWithXPathQuery:@"//table[@class='subst']/tr/td"];
        
        for (TFHppleElement *item in rawSupplyArray0) {
            if ([item.content isEqualToString:@""] || item.content == nil) {
                [supplyArray addObject:@"---"];
            } else if (![item.content isEqualToString:@"Vertretungen sind nicht freigegeben"] && ![item.content isEqualToString:@"Keine Vertretungen"]) {
                [supplyArray addObject:item.content];
            }
        }
    } else if (parseResultWeek0 == nil && parseResultWeek1 != nil) {
        TFHpple *path1 = [[TFHpple alloc] initWithHTMLData:parseResultWeek1];
        
        NSArray *rawSupplyArray1 = [path1 searchWithXPathQuery:@"//table[@class='subst']/tr/td"];
        
        for (TFHppleElement *item in rawSupplyArray1) {
            if ([item.content isEqualToString:@""] || item.content == nil) {
                [supplyArray addObject:@"---"];
            } else if (![item.content isEqualToString:@"Vertretungen sind nicht freigegeben"] && ![item.content isEqualToString:@"Keine Vertretungen"]) {
                [supplyArray addObject:item.content];
            }
        }
    } else if (parseResultWeek0 != nil && parseResultWeek1 != nil) {
        TFHpple *path0 = [[TFHpple alloc] initWithHTMLData:parseResultWeek0];
        TFHpple *path1 = [[TFHpple alloc] initWithHTMLData:parseResultWeek1];
        
        NSArray *rawSupplyArray0 = [path0 searchWithXPathQuery:@"//table[@class='subst']/tr/td"];
        NSArray *rawSupplyArray1 = [path1 searchWithXPathQuery:@"//table[@class='subst']/tr/td"];
        
        for (TFHppleElement *item in rawSupplyArray0) {
            if ([item.content isEqualToString:@""] || item.content == nil) {
                [supplyArray addObject:@"---"];
            } else if (![item.content isEqualToString:@"Vertretungen sind nicht freigegeben"] && ![item.content isEqualToString:@"Keine Vertretungen"]) {
                [supplyArray addObject:item.content];
            }
        }
        
        for (TFHppleElement *item in rawSupplyArray1) {
            if ([item.content isEqualToString:@""] || item.content == nil) {
                [supplyArray addObject:@"---"];
            } else if (![item.content isEqualToString:@"Vertretungen sind nicht freigegeben"] && ![item.content isEqualToString:@"Keine Vertretungen"]) {
                [supplyArray addObject:item.content];
            }
        }
    }
    
    NSMutableArray *schoolClassArray = [[NSMutableArray alloc] init];
    NSMutableArray *dateArray = [[NSMutableArray alloc] init];
    NSMutableArray *lessonArray = [[NSMutableArray alloc] init];
    NSMutableArray *typeArray = [[NSMutableArray alloc] init];
    NSMutableArray *subjectNewArray = [[NSMutableArray alloc] init];
    NSMutableArray *subjectOldArray = [[NSMutableArray alloc] init];
    NSMutableArray *roomNewArray = [[NSMutableArray alloc] init];
    NSMutableArray *roomOldArray = [[NSMutableArray alloc] init];
    NSMutableArray *informationArray = [[NSMutableArray alloc] init];
    
    if (supplyArray.count == 0 || supplyArray.count <= 5) {
        NSLog(@"Supply data: error (%lu objects)", (unsigned long)[supplyArray count]);
        
        self.fullArray = @[];
        self.supplyArray = [FESupplyFetcher filterArray:[NSMutableArray arrayWithArray:self.fullArray]];
        
        self.todaySection = -1;
        self.tomorrowSection = -1;
        
        [self informDelegateAboutChangesOfType:FESupplyFetcherDataTypeOnline succeeded:YES];
        [FESupplyFetcher saveContext];
        
    } else {
        for (NSUInteger i = 0; i <= [supplyArray count] - 8; i = i + 9) {
            [schoolClassArray addObject:[supplyArray objectAtIndex:i]];
        }
        
        for (NSUInteger i = 1; i <= [supplyArray count] - 7; i = i + 9) {
            [dateArray addObject:[supplyArray objectAtIndex:i]];
        }
        
        for (NSUInteger i = 2; i <= [supplyArray count] - 6; i = i + 9) {
            [lessonArray addObject:[supplyArray objectAtIndex:i]];
        }
        
        for (NSUInteger i = 3; i <= [supplyArray count] - 5; i = i + 9) {
            [typeArray addObject:[supplyArray objectAtIndex:i]];
        }
        
        for (NSUInteger i = 4; i <= [supplyArray count] - 4; i = i + 9) {
            [subjectOldArray addObject:[supplyArray objectAtIndex:i]];
        }
        
        for (NSUInteger i = 5; i <= [supplyArray count] - 3; i = i + 9) {
            [subjectNewArray addObject:[supplyArray objectAtIndex:i]];
        }
        
        for (NSUInteger i = 6; i <= [supplyArray count] - 2; i = i + 9) {
            [roomOldArray addObject:[supplyArray objectAtIndex:i]];
        }
        
        for (NSUInteger i = 7; i <= [supplyArray count] - 1; i = i + 9) {
            [roomNewArray addObject:[supplyArray objectAtIndex:i]];
        }
        
        for (NSUInteger i = 8; i <= [supplyArray count] - 1; i = i + 9) {
            [informationArray addObject:[supplyArray objectAtIndex:i]];
        }
        
        NSMutableArray *mutableSupplyArray = [[NSMutableArray alloc] init];
        
        for (NSUInteger i = 0; i < [schoolClassArray count]; i++) {
            NSString *dateString = dateArray[i];
            NSString *typeString = [SupplyHelper displayTypeForType:typeArray[i]];
            NSString *schoolClassString = [FESupplyFetcher validStringOfString:schoolClassArray[i]];
            
            NSString *lessonString = [FESupplyFetcher validStringOfString:lessonArray[i]];
            lessonString = [lessonString stringByReplacingOccurrencesOfString:@" " withString:@""];
            
            NSString *roomOldString = [FESupplyFetcher roomStringByCuttingOffCharacterROfString:roomOldArray[i]];
            NSString *roomNewString = [FESupplyFetcher roomStringByCuttingOffCharacterROfString:roomNewArray[i]];
            NSString *subjectOldString = [FESupplyFetcher validStringOfString:subjectOldArray[i]];
            NSString *subjectNewString = [FESupplyFetcher validStringOfString:subjectNewArray[i]];
            NSString *informationString = [FESupplyFetcher validInformationStringOfString:informationArray[i]];
            
            NSDateFormatter *year = [[NSDateFormatter alloc] init];
            [year setLocale:[NSLocale localeWithLocaleIdentifier:@"de_DE"]];
            
            [year setDateFormat:@"yyyy"];
            NSString *currentYear = [year stringFromDate:[NSDate date]];
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setLocale:[NSLocale localeWithLocaleIdentifier:@"de_DE"]];
            [formatter setDateFormat:@"dd.MM.yyyy-HH:mm:ss"];
            
            if (![dateString isEqualToString:@"---"] && ![dateString isEqualToString:@""] && dateString != nil) {
                NSDate *date = [formatter dateFromString:[NSString stringWithFormat:@"%@%@-07:00:00", dateString, currentYear]];
                
                SupplyItem *supply = [[SupplyItem alloc] init];
                
                supply.datum = date;
                supply.art = typeString;
                supply.klasse = schoolClassString;
                supply.stunde = lessonString;
                supply.alterRaum = roomOldString;
                supply.neuerRaum = roomNewString;
                supply.altesFach = subjectOldString;
                supply.neuesFach = subjectNewString;
                supply.info = informationString;
                [supply setupUUID];
                
                [mutableSupplyArray addObject:supply];
            }
        }
        
        self.fullArray = [NSArray arrayWithArray:mutableSupplyArray];
        
        // Filter by date and lesson
        self.fullArray = [self.fullArray sortedArrayUsingComparator:^NSComparisonResult(SupplyItem *obj1, SupplyItem *obj2) {
            return [obj1.stunde caseInsensitiveCompare:obj2.stunde];
        }];
        
        self.fullArray = [self.fullArray sortedArrayUsingComparator:^NSComparisonResult(SupplyItem *obj1, SupplyItem *obj2) {
            return [obj1.datum compare:obj2.datum];
        }];
        
        self.supplyArray = [FESupplyFetcher filterArray:self.fullArray];
        
        
        NSUserDefaults *groupDefaults = [NSUserDefaults standardUserDefaults];
        NSInteger count = self.supplyArray.count;
        [groupDefaults setInteger:count forKey:@"SUPPLY_GLANCE_COUNT"];
        [groupDefaults synchronize];
        
        
        self.todaySection = -1;
        self.tomorrowSection = -1;
        
        [self informDelegateAboutChangesOfType:FESupplyFetcherDataTypeOnline succeeded:YES];
        [FESupplyFetcher saveContext];
    }
}

/// Notification use only!!!
+ (NSArray *)latestSupplyArray
{
    NSData *parseResultWeek0 = [[NSData alloc] initWithContentsOfURL:[FESupplyFetcher supplyURLForWeek:0]];
    NSData *parseResultWeek1 = [[NSData alloc] initWithContentsOfURL:[FESupplyFetcher supplyURLForWeek:1]];
    
    NSMutableArray *supplyArray = [[NSMutableArray alloc] init];
    
    if (parseResultWeek0 == nil && parseResultWeek1 == nil) {
        return @[];
    } else if (parseResultWeek0 != nil && parseResultWeek1 == nil) {
        TFHpple *path0 = [[TFHpple alloc] initWithHTMLData:parseResultWeek0];
        
        NSArray *rawSupplyArray0 = [path0 searchWithXPathQuery:@"//table[@class='subst']/tr/td"];
        
        for (TFHppleElement *item in rawSupplyArray0) {
            if ([item.content isEqualToString:@""] || item.content == nil) {
                [supplyArray addObject:@"---"];
            } else if (![item.content isEqualToString:@"Vertretungen sind nicht freigegeben"] && ![item.content isEqualToString:@"Keine Vertretungen"]) {
                [supplyArray addObject:item.content];
            }
        }
    } else if (parseResultWeek0 == nil && parseResultWeek1 != nil) {
        TFHpple *path1 = [[TFHpple alloc] initWithHTMLData:parseResultWeek1];
        
        NSArray *rawSupplyArray1 = [path1 searchWithXPathQuery:@"//table[@class='subst']/tr/td"];
        
        for (TFHppleElement *item in rawSupplyArray1) {
            if ([item.content isEqualToString:@""] || item.content == nil) {
                [supplyArray addObject:@"---"];
            } else if (![item.content isEqualToString:@"Vertretungen sind nicht freigegeben"] && ![item.content isEqualToString:@"Keine Vertretungen"]) {
                [supplyArray addObject:item.content];
            }
        }
    } else if (parseResultWeek0 != nil && parseResultWeek1 != nil) {
        TFHpple *path0 = [[TFHpple alloc] initWithHTMLData:parseResultWeek0];
        TFHpple *path1 = [[TFHpple alloc] initWithHTMLData:parseResultWeek1];
        
        NSArray *rawSupplyArray0 = [path0 searchWithXPathQuery:@"//table[@class='subst']/tr/td"];
        NSArray *rawSupplyArray1 = [path1 searchWithXPathQuery:@"//table[@class='subst']/tr/td"];
        
        
        for (TFHppleElement *item in rawSupplyArray0) {
            if ([item.content isEqualToString:@""] || item.content == nil) {
                [supplyArray addObject:@"---"];
            } else if (![item.content isEqualToString:@"Vertretungen sind nicht freigegeben"] && ![item.content isEqualToString:@"Keine Vertretungen"]) {
                [supplyArray addObject:item.content];
            }
        }
        
        for (TFHppleElement *item in rawSupplyArray1) {
            NSLog(@"xITMx= %@", item.content);
            if ([item.content isEqualToString:@""] || item.content == nil) {
                [supplyArray addObject:@"---"];
            } else if (![item.content isEqualToString:@"Vertretungen sind nicht freigegeben"] && ![item.content isEqualToString:@"Keine Vertretungen"]) {
                [supplyArray addObject:item.content];
            }
        }
    }
    
    NSMutableArray *schoolClassArray = [[NSMutableArray alloc] init];
    NSMutableArray *dateArray = [[NSMutableArray alloc] init];
    NSMutableArray *lessonArray = [[NSMutableArray alloc] init];
    NSMutableArray *typeArray = [[NSMutableArray alloc] init];
    NSMutableArray *subjectNewArray = [[NSMutableArray alloc] init];
    NSMutableArray *subjectOldArray = [[NSMutableArray alloc] init];
    NSMutableArray *roomNewArray = [[NSMutableArray alloc] init];
    NSMutableArray *roomOldArray = [[NSMutableArray alloc] init];
    NSMutableArray *informationArray = [[NSMutableArray alloc] init];
    
    if (supplyArray.count == 0 || supplyArray.count <= 5) {
        NSLog(@"Supply data: error (%lu objects)", (unsigned long)[supplyArray count]);
    } else {
        for (NSUInteger i = 0; i <= [supplyArray count] - 8; i = i + 9) {
            [schoolClassArray addObject:[supplyArray objectAtIndex:i]];
        }
        
        for (NSUInteger i = 1; i <= [supplyArray count] - 7; i = i + 9) {
            [dateArray addObject:[supplyArray objectAtIndex:i]];
        }
        
        for (NSUInteger i = 2; i <= [supplyArray count] - 6; i = i + 9) {
            [lessonArray addObject:[supplyArray objectAtIndex:i]];
        }
        
        for (NSUInteger i = 3; i <= [supplyArray count] - 5; i = i + 9) {
            [typeArray addObject:[supplyArray objectAtIndex:i]];
        }
        
        for (NSUInteger i = 4; i <= [supplyArray count] - 4; i = i + 9) {
            [subjectOldArray addObject:[supplyArray objectAtIndex:i]];
        }
        
        for (NSUInteger i = 5; i <= [supplyArray count] - 3; i = i + 9) {
            [subjectNewArray addObject:[supplyArray objectAtIndex:i]];
        }
        
        for (NSUInteger i = 6; i <= [supplyArray count] - 2; i = i + 9) {
            [roomOldArray addObject:[supplyArray objectAtIndex:i]];
        }
        
        for (NSUInteger i = 7; i <= [supplyArray count] - 1; i = i + 9) {
            [roomNewArray addObject:[supplyArray objectAtIndex:i]];
        }
        
        for (NSUInteger i = 8; i <= [supplyArray count] - 1; i = i + 9) {
            [informationArray addObject:[supplyArray objectAtIndex:i]];
        }
        
        
        NSMutableArray *mutableSupplyArray = [[NSMutableArray alloc] init];
        
        for (NSUInteger i = 0; i < [schoolClassArray count]; i++) {
            NSString *dateString = dateArray[i];
            NSString *typeString = [SupplyHelper displayTypeForType:typeArray[i]];
            NSString *schoolClassString = [FESupplyFetcher validStringOfString:schoolClassArray[i]];
            
            NSString *lessonString = [FESupplyFetcher validStringOfString:lessonArray[i]];
            lessonString = [lessonString stringByReplacingOccurrencesOfString:@" " withString:@""];
            
            NSString *roomOldString = [FESupplyFetcher roomStringByCuttingOffCharacterROfString:roomOldArray[i]];
            NSString *roomNewString = [FESupplyFetcher roomStringByCuttingOffCharacterROfString:roomNewArray[i]];
            NSString *subjectOldString = [FESupplyFetcher validStringOfString:subjectOldArray[i]];
            NSString *subjectNewString = [FESupplyFetcher validStringOfString:subjectNewArray[i]];
            NSString *informationString = [FESupplyFetcher validInformationStringOfString:informationArray[i]];
            
            NSDateFormatter *year = [[NSDateFormatter alloc] init];
            [year setLocale:[NSLocale localeWithLocaleIdentifier:@"de_DE"]];
            [year setDateFormat:@"yyyy"];
            NSString *currentYear = [year stringFromDate:[NSDate date]];
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setLocale:[NSLocale localeWithLocaleIdentifier:@"de_DE"]];
            [formatter setDateFormat:@"dd.MM.yyyy-HH:mm:ss"];
            
            if (![dateString isEqualToString:@"---"] && ![dateString isEqualToString:@""] && dateString != nil) {
                NSDate *date = [formatter dateFromString:[NSString stringWithFormat:@"%@%@-07:00:00", dateString, currentYear]];
                
                SupplyItem *supply = [[SupplyItem alloc] init];
                
                supply.datum = date;
                supply.art = typeString;
                supply.klasse = schoolClassString;
                supply.stunde = lessonString;
                supply.alterRaum = roomOldString;
                supply.neuerRaum = roomNewString;
                supply.altesFach = subjectOldString;
                supply.neuesFach = subjectNewString;
                supply.info = informationString;
                [supply setupUUID];
                
                [mutableSupplyArray addObject:supply];
            }
        }
        
        [FESupplyFetcher sharedFetcher].supplyArray = [FESupplyFetcher filterArray:mutableSupplyArray];
        [FESupplyFetcher saveContext];
        
        return [FESupplyFetcher sharedFetcher].supplyArray;
    }
    return @[];
}


#pragma mark - Helper

+ (NSString *)validStringOfString:(NSString *)str
{
    if ([str isEqualToString:@"---"]) {
        return @"–";
    }
    return str;
}

+ (NSString *)validInformationStringOfString:(NSString *)str
{
    if ([str isEqualToString:@"---"]) {
        return @"Keine Anmerkungen";
    }
    
    return str;
}

+ (NSString *)roomStringByCuttingOffCharacterROfString:(NSString *)str
{
    if ([str isEqualToString:@"---"]) {
        return @"–";
    }
    
    char firstChar = [str characterAtIndex:0];
    
    if (firstChar == 'R') {
        str = [str stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
    }
    
    return str;
}


#pragma mark - Filter

+ (NSArray *)filterArray:(NSArray *)array
{
    NSArray *returnArray = nil;
    NSPredicate *filterPredicate = nil;
    
    NSMutableArray *arrayCopy = [array mutableCopy];
    NSMutableArray *klassenToDelete = [NSMutableArray array];
    
    for (SupplyItem *supply in arrayCopy)
    {
        NSString *klasse = supply.klasse;
        
        if ([klasse isEqualToString:@"---"]) {
            [klassenToDelete addObject:supply];
        }
    }
    
    [arrayCopy removeObjectsInArray:klassenToDelete];
    
    NSUserDefaults *groupDefaults = [NSUserDefaults standardUserDefaults];
    NSString *filterString = [groupDefaults objectForKey:@"klassefilterstring"];
    
    NSString *stufe;
    NSString *token;
    
    NSMutableString *stufeString = [[NSMutableString alloc] init];
    
    if ([filterString isEqualToString:@"Alle"]) {
        stufe = @"";
    } else if ([filterString isEqualToString:@"K_Abi"]) {
        stufe = @"K_Abi";
    } else {
        for (NSUInteger i = 0; i < filterString.length; i++)
        {
            char c = (char) [filterString characterAtIndex:i];
            if (c >= '0' && c <= '9') {
                [stufeString appendString:[NSString stringWithFormat:@"%c", c]];
            }
        }
        
        stufe = stufeString;
    }
    
    if ([filterString isEqualToString:@"Alle"] || [filterString isEqualToString:@"10"] || [filterString isEqualToString:@"11"] || [filterString isEqualToString:@"12"] || [filterString isEqualToString:@"13"] || [filterString isEqualToString:@"K_Abi"]) {
        token = @"";
    } else {
        if (filterString.length > 1) {
            token = [NSString stringWithFormat:@"%c", [filterString characterAtIndex:filterString.length - 1]];
        } else {
            token = @"";
        }
    }
    
    if ([filterString isEqualToString:@"Alle"]) {
        filterPredicate = [NSPredicate predicateWithFormat:@"klasse != nil"];
    } else if ([token isEqualToString:@""] || token == nil) {
        filterPredicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"(klasse contains '%@')", stufe]];
    } else {
        filterPredicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"(klasse contains '%@') AND (klasse contains '%@')", stufe, token]];
    }
    
    returnArray = [arrayCopy filteredArrayUsingPredicate:filterPredicate];
    
    if ([groupDefaults boolForKey:@"SHOULD_FILTER_COURSES"]) {
        if ([filterString isEqualToString:@"Alle"] || [filterString isEqualToString:@"10"] || [filterString isEqualToString:@"11"] || [filterString isEqualToString:@"12"] || [filterString isEqualToString:@"13"] || [filterString isEqualToString:@"K_Abi"]) {
            
            NSData *savedData = [groupDefaults objectForKey:[NSString stringWithFormat:@"COURSES_ARRAY"]];
            NSArray *kurse = @[];
            
            if (savedData) {
                NSArray *coursesArray = [NSKeyedUnarchiver unarchiveObjectWithData:savedData];
                NSMutableArray *mutableCourses = [[NSMutableArray alloc] init];
                for (Course *crs in coursesArray) {
                    [mutableCourses addObject:[crs courseString]];
                }
                kurse = [NSArray arrayWithArray:mutableCourses];
            }
            
            NSMutableArray *objToAdd = [[NSMutableArray alloc] init];
            
            for (SupplyItem *supply in returnArray)
            {
                if ([[supply.neuerRaum description] isEqualToString:@"Mensa"] || [[supply.neuerRaum description] isEqualToString:@"Thea"]) {
                    if ([[supply.alterRaum description] isEqualToString:@"---"] && [[supply.altesFach description] isEqualToString:@"---"] && [[supply.neuesFach description] isEqualToString:@"---"]) {
                        [objToAdd addObject:supply];
                    }
                }
                
                for (NSString *kurs in kurse)
                {
                    if ([[supply.neuesFach description] isEqualToString:kurs] || [[supply.altesFach description] isEqualToString:kurs]) {
                        [objToAdd addObject:supply];
                    }
                }
            }
            
            returnArray = [NSArray arrayWithArray:objToAdd];
        }
    }
    
    return returnArray;
}


#pragma mark - SAVE & Notify Delegate

- (void)informDelegateAboutChangesOfType:(FESupplyFetcherDataType)type succeeded:(BOOL)success
{
    if ([self.delegate respondsToSelector:@selector(supplyFetcherDataChanged:finishedLoadingDataOfType:success:)]) {
        [self.delegate supplyFetcherDataChanged:self finishedLoadingDataOfType:type success:success];
    }
}

+ (void)saveContext
{
    NSUserDefaults *groupDefaults = [NSUserDefaults standardUserDefaults];
    [groupDefaults setObject:[NSKeyedArchiver archivedDataWithRootObject:[FESupplyFetcher sharedFetcher].fullArray] forKey:@"SUPPLY_DATA"];
    [groupDefaults synchronize];
}


#pragma mark - Sections

- (void)setTodayAndTomorrowSectionValuesWithInfoArray:(NSMutableArray *)array
{
    NSDateFormatter *currentDateFormatter = [[NSDateFormatter alloc] init];
    [currentDateFormatter setDateFormat:@"dd.MM.yyyy"];
    
    NSDate *today = [NSDate date];
    NSString *todayString = [currentDateFormatter stringFromDate:today];
    
    for (NSUInteger c = 0; c < [array count]; c++) {
        NSString *aDate = [[array objectAtIndex:c] objectForKey:@"sectionDate"];
        
        if ([aDate isEqualToString:todayString]) {
            self.todaySection = c;
        }
    }
    
    
    NSDate *tomorrow = [[NSDate date] dateByAddingTimeInterval:60*60*24];
    NSString *tomorrowString = [currentDateFormatter stringFromDate:tomorrow];
    
    for (NSUInteger c = 0; c < [array count]; c++) {
        NSString *aDate = [[array objectAtIndex:c] objectForKey:@"sectionDate"];
        
        if ([aDate isEqualToString:tomorrowString]) {
            self.tomorrowSection = c;
        }
    }
}

- (NSMutableArray *)sectionInformation
{
    NSMutableArray *returnArray = [[NSMutableArray alloc] init];
    NSMutableArray *allDates = [[NSMutableArray alloc] init];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd.MM.yyyy"];
    
    [self.supplyArray enumerateObjectsUsingBlock:^(SupplyItem *item, NSUInteger idx, BOOL *stop) {
        NSString *currentDateString = [dateFormatter stringFromDate:item.datum];
        
#pragma mark - is nil when 24hr is turned off
        NSLog(@"DATUM= %@", item.datum);
        
        if (idx == 0 && currentDateString != nil) {
            [allDates addObject:currentDateString];
        }
        
        if (idx > 0) {
            SupplyItem *prevSpl = self.supplyArray[idx - 1];
            NSString *prevObject = [dateFormatter stringFromDate:prevSpl.datum];
            
            NSLog(@"currentDateString= %@", currentDateString);
            
            if (![prevObject isEqualToString:currentDateString] && ![prevObject isEqualToString:@"---"] && ![currentDateString isEqualToString:@"---"] && currentDateString != nil) {
                [allDates addObject:currentDateString];
            }
        }
    }];
    
    __block NSUInteger itemsInSection;
    
    for (NSString *dateObject in allDates) {
        itemsInSection = 0;
        
        [self.supplyArray enumerateObjectsUsingBlock:^(SupplyItem *item, NSUInteger idx, BOOL *stop) {
            NSString *currentDateString = [dateFormatter stringFromDate:item.datum];
            
            if ([currentDateString isEqualToString:dateObject]) {
                itemsInSection++;
            }
        }];
        
        NSDictionary *secDict = @{@"sectionDate": dateObject, @"itemsInSection": [NSNumber numberWithInteger:itemsInSection]};
        
        [returnArray addObject:secDict];
    }
    
    [self setTodayAndTomorrowSectionValuesWithInfoArray:returnArray];
    
    return returnArray;
}

@end
