//
//  CoursesAddEditTableViewController.h
//  AKG
//
//  Created by Fabian Ehlert on 12.02.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Course.h"

@interface CoursesAddEditTableViewController : UITableViewController

@property (strong, nonatomic) Course *courseToEdit;
@property (assign, nonatomic) NSInteger editIdx;

@end
