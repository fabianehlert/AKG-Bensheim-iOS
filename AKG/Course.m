//
//  Course.m
//  AKG
//
//  Created by Fabian Ehlert on 12.02.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "Course.h"

@implementation Course

- (NSString *)courseString
{
    return [self validCourseOfString];
}

+ (Course *)courseOfCourseString:(NSString *)str
{
    Course *crs = [[self alloc] init];
    
    if ([str characterAtIndex:0] == 't') {
        // TutorKurs
        NSMutableString *subjectString = [[NSMutableString alloc] init];
        NSMutableString *courseNumberString = [[NSMutableString alloc] init];

        for (NSUInteger i = 1; i < str.length; i++) {
            char c = [str characterAtIndex:i];
            
            if (c >= '0' && c <= '9') {
                [courseNumberString appendString:[NSString stringWithFormat:@"%c", c]];
            } else {
                [subjectString appendString:[NSString stringWithFormat:@"%c", c]];
            }
        }
        
        if ([Course subjectISLK:subjectString]) {
            crs.isTutor = YES;
            crs.isLK = YES;
            crs.subject = [Course subjectForShortLKString:subjectString];
            crs.courseNumberString = [Course courseNumberStringOfString:courseNumberString];
        } else {
            crs.isTutor = YES;
            crs.isLK = NO;
            crs.subject = [Course subjectForShortGKString:subjectString];
            crs.courseNumberString = [Course courseNumberStringOfString:courseNumberString];
        }
        
    } else {
        NSMutableString *subjectString = [[NSMutableString alloc] init];
        NSMutableString *courseNumberString = [[NSMutableString alloc] init];

        for (NSUInteger i = 0; i < str.length; i++) {
            char c = [str characterAtIndex:i];
            
            if (c >= '0' && c <= '9') {
                [courseNumberString appendString:[NSString stringWithFormat:@"%c", c]];
            } else {
                [subjectString appendString:[NSString stringWithFormat:@"%c", c]];
            }
        }
        
        if ([Course subjectISLK:subjectString]) {
            crs.isTutor = NO;
            crs.isLK = YES;
            crs.subject = [Course subjectForShortLKString:subjectString];
            crs.courseNumberString = [Course courseNumberStringOfString:courseNumberString];
        } else {
            crs.isTutor = NO;
            crs.isLK = NO;
            crs.subject = [Course subjectForShortGKString:subjectString];
            crs.courseNumberString = [Course courseNumberStringOfString:courseNumberString];
        }

    }
    
    return crs;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.subject forKey:@"subject"];
    [encoder encodeObject:self.courseNumberString forKey:@"courseNumberString"];
    
    [encoder encodeBool:self.isLK forKey:@"isLK"];
    [encoder encodeBool:self.isTutor forKey:@"isTutor"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super init])) {
        self.subject = [decoder decodeObjectForKey:@"subject"];
        self.courseNumberString = [decoder decodeObjectForKey:@"courseNumberString"];
        
        self.isLK = [decoder decodeBoolForKey:@"isLK"];
        self.isTutor = [decoder decodeBoolForKey:@"isTutor"];
    }
    return self;
}


#pragma mark - Private

- (NSString *)validCourseOfString
{
    if (self.isLK) {
        if (self.isTutor) {
            return [NSString stringWithFormat:@"t%@%@", [self shortLKStringOfSubjectString:self.subject], self.courseNumberString];
        } else {
            return [NSString stringWithFormat:@"%@%@", [self shortLKStringOfSubjectString:self.subject], self.courseNumberString];
        }
    } else {
        return [NSString stringWithFormat:@"%@%@", [self shortGKStringOfSubjectString:self.subject], [self validGKCourseNumberStringOfString:self.courseNumberString]];
    }
    
    return @"";
}

- (NSString *)validGKCourseNumberStringOfString:(NSString *)str
{
    if ([str characterAtIndex:0] != '0' && str.length == 1) {
        return [NSString stringWithFormat:@"0%@", str];
    } else {
        return str;
    }
    
    return @"";
}

#pragma mark - Porter

+ (BOOL)subjectISLK:(NSString *)str
{
    NSCharacterSet *set = [NSCharacterSet uppercaseLetterCharacterSet];
    if ([str rangeOfCharacterFromSet:set].location != NSNotFound) {
        return YES;
    }
    return NO;
}

