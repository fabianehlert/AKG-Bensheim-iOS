//
//  SupplyTypeColorTableViewController.h
//  AKG
//
//  Created by Fabian Ehlert on 08.02.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ColorSettingsDelegate <NSObject>

@required
- (void)saveColorAtIndex:(NSUInteger)color forTypeAtIndex:(NSUInteger)type;
- (void)cancel;

@end

@interface SupplyTypeColorTableViewController : UITableViewController

@property (weak, nonatomic) id <ColorSettingsDelegate> delegate;

@property (strong, nonatomic) NSString *type;
@property (assign, nonatomic) NSUInteger colorIndex;
@property (assign, nonatomic) NSUInteger typeIndex;

@end
