//
//  Appointment.m
//  AKG
//
//  Created by Fabian Ehlert on 08.02.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "Appointment.h"

@implementation Appointment

- (instancetype)initWithTitle:(NSString *)title details:(NSString *)det atDate:(NSString *)date
{
    self = [super init];
    if (self) {
        self.title = title;
        self.details = det;
        self.date = date;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.title forKey:@"title"];
    [encoder encodeObject:self.details forKey:@"details"];
    [encoder encodeObject:self.date forKey:@"date"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super init])) {
        self.title = [decoder decodeObjectForKey:@"title"];
        self.details = [decoder decodeObjectForKey:@"details"];
        self.date = [decoder decodeObjectForKey:@"date"];
    }
    return self;
}

@end