+ (NSString *)courseNumberStringOfString:(NSString *)str
{
    if ([str characterAtIndex:0] == '0') {
        str = [str substringFromIndex:1];
    }
    return str;
}

+ (NSString *)subjectForShortGKString:(NSString *)str
{
    if ([str isEqualToString:@"bio"]) {
        return @"Biologie";
    } else if ([str isEqualToString:@"ch"]) {
        return @"Chemie";
    } else if ([str isEqualToString:@"d"]) {
        return @"Deutsch";
    } else if ([str isEqualToString:@"e"]) {
        return @"Englisch";
    } else if ([str isEqualToString:@"f"]) {
        return @"Französisch";
    } else if ([str isEqualToString:@"g"]) {
        return @"Geschichte";
    } else if ([str isEqualToString:@"gr"]) {
        return @"Griechisch";
    } else if ([str isEqualToString:@"l"]) {
        return @"Latein";
    } else if ([str isEqualToString:@"m"]) {
        return @"Mathematik";
    } else if ([str isEqualToString:@"mu"]) {
        return @"Musik";
    } else if ([str isEqualToString:@"ph"]) {
        return @"Physik";
    } else if ([str isEqualToString:@"pw"]) {
        return @"PoWi";
    } else if ([str isEqualToString:@"sp"]) {
        return @"Sport";
    } else if ([str isEqualToString:@"ek"]) {
        return @"Erdkunde";
    } else if ([str isEqualToString:@"eth"]) {
        return @"Ethik";
    } else if ([str isEqualToString:@"inf"]) {
        return @"Informatik";
    } else if ([str isEqualToString:@"ita"]) {
        return @"Italienisch";
    } else if ([str isEqualToString:@"ku"]) {
        return @"Kunst";
    } else if ([str isEqualToString:@"phil"]) {
        return @"Philosophie";
    } else if ([str isEqualToString:@"rev"]) {
        return @"Religion (evangelisch)";
    } else if ([str isEqualToString:@"rka"]) {
        return @"Religion (katholisch)";
    } else if ([str isEqualToString:@"spa"]) {
        return @"Spanisch";
    }
    
    return @"";
}

+ (NSString *)subjectForShortLKString:(NSString *)str
{
    if ([str isEqualToString:@"BIO"]) {
        return @"Biologie";
    } else if ([str isEqualToString:@"CH"]) {
        return @"Chemie";
    } else if ([str isEqualToString:@"D"]) {
        return @"Deutsch";
    } else if ([str isEqualToString:@"E"]) {
        return @"Englisch";
    } else if ([str isEqualToString:@"F"]) {
        return @"Französisch";
    } else if ([str isEqualToString:@"G"]) {
        return @"Geschichte";
    } else if ([str isEqualToString:@"Gr"]) {
        return @"Griechisch";
    } else if ([str isEqualToString:@"L"]) {
        return @"Latein";
    } else if ([str isEqualToString:@"M"]) {
        return @"Mathematik";
    } else if ([str isEqualToString:@"MU"]) {
        return @"Musik";
    } else if ([str isEqualToString:@"PH"]) {
        return @"Physik";
    } else if ([str isEqualToString:@"PW"]) {
        return @"PoWi";
    } else if ([str isEqualToString:@"SP"]) {
        return @"Sport";
    } else if ([str isEqualToString:@"EK"]) {
        return @"Erdkunde";
    } else if ([str isEqualToString:@"ETH"]) {
        return @"Ethik";
    } else if ([str isEqualToString:@"INF"]) {
        return @"Informatik";
    } else if ([str isEqualToString:@"ITA"]) {
        return @"Italienisch";
    } else if ([str isEqualToString:@"KU"]) {
        return @"Kunst";
    } else if ([str isEqualToString:@"PHIL"]) {
        return @"Philosophie";
    } else if ([str isEqualToString:@"REV"]) {
        return @"Religion (evangelisch)";
    } else if ([str isEqualToString:@"RKA"]) {
        return @"Religion (katholisch)";
    } else if ([str isEqualToString:@"SPA"]) {
        return @"Spanisch";
    }
    
    return @"";
}

