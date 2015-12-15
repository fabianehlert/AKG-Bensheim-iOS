//
//  Teacher.h
//  AKG
//
//  Created by Fabian Ehlert on 09.02.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Teacher : NSObject

@property (strong, nonatomic) NSString *firstName;
@property (strong, nonatomic) NSString *lastName;
@property (strong, nonatomic) NSString *shortName;
@property (strong, nonatomic) NSString *subjects;
@property (strong, nonatomic) NSString *mail;

- (instancetype)initWithFirstName:(NSString *)fnm lastName:(NSString *)lnm shortName:(NSString *)shrtNm subjects:(NSString *)sbjcts mail:(NSString *)ml;

@end
