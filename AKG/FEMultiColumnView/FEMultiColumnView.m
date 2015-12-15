//
//  FEMultiColumnView.m
//  FEMulticolumnTableView
//
//  Created by Fabian Ehlert on 16.03.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "FEMultiColumnView.h"

@interface FEMultiColumnView () <UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) UIScrollView *tableContainerScrollView;
@property (strong, nonatomic) NSMutableArray *tableColumnArray;

@end

@implementation FEMultiColumnView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.alpha = 0.0;

        self.tableColumnArray = [[NSMutableArray alloc] init];
        self.tableContainerScrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        self.tableContainerScrollView.backgroundColor = [UIColor colorWithRed:0.88 green:0.88 blue:0.9 alpha:1.0];
        
        [self addSubview:self.tableContainerScrollView];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setupTableViews];
        });
    }
    return self;
}

- (void)setupTableViews
{
    if ([self.dataSource respondsToSelector:@selector(numberOfColumnsInMultiColumnView:)] && [self.dataSource respondsToSelector:@selector(widthForColumnInMultiColumnView:)]) {
        NSUInteger columns = [self.dataSource numberOfColumnsInMultiColumnView:self];
        CGFloat columnWidth = [self.dataSource widthForColumnInMultiColumnView:self];
        
        CGFloat columnHeight;
        
        if ([FEVersionChecker version] >= 8.0) {
            columnHeight = self.tableContainerScrollView.bounds.size.height - 64.0;
        } else {
            columnHeight = self.tableContainerScrollView.bounds.size.height;
        }
        
        for (NSUInteger c = 0; c < columns; c++) {
            UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake((c * columnWidth) + (c * 1), 0, columnWidth, columnHeight)];
            tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
            tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
            tableView.separatorInset = UIEdgeInsetsMake(0, 78, 0, 0);
            tableView.delegate = self;
            tableView.dataSource = self;
            tableView.tag = c+1;
            
            [self.tableColumnArray addObject:tableView];
            [self.tableContainerScrollView addSubview:tableView];
        }
        
        if ([FEVersionChecker version] >= 8.0) {
            [self.tableContainerScrollView setContentSize:CGSizeMake(([self.tableColumnArray count] * columnWidth) + ([self.tableColumnArray count] - 1), columnHeight - 64.0)];
        } else {
            [self.tableContainerScrollView setContentSize:CGSizeMake(([self.tableColumnArray count] * columnWidth) + ([self.tableColumnArray count] - 1), columnHeight)];
        }
    }
    
    [UIView animateWithDuration:0.21 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.alpha = 1.0;
    } completion:^(BOOL finished) {
    }];
}

- (void)updateTableViews
{
    [self.tableContainerScrollView removeFromSuperview];
    self.tableContainerScrollView = nil;

    self.tableColumnArray = [[NSMutableArray alloc] init];
    self.tableContainerScrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    self.tableContainerScrollView.backgroundColor = [UIColor colorWithRed:0.88 green:0.88 blue:0.9 alpha:1.0];
    
    [self addSubview:self.tableContainerScrollView];
    
    [self setupTableViews];
}


#pragma mark - Rotation

- (void)updateBounds
{
    self.tableContainerScrollView.frame = self.bounds;
    
    CGFloat columnHeight = self.tableContainerScrollView.frame.size.height;
    CGFloat columnWidth = [self.dataSource widthForColumnInMultiColumnView:self];
    
    if ([FEVersionChecker version] >= 8.0) {
        [self.tableContainerScrollView setContentSize:CGSizeMake(([self.tableColumnArray count] * columnWidth) + ([self.tableColumnArray count] - 1), columnHeight - 64.0)];
    } else {
        [self.tableContainerScrollView setContentSize:CGSizeMake(([self.tableColumnArray count] * columnWidth) + ([self.tableColumnArray count] - 1), columnHeight)];
    }
}


#pragma mark - Reload

- (void)reloadTableViewContents
{
    if ([self.dataSource respondsToSelector:@selector(numberOfColumnsInMultiColumnView:)]) {
        if ([self.tableColumnArray count] == 0) {
            [self setupTableViews];
        } else if ([self.tableColumnArray count] != [self.dataSource numberOfColumnsInMultiColumnView:self]) {
            [self updateTableViews];
        }
    }
    
    [self.tableColumnArray enumerateObjectsUsingBlock:^(UITableView *tv, NSUInteger idx, BOOL *stop) {
        [tv reloadData];
    }];
}


