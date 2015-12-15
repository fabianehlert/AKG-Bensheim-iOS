//
//  TeacherLoader.h
//  AKG
//
//  Created by Fabian Ehlert on 09.02.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TeacherLoader : NSObject

+ (NSArray *)savedTeachers;
+ (NSArray *)latestTeachers;

@end
