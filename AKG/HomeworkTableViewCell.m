//
//  HomeworkTableViewCell.m
//  AKG
//
//  Created by Fabian Ehlert on 08.03.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "HomeworkTableViewCell.h"

@interface HomeworkTableViewCell ()

@property (weak, nonatomic) IBOutlet UIView *selectionHelperView;
@property (strong, nonatomic) UITapGestureRecognizer *tap;

@end

@implementation HomeworkTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    if (self.tap == nil) {
        self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(circleTapped:)];
        self.tap.numberOfTapsRequired = 1;
        self.tap.numberOfTouchesRequired = 1;
        
        [self.selectionHelperView addGestureRecognizer:self.tap];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.taskIsDone) {
        UIImage *img = [[UIImage imageNamed:@"CircleFull"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self.checkCircleButton setImage:img forState:UIControlStateNormal];
    } else {
        UIImage *img = [[UIImage imageNamed:@"CircleEmpty"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self.checkCircleButton setImage:img forState:UIControlStateNormal];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}


#pragma mark - IBActions

- (IBAction)circleTapped:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(checkCircleTapped:currentDoneValue:)]) {
        [self.delegate checkCircleTapped:self currentDoneValue:self.taskIsDone];
    }
}

@end