#pragma mark - TableView

- (UITableView *)tableViewInColumn:(NSUInteger)column
{
    UITableView *tv = self.tableColumnArray[column];
    return tv;
}

- (NSUInteger)numberOfRowsInTableViewInColumn:(NSInteger)column
{
    UITableView *tv = self.tableColumnArray[column];
    return [tv numberOfRowsInSection:0];
}

- (FEIndexPath *)indexPathForCell:(UITableViewCell *)cell
{
    __block FEIndexPath *idxPath;
    [self.tableColumnArray enumerateObjectsUsingBlock:^(UITableView *tv, NSUInteger idx, BOOL *stop) {
        NSIndexPath *path = [tv indexPathForCell:cell];
        if (path) {
            idxPath = [FEIndexPath indexPathWithRow:path.row inColumn:idx];
        }
    }];
    return idxPath;
}


#pragma mark - ScrollOffset

- (CGFloat)horizontalScrollOffset
{
    return self.tableContainerScrollView.contentOffset.x;
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    __block NSInteger rowsInColumn = 0;
    [self.tableColumnArray enumerateObjectsUsingBlock:^(UITableView *tv, NSUInteger idx, BOOL *stop) {
        if (tableView == tv && [self.dataSource respondsToSelector:@selector(multiColumnView:numberOfRowsInColumn:)]) {
            rowsInColumn = [self.dataSource multiColumnView:self numberOfRowsInColumn:idx];
        }
    }];
    return rowsInColumn;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    __block UIView *headerView = [[UIView alloc] init];
    [self.tableColumnArray enumerateObjectsUsingBlock:^(UITableView *tv, NSUInteger idx, BOOL *stop) {
        if (tableView == tv && [self.dataSource respondsToSelector:@selector(multiColumnView:viewForHeaderInColumn:)]) {
            headerView = [self.dataSource multiColumnView:self viewForHeaderInColumn:idx];
        }
    }];
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    __block CGFloat rowHeight = 0.0;
    [self.tableColumnArray enumerateObjectsUsingBlock:^(UITableView *tv, NSUInteger idx, BOOL *stop) {
        if (tableView == tv && [self.dataSource respondsToSelector:@selector(multiColumnView:heightForRowAtIndexPath:)]) {
            rowHeight = [self.dataSource multiColumnView:self heightForRowAtIndexPath:[FEIndexPath indexPathWithRow:indexPath.row inColumn:idx]];
        }
    }];
    return rowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    __block CGFloat headerHeight = 0.0;
    [self.tableColumnArray enumerateObjectsUsingBlock:^(UITableView *tv, NSUInteger idx, BOOL *stop) {
        if (tableView == tv && [self.dataSource respondsToSelector:@selector(multiColumnView:heightForHeaderInColumn:)]) {
            headerHeight = [self.dataSource multiColumnView:self heightForHeaderInColumn:idx];
        }
    }];
    return headerHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;

    __block FEIndexPath *idxPath;
    
    [self.tableColumnArray enumerateObjectsUsingBlock:^(UITableView *tv, NSUInteger idx, BOOL *stop) {
        if (tableView == tv) {
            idxPath = [FEIndexPath indexPathWithRow:indexPath.row inColumn:idx];
        }
    }];
    
    if ([self.dataSource respondsToSelector:@selector(multiColumnView:cellForRowAtIndexPath:inTableViewColumn:)]) {
        cell = [self.dataSource multiColumnView:self cellForRowAtIndexPath:idxPath inTableViewColumn:tableView];
    }
    return cell;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableColumnArray enumerateObjectsUsingBlock:^(UITableView *tv, NSUInteger idx, BOOL *stop) {
        if (tableView == tv && [self.delegate respondsToSelector:@selector(multiColumnView:didSelectRowAtIndexPath:)]) {
            [self.delegate multiColumnView:self didSelectRowAtIndexPath:[FEIndexPath indexPathWithRow:indexPath.row inColumn:idx]];
        }
    }];
}

@end
