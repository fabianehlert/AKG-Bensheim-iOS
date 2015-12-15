//
//  FEIndexPath.h
//  FEMulticolumnTableView
//
//  Created by Fabian Ehlert on 13.03.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FEIndexPath : NSObject

@property (assign, nonatomic) NSUInteger row;
@property (assign, nonatomic) NSUInteger column;

+ (instancetype)indexPathWithRow:(NSUInteger)row inColumn:(NSUInteger)column;

@end
