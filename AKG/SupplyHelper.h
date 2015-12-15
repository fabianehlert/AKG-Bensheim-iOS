//
//  SupplyHelper.h
//  AKG
//
//  Created by Fabian Ehlert on 09.03.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SupplyHelper : NSObject

+ (NSString *)displayTypeForType:(NSString *)type;
+ (UIColor *)colorForType:(NSString *)type;

@end
