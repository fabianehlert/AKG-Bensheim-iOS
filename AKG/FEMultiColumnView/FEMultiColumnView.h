//
//  FEMultiColumnView.h
//  FEMulticolumnTableView
//
//  Created by Fabian Ehlert on 16.03.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FEMultiColumnViewDataSource;
@protocol FEMultiColumnViewDelegate;


@interface FEMultiColumnView : UIView

@property (weak, nonatomic) id <FEMultiColumnViewDataSource> dataSource;
@property (weak, nonatomic) id <FEMultiColumnViewDelegate> delegate;

- (void)updateBounds;
- (void)reloadTableViewContents;

- (UITableView *)tableViewInColumn:(NSUInteger)column;
- (NSUInteger)numberOfRowsInTableViewInColumn:(NSInteger)column;

- (CGFloat)horizontalScrollOffset;
- (FEIndexPath *)indexPathForCell:(UITableViewCell *)cell;

@end


@protocol FEMultiColumnViewDataSource <NSObject>

@required
- (NSUInteger)numberOfColumnsInMultiColumnView:(FEMultiColumnView *)view;
- (NSUInteger)multiColumnView:(FEMultiColumnView *)view numberOfRowsInColumn:(NSUInteger)column;

- (UITableViewCell *)multiColumnView:(FEMultiColumnView *)view cellForRowAtIndexPath:(FEIndexPath *)indexPath inTableViewColumn:(UITableView *)tv;

@optional
- (CGFloat)widthForColumnInMultiColumnView:(FEMultiColumnView *)view;
- (CGFloat)multiColumnView:(FEMultiColumnView *)view heightForRowAtIndexPath:(FEIndexPath *)indexPath;
- (CGFloat)multiColumnView:(FEMultiColumnView *)view heightForHeaderInColumn:(NSUInteger)column;

- (UIView *)multiColumnView:(FEMultiColumnView *)view viewForHeaderInColumn:(NSUInteger)column;

@end


@protocol FEMultiColumnViewDelegate <NSObject>

@optional
- (void)multiColumnView:(FEMultiColumnView *)view didSelectRowAtIndexPath:(FEIndexPath *)indexPath;

@end