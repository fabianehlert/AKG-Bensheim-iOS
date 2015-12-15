//
//  FESupplyFetcher.h
//  AKG
//
//  Created by Fabian Ehlert on 11.03.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, FESupplyFetcherDataType) {
    FESupplyFetcherDataTypeOffline = 0,
    FESupplyFetcherDataTypeOnline = 1
};


@protocol FESupplyFetcherDelegate;


@interface FESupplyFetcher : NSObject

/**
 This Protocol helps the receiving ViewController to be able to recognize new data.
 */
@property (weak, nonatomic) id <FESupplyFetcherDelegate> delegate;


/**
 The section number for the current day.
 */
@property (assign, nonatomic, readonly) NSInteger todaySection;
/**
 The section number for the next day.
 */
@property (assign, nonatomic, readonly) NSInteger tomorrowSection;


/**
 The array with the filtered Supply objects.
 */
@property (strong, nonatomic, readonly) NSArray *supplyArray;


/**
 Returns a singleton instance of FESupplyFetcher.
 */
+ (instancetype)sharedFetcher;


/**
 Initializes a 'SavedDataFetch'.
 */
- (void)loadSavedData;
/**
 Initializes an 'OnlineDataFetch'.
 */
- (void)fetchNewData;


/**
 Returns general information about the day-sections, such as number of objects in section and it´s title.
 */
- (NSMutableArray *)sectionInformation;

/**
 Returns an array of the filtered Supplies. (Mainly used for BackgroundFetches)
 */
+ (NSArray *)latestSupplyArray;

@end


@protocol FESupplyFetcherDelegate <NSObject>

@required
- (void)supplyFetcherDataChanged:(FESupplyFetcher *)fetcher finishedLoadingDataOfType:(FESupplyFetcherDataType)type success:(BOOL)success;

@end