//
//  Supply.h
//  AKG
//
//  Created by Fabian Ehlert on 21.10.13.
//  Copyright (c) 2013 Fabian Ehlert. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SupplyItem : NSObject

@property (strong, nonatomic) NSString *art;
@property (strong, nonatomic) NSString *klasse;
@property (strong, nonatomic) NSDate *datum;
@property (strong, nonatomic) NSString *stunde;
@property (strong, nonatomic) NSString *alterRaum;
@property (strong, nonatomic) NSString *neuerRaum;
@property (strong, nonatomic) NSString *altesFach;
@property (strong, nonatomic) NSString *neuesFach;
@property (strong, nonatomic) NSString *info;

@property (strong, nonatomic, readonly) NSString *uuid;

- (void)setupUUID;

- (NSString *)titleForReminder;
- (NSString *)noteForReminder;

- (NSString *)validLesson;
- (NSString *)validAlterRaum;
- (NSString *)validNeuerRaum;
- (NSString *)validOldSubject;
- (NSString *)validNewSubject;

@end
