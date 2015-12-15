//
//  FEActionsMenuItem.h
//
//  Created by Fabian Ehlert on 25.01.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FEActionsMenuItemDelegate;

@interface FEActionsMenuItem : UIView

@property (weak) id <FEActionsMenuItemDelegate> delegate;

@property (strong, nonatomic) UILabel *titleLabel;

@property (assign, nonatomic, readonly) CGSize size;

@property (strong, nonatomic, readonly) NSString *title;

- (instancetype)initWithTitle:(NSString *)aTitle itemSize:(CGSize)aSize;

@end


@protocol FEActionsMenuItemDelegate <NSObject>

@required
- (void)clickedMenuItem:(FEActionsMenuItem *)item;

@end