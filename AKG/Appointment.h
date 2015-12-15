//
//  Appointment.h
//  AKG
//
//  Created by Fabian Ehlert on 08.02.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Appointment : NSObject

@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *details;
@property (strong, nonatomic) NSString *date;

- (instancetype)initWithTitle:(NSString *)title details:(NSString *)det atDate:(NSString *)date;

@end
