//
//  FEVersionChecker.m
//  AKG
//
//  Created by Fabian Ehlert on 16.08.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "FEVersionChecker.h"

@implementation FEVersionChecker

+ (CGFloat)version {
    NSString *versionNumber = [UIDevice currentDevice].systemVersion;
    CGFloat floatVersionNumber = [versionNumber floatValue];

    return floatVersionNumber;
}

@end
