//
//  FEActionsMenuItemsStorage.h
//
//  Created by Fabian Ehlert on 26.01.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FEActionsMenuItem.h"

@class FEActionsMenuItem;
typedef void(^FEActionsMenuItemBlock)(FEActionsMenuItem *menuItem);

/*
 This Class is of type NSObject.
 This means that it acts as a data store for FEActionsMenuItems.
 */
@interface FEActionsMenuItemsStorage : NSObject

@property (strong, nonatomic, readonly) NSMutableArray *blocks;
@property (strong, nonatomic, readonly) NSMutableArray *menuItems;

// MenuItems
/**
 Adds a created FEActionsMenuItem to the MenuItems of the FEActionsMenu. The code in the block will be executed when the user taps on the item.
 */
- (void)addMenuItem:(FEActionsMenuItem *)aItm actions:(FEActionsMenuItemBlock)block;

/**
 Creates a FEActionsMenuItem and adds it to the MenuItems of the FEActionsMenu. The code in the block will be executed when the user taps on the item.
 */
- (void)addMenuItemWithTitle:(NSString *)aTitle andItemSize:(CGSize)aSize actions:(FEActionsMenuItemBlock)block;

@end
