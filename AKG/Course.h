//
//  Course.h
//  AKG
//
//  Created by Fabian Ehlert on 12.02.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Course : NSObject

@property (strong, nonatomic) NSString *subject;
@property (strong, nonatomic) NSString *courseNumberString;

@property (assign, nonatomic) BOOL isLK;
@property (assign, nonatomic) BOOL isTutor;

- (NSString *)courseString;

+ (Course *)courseOfCourseString:(NSString *)str;

@end
