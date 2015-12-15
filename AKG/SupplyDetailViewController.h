//
//  SupplyDetailViewController.h
//  AKG
//
//  Created by Fabian Ehlert on 21.02.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SupplyItem.h"

@protocol SupplyDetailViewControllerDelegate;

@interface SupplyDetailViewController : UIViewController

@property (strong, nonatomic) SupplyItem *supply;
@property (weak, nonatomic) id <SupplyDetailViewControllerDelegate> delegate;

@end

@protocol SupplyDetailViewControllerDelegate <NSObject>

@required
- (void)dismissButtonClicked:(SupplyDetailViewController *)sDetail;
- (void)dismissBackground;

@optional
- (void)orientationChanged;

@end
