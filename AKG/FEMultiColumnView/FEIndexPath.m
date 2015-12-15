//
//  FEIndexPath.m
//  FEMulticolumnTableView
//
//  Created by Fabian Ehlert on 13.03.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "FEIndexPath.h"

@implementation FEIndexPath

+ (instancetype)indexPathWithRow:(NSUInteger)row inColumn:(NSUInteger)column
{
    FEIndexPath *indexPath = [[FEIndexPath alloc] init];
    indexPath.row = row;
    indexPath.column = column;
    
    return indexPath;
}

@end