#pragma mark -
- (NSString *)shortGKStringOfSubjectString:(NSString *)sbj
{
    if ([sbj isEqualToString:@"Biologie"]) {
        return @"bio";
    } else if ([sbj isEqualToString:@"Chemie"]) {
        return @"ch";
    } else if ([sbj isEqualToString:@"Deutsch"]) {
        return @"d";
    } else if ([sbj isEqualToString:@"Englisch"]) {
        return @"e";
    } else if ([sbj isEqualToString:@"Französisch"]) {
        return @"f";
    } else if ([sbj isEqualToString:@"Geschichte"]) {
        return @"g";
    } else if ([sbj isEqualToString:@"Griechisch"]) {
        return @"gr";
    } else if ([sbj isEqualToString:@"Latein"]) {
        return @"l";
    } else if ([sbj isEqualToString:@"Mathematik"]) {
        return @"m";
    } else if ([sbj isEqualToString:@"Musik"]) {
        return @"mu";
    } else if ([sbj isEqualToString:@"Physik"]) {
        return @"ph";
    } else if ([sbj isEqualToString:@"PoWi"]) {
        return @"pw";
    } else if ([sbj isEqualToString:@"Sport"]) {
        return @"sp";
    } else if ([sbj isEqualToString:@"Erdkunde"]) {
        return @"ek";
    } else if ([sbj isEqualToString:@"Ethik"]) {
        return @"eth";
    } else if ([sbj isEqualToString:@"Informatik"]) {
        return @"inf";
    } else if ([sbj isEqualToString:@"Italienisch"]) {
        return @"ita";
    } else if ([sbj isEqualToString:@"Kunst"]) {
        return @"ku";
    } else if ([sbj isEqualToString:@"Philosophie"]) {
        return @"phil";
    } else if ([sbj isEqualToString:@"Religion (evangelisch)"]) {
        return @"rev";
    } else if ([sbj isEqualToString:@"Religion (katholisch)"]) {
        return @"rka";
    } else if ([sbj isEqualToString:@"Spanisch"]) {
        return @"spa";
    }
    
    return @"";
}

- (NSString *)shortLKStringOfSubjectString:(NSString *)sbj
{
    if ([sbj isEqualToString:@"Biologie"]) {
        return @"BIO";
    } else if ([sbj isEqualToString:@"Chemie"]) {
        return @"CH";
    } else if ([sbj isEqualToString:@"Deutsch"]) {
        return @"D";
    } else if ([sbj isEqualToString:@"Englisch"]) {
        return @"E";
    } else if ([sbj isEqualToString:@"Französisch"]) {
        return @"F";
    } else if ([sbj isEqualToString:@"Geschichte"]) {
        return @"G";
    } else if ([sbj isEqualToString:@"Griechisch"]) {
        return @"Gr";
    } else if ([sbj isEqualToString:@"Latein"]) {
        return @"L";
    } else if ([sbj isEqualToString:@"Mathematik"]) {
        return @"M";
    } else if ([sbj isEqualToString:@"Musik"]) {
        return @"MU";
    } else if ([sbj isEqualToString:@"Physik"]) {
        return @"PH";
    } else if ([sbj isEqualToString:@"PoWi"]) {
        return @"PW";
    } else if ([sbj isEqualToString:@"Sport"]) {
        return @"SP";
    } else if ([sbj isEqualToString:@"Erdkunde"]) {
        return @"EK";
    } else if ([sbj isEqualToString:@"Ethik"]) {
        return @"ETH";
    } else if ([sbj isEqualToString:@"Informatik"]) {
        return @"INF";
    } else if ([sbj isEqualToString:@"Italienisch"]) {
        return @"ITA";
    } else if ([sbj isEqualToString:@"Kunst"]) {
        return @"KU";
    } else if ([sbj isEqualToString:@"Philosophie"]) {
        return @"PHIL";
    } else if ([sbj isEqualToString:@"Religion (evangelisch)"]) {
        return @"REV";
    } else if ([sbj isEqualToString:@"Religion (katholisch)"]) {
        return @"RKA";
    } else if ([sbj isEqualToString:@"Spanisch"]) {
        return @"SPA";
    }
    
    return @"";
}

@end
