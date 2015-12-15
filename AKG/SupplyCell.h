//
//  SupplyCell.h
//  AKG
//
//  Created by Fabian Ehlert on 23.01.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SupplyCellDelegate;

@interface SupplyCell : UITableViewCell

@property (weak, nonatomic) id <SupplyCellDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIButton *infoButton;
@property (weak, nonatomic) IBOutlet UILabel *supplyTypeLabel;
@property (weak, nonatomic) IBOutlet UILabel *subjectNewLabel;
@property (weak, nonatomic) IBOutlet UILabel *roomNewLabel;
@property (weak, nonatomic) IBOutlet UILabel *subjectOldLabel;
@property (weak, nonatomic) IBOutlet UILabel *lessonLabel;
@property (weak, nonatomic) IBOutlet UIImageView *markerImageView;

@end

@protocol SupplyCellDelegate <NSObject>

@required
- (void)infoButtonClicked:(SupplyCell *)sCell;

@end