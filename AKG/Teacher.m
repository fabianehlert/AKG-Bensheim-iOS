//
//  Teacher.m
//  AKG
//
//  Created by Fabian Ehlert on 09.02.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "Teacher.h"

@implementation Teacher

- (instancetype)initWithFirstName:(NSString *)fnm lastName:(NSString *)lnm shortName:(NSString *)shrtNm subjects:(NSString *)sbjcts mail:(NSString *)ml
{
    self = [super init];
    if (self) {
        self.firstName = fnm;
        self.lastName = lnm;
        self.shortName = shrtNm;
        self.subjects = sbjcts;
        self.mail = ml;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.firstName forKey:@"firstName"];
    [encoder encodeObject:self.lastName forKey:@"lastName"];
    [encoder encodeObject:self.shortName forKey:@"shortName"];
    [encoder encodeObject:self.subjects forKey:@"subjects"];
    [encoder encodeObject:self.mail forKey:@"mail"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super init])) {
        self.firstName = [decoder decodeObjectForKey:@"firstName"];
        self.lastName = [decoder decodeObjectForKey:@"lastName"];
        self.shortName = [decoder decodeObjectForKey:@"shortName"];
        self.subjects = [decoder decodeObjectForKey:@"subjects"];
        self.mail = [decoder decodeObjectForKey:@"mail"];
    }
    return self;
}

@end
