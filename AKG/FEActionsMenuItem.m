//
//  FEActionsMenuItem.m
//
//  Created by Fabian Ehlert on 25.01.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "FEActionsMenuItem.h"

@interface FEActionsMenuItem ()

@property (strong, nonatomic) UITapGestureRecognizer *tapGestureRecognizer;

@property (assign, nonatomic, readwrite) CGSize size;
@property (strong, nonatomic, readwrite) NSString *title;

@end

@implementation FEActionsMenuItem

- (instancetype)initWithTitle:(NSString *)aTitle itemSize:(CGSize)aSize
{
    self = [super initWithFrame:CGRectMake(0, 0, aSize.width, aSize.height)];
    if (self) {
        
        self.title = aTitle;
        self.size = aSize;
        
        [self addLabel];
        
        self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRecognized:)];
        self.tapGestureRecognizer.numberOfTapsRequired = 1;
        self.tapGestureRecognizer.numberOfTouchesRequired = 1;
        
        [self addGestureRecognizer:self.tapGestureRecognizer];
        
    }
    return self;
}

- (void)addLabel
{
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.size.width, self.size.height)];
    self.titleLabel.text = self.title;
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.textColor = [UIColor colorWithWhite:0.75 alpha:1.0];
    
    if ([FEVersionChecker version] >= 9.0) {
        self.titleLabel.font = [UIFont systemFontOfSize:22.0 weight:UIFontWeightLight];
    } else {
        self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:22.0];
    }
    
    [self addSubview:self.titleLabel];
}


#pragma mark - Tap Recognizer

- (void)tapRecognized:(UITapGestureRecognizer *)tap
{
    if ([self.delegate respondsToSelector:@selector(clickedMenuItem:)]) {
        [self.delegate clickedMenuItem:self];
    }
}

@end
