//
//  ColorCell.h
//  AKG
//
//  Created by Fabian Ehlert on 08.02.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ColorCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *colorTitleLabel;
@property (weak, nonatomic) IBOutlet UIView *colorView;

@end
