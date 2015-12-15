//
//  ReminderTableViewController.h
//  AKG
//
//  Created by Fabian Ehlert on 08.09.13.
//  Copyright (c) 2013 Fabian Ehlert. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SupplyItem.h"

@protocol ReminderDelegate;

@interface ReminderTableViewController : UITableViewController

@property (strong, nonatomic) SupplyItem *supply;

@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSString *titleString;
@property (nonatomic, strong) NSString *notesString;

@property (nonatomic, weak) id <ReminderDelegate> delegate;

@end


@protocol ReminderDelegate <NSObject>

@required
- (void)reminderDidCreate;
- (void)reminderDidCancel;
- (void)reminderDidFail;

@end