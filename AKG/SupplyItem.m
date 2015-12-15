//
//  Supply.m
//  AKG
//
//  Created by Fabian Ehlert on 21.10.13.
//  Copyright (c) 2013 Fabian Ehlert. All rights reserved.
//

#import "SupplyItem.h"

@interface SupplyItem ()

@property (strong, nonatomic, readwrite) NSString *uuid;

@end

@implementation SupplyItem

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.art forKey:@"art"];
    [encoder encodeObject:self.klasse forKey:@"klasse"];
    [encoder encodeObject:self.datum forKey:@"datum"];
    [encoder encodeObject:self.stunde forKey:@"stunde"];
    [encoder encodeObject:self.alterRaum forKey:@"alterRaum"];
    [encoder encodeObject:self.neuerRaum forKey:@"neuerRaum"];
    [encoder encodeObject:self.altesFach forKey:@"altesFach"];
    [encoder encodeObject:self.neuesFach forKey:@"neuesFach"];
    [encoder encodeObject:self.info forKey:@"info"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super init]))
    {
        self.art = [decoder decodeObjectForKey:@"art"];
        self.klasse = [decoder decodeObjectForKey:@"klasse"];
        self.datum = [decoder decodeObjectForKey:@"datum"];
        self.stunde = [decoder decodeObjectForKey:@"stunde"];
        self.alterRaum = [decoder decodeObjectForKey:@"alterRaum"];
        self.neuerRaum = [decoder decodeObjectForKey:@"neuerRaum"];
        self.altesFach = [decoder decodeObjectForKey:@"altesFach"];
        self.neuesFach = [decoder decodeObjectForKey:@"neuesFach"];
        self.info = [decoder decodeObjectForKey:@"info"];
    }
    return self;
}

- (void)setupUUID
{
    self.uuid = [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@", self.klasse, self.altesFach, self.neuesFach, self.alterRaum, self.neuerRaum, self.datum, self.stunde, self.info];
}

#pragma mark - Reminder

- (NSString *)titleForReminder
{
    NSString *finalKlasse = @"";
    
    if ([self.klasse rangeOfString:@"K0"].location == NSNotFound) {
        finalKlasse = self.klasse;
    } else {
        finalKlasse = [self.klasse stringByReplacingOccurrencesOfString:@"K0" withString:@""];
    }
    
    NSString *reminderTitle = @"";
    
    if ([self.art isEqualToString:@"Fällt aus!"]) {
        reminderTitle = [NSString stringWithFormat:@"%@: %@.Std. fällt aus! (%@)", self.klasse, self.stunde, self.datum];
    } else if ([self.art isEqualToString:@"Freisetzung"]) {
        reminderTitle = [NSString stringWithFormat:@"%@: Freisetzung in der %@.Std. (%@)", self.klasse, self.stunde, self.datum];
    } else if ([self.art isEqualToString:@"Vertretung"]) {
        reminderTitle = [NSString stringWithFormat:@"%@: Vertretung in der %@.Std. (%@)", self.klasse, self.stunde, self.datum];
    } else {
        reminderTitle = [NSString stringWithFormat:@"%@: %@.Std.: %@ (%@)", self.klasse, self.stunde, self.art, self.datum];
    }

    return reminderTitle;
}

- (NSString *)noteForReminder
{
    NSString *finalKlasse = @"";
    
    if ([self.klasse rangeOfString:@"K0"].location == NSNotFound) {
        finalKlasse = self.klasse;
    } else {
        finalKlasse = [self.klasse stringByReplacingOccurrencesOfString:@"K0" withString:@""];
    }
    
    NSString *reminderNote = @"";
    
    if ([self.art isEqualToString:@"Fällt aus!"]) {
        if ([self.info isEqualToString:@"---"]) {
            reminderNote = [NSString stringWithFormat:@"Klasse %@: %@ am %@ in der %@.Stunde fällt aus.", finalKlasse, self.altesFach, self.datum, self.stunde];
        } else {
            reminderNote = [NSString stringWithFormat:@"Klasse %@: %@ am %@ in der %@.Stunde fällt aus. Weitere Hinweise:%@", finalKlasse, self.altesFach, self.datum, self.stunde, self.info];
        }
    } else if ([self.art isEqualToString:@"Freisetzung"]) {
        if ([self.info isEqualToString:@"---"]) {
            reminderNote = [NSString stringWithFormat:@"Klasse %@ ist am %@ in der %@.Stunde vom Unterricht freigestellt.", finalKlasse, self.datum, self.stunde];
        } else {
            reminderNote = [NSString stringWithFormat:@"Klasse %@ ist am %@ in der %@.Stunde vom Unterricht freigestellt. Weitere Hinweise:%@", finalKlasse, self.datum, self.stunde, self.info];
        }
    } else if ([self.art isEqualToString:@"Vertretung"]) {
        if ([self.info isEqualToString:@"---"]) {
            reminderNote = [NSString stringWithFormat:@"Klasse %@, %@ - %@.Std.: Das Fach %@ wird durch das Fach %@ in Raum %@ vertreten.", finalKlasse, self.datum, self.stunde, self.altesFach, self.neuesFach, self.neuesFach];
        } else {
            reminderNote = [NSString stringWithFormat:@"Klasse %@, %@ - %@.Std.: Das Fach %@ wird durch das Fach %@ in Raum %@ vertreten.\nWeitere Hinweise: %@", finalKlasse, self.datum, self.stunde, self.altesFach, self.neuesFach, self.neuerRaum, self.info];
        }
    } else {
        if ([self.info isEqualToString:@"---"]) {
            reminderNote = [NSString stringWithFormat:@"Klasse %@, %@ - %@.Std.: Das Fach %@ wird durch das Fach %@ in Raum %@ vertreten.", finalKlasse, self.datum, self.stunde, self.altesFach, self.neuesFach, self.neuerRaum];
        } else {
            reminderNote = [NSString stringWithFormat:@"Klasse %@, %@ - %@.Std.: Das Fach %@ wird durch das Fach %@ in Raum %@ vertreten.\nWeitere Hinweise: %@", finalKlasse, self.datum, self.stunde, self.altesFach, self.neuesFach, self.neuerRaum, self.info];
        }
    }

    return reminderNote;
}


#pragma mark - CellForRowAtIndexPath

- (NSString *)validLesson
{
    NSString *validString = self.stunde;
    
    if ([validString isEqualToString:@"---"]) {
        return @"–";
    }
    return [validString stringByReplacingOccurrencesOfString:@" " withString:@""];
}

- (NSString *)validAlterRaum
{
    NSString *validString = self.alterRaum;
    
    if ([validString isEqualToString:@"---"]) {
        return @"–";
    }
    
    char firstChar = [validString characterAtIndex:0];
    
    if (firstChar == 'R') {
        validString = [validString stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
    }

    return validString;
}

- (NSString *)validNeuerRaum
{
    NSString *validString = self.neuerRaum;
    
    if ([validString isEqualToString:@"---"]) {
        return @"–";
    }
    
    char firstChar = [validString characterAtIndex:0];
    
    if (firstChar == 'R') {
        validString = [validString stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
    }

    return validString;
}

- (NSString *)validOldSubject
{
    NSString *validString = self.altesFach;
    
    if ([validString isEqualToString:@"---"]) {
        return @"–";
    }
    return validString;
}

- (NSString *)validNewSubject
{
    NSString *validString = self.neuesFach;
    
    if ([validString isEqualToString:@"---"]) {
        return @"–";
    }
    return validString;
}

@end
