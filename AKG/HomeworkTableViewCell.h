//
//  HomeworkTableViewCell.h
//  AKG
//
//  Created by Fabian Ehlert on 08.03.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HomeworkTableViewCellDelegate;

@interface HomeworkTableViewCell : UITableViewCell

@property (weak, nonatomic) id <HomeworkTableViewCellDelegate> delegate;

@property (weak, nonatomic) IBOutlet UILabel *taskLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@property (weak, nonatomic) IBOutlet UIButton *checkCircleButton;

@property (assign, nonatomic) BOOL taskIsDone;

@end


@protocol HomeworkTableViewCellDelegate <NSObject>

@required
- (void)checkCircleTapped:(HomeworkTableViewCell *)cell currentDoneValue:(BOOL)done;

@end