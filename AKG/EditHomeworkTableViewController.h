//
//  EditHomeworkTableViewController.h
//  AKG
//
//  Created by Fabian Ehlert on 08.03.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Homework.h"

@protocol EditHomeworkTableViewControllerDelegate;

@interface EditHomeworkTableViewController : UITableViewController

@property (weak, nonatomic) id <EditHomeworkTableViewControllerDelegate> delegate;

@property (strong, nonatomic) Homework *homework;

@end

@protocol EditHomeworkTableViewControllerDelegate <NSObject>

@required
- (void)shouldUpdateContent;
- (void)willDeleteHomework:(Homework *)homework;

@end
