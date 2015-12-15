//
//  AppointmentsLoader.h
//  AKG
//
//  Created by Fabian Ehlert on 08.02.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppointmentsLoader : NSObject

+ (NSArray *)savedAppointmentsFeed;
+ (NSArray *)latestAppointmentsFeed;

@end
