//
//  FEActionsMenuItemsStorage.m
//
//  Created by Fabian Ehlert on 26.01.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "FEActionsMenuItemsStorage.h"

@interface FEActionsMenuItemsStorage () <FEActionsMenuItemDelegate>

@property (strong, nonatomic, readwrite) NSMutableArray *blocks;
@property (strong, nonatomic, readwrite) NSMutableArray *menuItems;

@end

@implementation FEActionsMenuItemsStorage

- (id)init
{
    self = [super init];
    if (self) {
        
        self.blocks = [[NSMutableArray alloc] init];
        self.menuItems = [[NSMutableArray alloc] init];
        
    }
    return self;
}


#pragma mark - MenuItems

- (void)addMenuItem:(FEActionsMenuItem *)aItm actions:(FEActionsMenuItemBlock)block
{
    aItm.delegate = self;
    
    [self.blocks addObject:block ? [block copy] : [NSNull null]];
    [self.menuItems addObject:aItm];
}

- (void)addMenuItemWithTitle:(NSString *)aTitle andItemSize:(CGSize)aSize actions:(FEActionsMenuItemBlock)block
{
    FEActionsMenuItem *item = [[FEActionsMenuItem alloc] initWithTitle:aTitle itemSize:aSize];
    item.delegate = self;
    
    [self.blocks addObject:block ? [block copy] : [NSNull null]];
    [self.menuItems addObject:item];
}


#pragma mark - FEActionsMenuItemDelegate

- (void)clickedMenuItem:(FEActionsMenuItem *)item
{
    NSUInteger index = [self.menuItems indexOfObject:item];
    
    FEActionsMenuItemBlock block = self.blocks[index];
    if ((id) block != [NSNull null]) {
		block (item);
	}
}

@end
