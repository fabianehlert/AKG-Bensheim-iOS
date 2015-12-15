//
//  SupplyTableViewController.m
//  AKG
//
//  Created by Fabian Ehlert on 15.05.13.
//  Copyright (c) 2013 Fabian Ehlert. All rights reserved.
//

#import "SupplyTableViewController.h"

#import "SupplyItem.h"
#import "SupplyCell.h"
#import "FESupplyFetcher.h"
#import "SupplyHelper.h"

#import "SupplyDetailViewController.h"

#import "UIImage+ImageEffects.h"
#import "FBShimmeringView.h"

@interface SupplyTableViewController () <SupplyDetailViewControllerDelegate, SupplyCellDelegate, FESupplyFetcherDelegate>

/** Array mit finalen Vertretungsplan-Daten. Wird zur Darstellung verwendet.
 */
@property (strong, nonatomic) NSArray *filteredArray;

/** Array mit Informationen über SectionHeaders und Anzahl der Rows in einer Section
 */
@property (strong, nonatomic) NSMutableArray *sectionArray;

@property (assign, nonatomic) BOOL nullCountVisible;
@property (strong, nonatomic) UILabel *nullCountLabel;

@property (strong, nonatomic) UIRefreshControl *reloadControl;

@property (strong, nonatomic) SupplyDetailViewController *detailController;
@property (strong, nonatomic) SupplyItem *detailSupply;

@property (strong, nonatomic) UIView *whiteCellView;

@property (strong, nonatomic) UIImageView *cellSnapshotImageView;
@property (assign, nonatomic) BOOL detailControllerVisible;
@property (assign, nonatomic) CGRect currentDetailCellRect;

@property (strong, nonatomic) UIImageView *darkBlurImageView;
@property (strong, nonatomic) UIView *darkView;
@property (strong, nonatomic) UITapGestureRecognizer *tap;

@end

@implementation SupplyTableViewController

#pragma mark - ViewController lifecycle
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    dispatch_async(dispatch_queue_create("com.fabianehlert.offlinesupply", NULL), ^{
        [self loadOfflineData];
    });
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.nullCountVisible = NO;
    
    self.title = FELocalized(@"SUPPLY_PLAN_KEY");
    [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 78, 0, 0)];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.reloadControl = [[UIRefreshControl alloc] init];
    [self.reloadControl addTarget:self action:@selector(loadOnlineData) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = self.reloadControl;
    
    [self setupMenu];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    self.filteredArray = nil;
    self.sectionArray = nil;
    self.detailController = nil;
    self.detailSupply = nil;
}

#pragma mark - Menu

- (void)setupMenu
{
    // SideMenuButton
    UIBarButtonItem *sideMenuItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"MenuIcon"]
                                                                     style:UIBarButtonItemStyleBordered
                                                                    target:self
                                                                    action:@selector(showMenu)];
    
    self.navigationItem.leftBarButtonItem = sideMenuItem;
}

- (void)showMenu
{
    [self.sideMenuViewController presentLeftMenuViewController];
}


#pragma mark - Loading

- (void)loadOfflineData
{
    [FESupplyFetcher sharedFetcher].delegate = self;
    [[FESupplyFetcher sharedFetcher] loadSavedData];
}

- (void)loadOnlineData
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    dispatch_async(dispatch_queue_create("com.fabianehlert.onlinesupply", NULL), ^{
        [[FESupplyFetcher sharedFetcher] fetchNewData];
    });
}


#pragma mark - FESupplyFetcherDelegate

- (void)supplyFetcherDataChanged:(FESupplyFetcher *)fetcher finishedLoadingDataOfType:(FESupplyFetcherDataType)type success:(BOOL)success
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    if (success) {
        self.filteredArray = fetcher.supplyArray;
        self.sectionArray = [[FESupplyFetcher sharedFetcher] sectionInformation];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // Update the NullCountLabel
        [self updateNullCountLabel];
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        if ([self.reloadControl isRefreshing]) {
            [self.reloadControl endRefreshing];
        }
        
        // Reload the Table
        [self.tableView reloadData];
        
        if (type == FESupplyFetcherDataTypeOffline) {
            // Start loading online data
            [self loadOnlineData];
        }
    });
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.sectionArray count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.sectionArray[section] valueForKey:@"itemsInSection"] integerValue];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 74.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 26.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    // BackgroundView
    UIView *hView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, [self tableView:tableView heightForHeaderInSection:section])];
    hView.alpha = 1.0f;
    hView.backgroundColor = [UIColor colorWithWhite:0.965 alpha:1.0];
    
    // SupplyItem which carries information about the date
    SupplyItem *supply = self.filteredArray[[self numberOfRowsInFrontOfSection:section]];
    
    // Format the extracted date
    NSDate *date = supply.datum;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEEE"];
    NSString *weekDay = [dateFormatter stringFromDate:date];
    
    [dateFormatter setDateFormat:@"dd.MMMM"];
    NSString *day = [dateFormatter stringFromDate:date];
    
    if ([day characterAtIndex:0] == '0') {
        day = [day stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
    }
    
    if ([day characterAtIndex:day.length - 1] == '.') {
        day = [day stringByReplacingCharactersInRange:NSMakeRange(day.length - 1, 1) withString:@""];
    }
    
    // ShimmeringView
    CGRect shimmerRect = CGRectMake(0, 0, self.view.frame.size.width, hView.frame.size.height);
    FBShimmeringView *shimmeringView = [[FBShimmeringView alloc] initWithFrame:shimmerRect];
    shimmeringView.center = hView.center;
    if (section == [FESupplyFetcher sharedFetcher].todaySection) {
        shimmeringView.frame = CGRectMake(0, 0, 100, hView.frame.size.height);
        shimmeringView.center = hView.center;
    }
    
    shimmeringView.shimmeringPauseDuration = 0.2;
    shimmeringView.shimmeringSpeed = 60.0;
    shimmeringView.shimmeringHighlightWidth = 0.4;
    shimmeringView.shimmeringOpacity = 0.65;
    
    [hView addSubview:shimmeringView];
    
    
    // Create the label which displays the date
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:shimmeringView.bounds];
    titleLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textColor = [UIColor colorWithWhite:0.34 alpha:1.0];
    
    if (section == [FESupplyFetcher sharedFetcher].todaySection) {
        shimmeringView.shimmering = YES;
        titleLabel.textColor = [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:1.0];
        titleLabel.attributedText = [self attributedStringWithFirstString:FELocalized(@"todayTitleString") secondString:@""];
    } else if (section == [FESupplyFetcher sharedFetcher].tomorrowSection) {
        shimmeringView.shimmering = NO;
        titleLabel.textColor = [UIColor colorWithWhite:0.34 alpha:1.0];
        titleLabel.attributedText = [self attributedStringWithFirstString:FELocalized(@"tomorrowTitleString") secondString:@""];
    } else {
        shimmeringView.shimmering = NO;
        titleLabel.textColor = [UIColor colorWithWhite:0.34 alpha:1.0];
        titleLabel.attributedText = [self attributedStringWithFirstString:weekDay secondString:day];
    }
        
    shimmeringView.contentView = titleLabel;
    
    return hView;
}

- (NSAttributedString *)attributedStringWithFirstString:(NSString *)str0 secondString:(NSString *)str1
{
    UIFont *mediumFont = [UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0];
    if ([FEVersionChecker version] >= 9.0) {
        mediumFont = [UIFont systemFontOfSize:17.0 weight:UIFontWeightMedium];
    }
    
    UIFont *lightFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:17.0];
    if ([FEVersionChecker version] >= 9.0) {
        lightFont = [UIFont systemFontOfSize:17.0 weight:UIFontWeightLight];
    }
    

    NSMutableAttributedString *aStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@", str0, str1]];
    [aStr addAttribute:NSFontAttributeName value:mediumFont range:NSMakeRange(0, str0.length)];
    [aStr addAttribute:NSFontAttributeName value:lightFont range:NSMakeRange(str0.length + 1, str1.length)];
    return aStr;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SupplyCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    cell.delegate = self;
    
    SupplyItem *supply = self.filteredArray[indexPath.row + [self numberOfRowsInFrontOfIndex:indexPath]];
    NSString *artText = supply.art;
    NSString *displayTyp = [SupplyHelper displayTypeForType:artText];
    UIColor *markerColor = [SupplyHelper colorForType:artText];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SHOULD_APPLY_COLOR_SUPPLY_PLAN"]) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
        view.backgroundColor = markerColor;
        cell.markerImageView.image = [self imageFromView:view];
    } else if (![[NSUserDefaults standardUserDefaults] boolForKey:@"SHOULD_APPLY_COLOR_SUPPLY_PLAN"]) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
        view.backgroundColor = [UIColor colorWithWhite:0.78 alpha:1.0];
        cell.markerImageView.image = [self imageFromView:view];
    }
    
    if (supply.info && ![supply.info isEqualToString:@"Keine Anmerkungen"]) {
        cell.infoButton.alpha = 1.0;
        cell.infoButton.userInteractionEnabled = YES;
    } else {
        cell.infoButton.userInteractionEnabled = NO;
        cell.infoButton.alpha = 0.0;
    }
    
    cell.lessonLabel.text = [supply validLesson];
    cell.supplyTypeLabel.text = displayTyp;
    cell.subjectOldLabel.text = [supply validOldSubject];
    cell.roomNewLabel.text = [NSString stringWithFormat:@"Raum: %@", [supply validNeuerRaum]];
    cell.subjectNewLabel.text = [NSString stringWithFormat:@"Fach: %@", [supply validNewSubject]];

    return cell;
}


#pragma mark - Helper

- (UIImage *)imageFromView:(UIView *)view
{
    UIImage *image = [[UIImage alloc] init];
    
    UIGraphicsBeginImageContextWithOptions(view.frame.size, NO, 0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (NSInteger)numberOfRowsInFrontOfIndex:(NSIndexPath *)indexPath
{
    NSInteger returnInteger = 0;
    
    for (NSUInteger d = 0; d < indexPath.section; d++)
    {
        NSInteger rowsInSectionD = [self.tableView numberOfRowsInSection:d];
        returnInteger = returnInteger + rowsInSectionD;
    }
    
    return returnInteger;
}

- (NSInteger)numberOfRowsInFrontOfSection:(NSUInteger)section
{
    NSInteger returnInteger = 0;
    
    for (NSUInteger d = 0; d < section; d++) {
        NSInteger rowsInSectionD = [self.tableView numberOfRowsInSection:d];
        returnInteger = returnInteger + rowsInSectionD;
    }
    
    return returnInteger;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    CGRect rect = [tableView rectForRowAtIndexPath:indexPath];
    CGRect convertedRect = [tableView convertRect:rect toView:tableView.superview];
    
    self.detailSupply = self.filteredArray[indexPath.row + [self numberOfRowsInFrontOfIndex:indexPath]];
    
    
    // Snapshot of the selected Cell
    UIGraphicsBeginImageContextWithOptions(cell.bounds.size, 0, 0);
    [cell drawViewHierarchyInRect:CGRectMake(0, 0, cell.bounds.size.width, cell.bounds.size.height) afterScreenUpdates:NO];
    
    UIImage *cellSnapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    
    [self showDetailViewWithTransitionImage:cellSnapshotImage fromRect:convertedRect];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - NullCountLabel

- (void)updateNullCountLabel
{
    if ([self.filteredArray count] > 0) {
        [self hideNullCountLabel];
    } else {
        [self showNullCountLabel];
    }
}

- (void)showNullCountLabel
{
    if (!self.nullCountVisible) {
        self.nullCountVisible = YES;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            self.nullCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.tableView.frame.size.height / 2, self.tableView.frame.size.width, 45)];
            self.nullCountLabel.center = CGPointMake(self.tableView.frame.size.width / 2, ([UIScreen mainScreen].bounds.size.height - 64) / 2);
        } else {
            self.nullCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.tableView.frame.size.height / 2, self.tableView.frame.size.width, 45)];
            self.nullCountLabel.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
            self.nullCountLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
        }
        
        self.nullCountLabel.backgroundColor = [UIColor clearColor];
        self.nullCountLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
        self.nullCountLabel.highlightedTextColor = self.nullCountLabel.textColor;
        
        if ([FEVersionChecker version] >= 9.0) {
            self.nullCountLabel.font = [UIFont systemFontOfSize:28.0 weight:UIFontWeightLight];
        } else {
            self.nullCountLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:28.0];
        }
        
        self.nullCountLabel.textAlignment = NSTextAlignmentCenter;
        self.nullCountLabel.text = FELocalized(@"SUPPLY_NOT_AVLBL_KEY");
        self.nullCountLabel.alpha = 0.0;
        
        [self.view addSubview:self.nullCountLabel];
        
        [UIView animateWithDuration:0.24
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
                             self.nullCountLabel.alpha = 1.0;
                         } completion:nil];
    }
}

- (void)hideNullCountLabel
{
    if (self.nullCountVisible) {
        [UIView animateWithDuration:0.16
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             self.nullCountLabel.alpha = 0.0;
                             self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
                         } completion:^(BOOL finished) {
                             [self.nullCountLabel removeFromSuperview];
                             self.nullCountVisible = NO;
                         }];
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)pan
{
    
}

#pragma mark - DetailViewController

- (void)showDetailViewWithTransitionImage:(UIImage *)img fromRect:(CGRect)rect
{
    if (!self.detailController) {
        if (!self.detailControllerVisible && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size
            .height == 480.0) {
            // We don't blur the BG for 3.5in Devices --> CPU & GPU aren't strong enough
            self.detailControllerVisible = YES;
            
            self.currentDetailCellRect = rect;
            
            // WhiteCellView
            self.whiteCellView = [[UIView alloc] initWithFrame:rect];
            self.whiteCellView.backgroundColor = [UIColor whiteColor];
            self.whiteCellView.alpha = 1.0;
            [self.sideMenuViewController.contentViewController.view addSubview:self.whiteCellView];
            
            self.darkView = [[UIView alloc] initWithFrame:self.navigationController.view.frame];
            self.darkView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
            self.darkView.alpha = 0.0;
            self.darkView.userInteractionEnabled = YES;
            
            self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissButtonClicked:)];
            self.tap.numberOfTapsRequired = 1;
            self.tap.numberOfTouchesRequired = 1;
            
            [self.darkView addGestureRecognizer:self.tap];
            
            [self.sideMenuViewController.contentViewController.view addSubview:self.darkView];
            
            
            // Cell Snapshot
            self.cellSnapshotImageView = [[UIImageView alloc] initWithImage:img];
            [self.cellSnapshotImageView setFrame:rect];
            
            [self.sideMenuViewController.contentViewController.view addSubview:self.cellSnapshotImageView];
            
            
            // DetailController
            self.detailController = [self.storyboard instantiateViewControllerWithIdentifier:@"SUPPLY_DETAIL"];
            self.detailController.delegate = self;
            self.detailController.supply = self.detailSupply;
            
            self.detailController.view.frame = rect;
            self.detailController.view.alpha = 0.0;
            
            // Round the corners
            self.detailController.view.layer.cornerRadius = 10.0;
            
            // Interpolation
            UIInterpolatingMotionEffect *interpolationHorizontal = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
            interpolationHorizontal.minimumRelativeValue = @(-12);
            interpolationHorizontal.maximumRelativeValue = @(12);
            
            UIInterpolatingMotionEffect *interpolationVertical = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
            interpolationVertical.minimumRelativeValue = @(-12);
            interpolationVertical.maximumRelativeValue = @(12);
            
            
            [self.sideMenuViewController.contentViewController addChildViewController:self.detailController];
            [self.sideMenuViewController.contentViewController.view addSubview:self.detailController.view];
            [self.detailController didMoveToParentViewController:self];

            
            static CGFloat detailWidth = 300.0;
            static CGFloat detailHeight = 210.0;
            CGFloat detailX = (self.navigationController.view.frame.size.width - detailWidth) / 2.0;
            CGFloat detailY = (self.navigationController.view.frame.size.height / 2.0) - (detailHeight / 2.0);
            
            [UIView animateWithDuration:0.35
                                  delay:0.0
                 usingSpringWithDamping:0.75
                  initialSpringVelocity:0.5
                                options:UIViewAnimationOptionAllowUserInteraction
                             animations:^{
                                 [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
                                 self.darkView.alpha = 1.0;
                                 self.detailController.view.alpha = 1.0;
                                 self.cellSnapshotImageView.alpha = 0.0;
                                 
                                 self.detailController.view.frame = CGRectMake(detailX, detailY, detailWidth, detailHeight);
                                 self.cellSnapshotImageView.frame = CGRectMake(detailX, detailY, detailWidth, detailHeight);
                                 
                                 [self.detailController.view addMotionEffect:interpolationHorizontal];
                                 [self.detailController.view addMotionEffect:interpolationVertical];
                             } completion:^(BOOL finished) {
                                 
                             }];
        } else {
            self.detailControllerVisible = YES;
            
            self.currentDetailCellRect = rect;
            
            
            // WhiteCellView
            self.whiteCellView = [[UIView alloc] initWithFrame:rect];
            self.whiteCellView.backgroundColor = [UIColor whiteColor];
            self.whiteCellView.alpha = 1.0;
            [self.sideMenuViewController.contentViewController.view addSubview:self.whiteCellView];
            
            UIGraphicsBeginImageContextWithOptions(self.view.frame.size, 0, 0);
            [self.sideMenuViewController.contentViewController.view drawViewHierarchyInRect:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) afterScreenUpdates:NO];

            UIImage *backgroundImage = UIGraphicsGetImageFromCurrentImageContext();
            
            UIGraphicsEndImageContext();
            
            
            // BlurImage & ImageView
            UIImage *blurredBG = [backgroundImage applyBlurWithRadius:4.0 tintColor:[UIColor colorWithWhite:0.0 alpha:0.84] saturationDeltaFactor:2.3 maskImage:nil];

            self.darkBlurImageView = [[UIImageView alloc] initWithFrame:self.view.frame];
            self.darkBlurImageView.contentMode = UIViewContentModeScaleAspectFill;
            self.darkBlurImageView.image = blurredBG;
            self.darkBlurImageView.alpha = 0.0;
            self.darkBlurImageView.userInteractionEnabled = YES;
            
            self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissButtonClicked:)];
            self.tap.numberOfTapsRequired = 1;
            self.tap.numberOfTouchesRequired = 1;
            
            [self.darkBlurImageView addGestureRecognizer:self.tap];
            
            [self.sideMenuViewController.contentViewController.view addSubview:self.darkBlurImageView];

            
            // Cell Snapshot
            self.cellSnapshotImageView = [[UIImageView alloc] initWithImage:img];
            [self.cellSnapshotImageView setFrame:rect];
            
            [self.sideMenuViewController.contentViewController.view addSubview:self.cellSnapshotImageView];

            
            // DetailController
            self.detailController = [self.storyboard instantiateViewControllerWithIdentifier:@"SUPPLY_DETAIL"];
            self.detailController.delegate = self;
            self.detailController.supply = self.detailSupply;
            
            self.detailController.view.frame = rect;
            self.detailController.view.alpha = 0.0;
            
            // Round the corners
            self.detailController.view.layer.cornerRadius = 10.0;
            
            // Interpolation
            UIInterpolatingMotionEffect *interpolationHorizontal = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
            interpolationHorizontal.minimumRelativeValue = @(-10);
            interpolationHorizontal.maximumRelativeValue = @(10);
            
            UIInterpolatingMotionEffect *interpolationVertical = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
            interpolationVertical.minimumRelativeValue = @(-10);
            interpolationVertical.maximumRelativeValue = @(10);
            

            [self.sideMenuViewController.contentViewController addChildViewController:self.detailController];
            [self.sideMenuViewController.contentViewController.view addSubview:self.detailController.view];
            [self.detailController didMoveToParentViewController:self];
            
            
            static CGFloat detailWidth = 300.0;
            static CGFloat detailHeight = 210.0;
            
            CGFloat detailX = (self.view.frame.size.width - detailWidth) / 2.0;
            CGFloat detailY = (self.view.frame.size.height / 2.0) - (detailHeight / 2.0);
            
            [UIView animateWithDuration:0.35
                                  delay:0.0
                 usingSpringWithDamping:0.75
                  initialSpringVelocity:0.5
                                options:UIViewAnimationOptionAllowUserInteraction
                             animations:^{
                                 [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
                                 self.darkBlurImageView.alpha = 1.0;
                                 self.detailController.view.alpha = 1.0;
                                 self.cellSnapshotImageView.alpha = 0.0;
                                 
                                 self.detailController.view.frame = CGRectMake(detailX, detailY, detailWidth, detailHeight);
                                 self.cellSnapshotImageView.frame = CGRectMake(detailX, detailY, detailWidth, detailHeight);
                                 
                                 [self.detailController.view addMotionEffect:interpolationHorizontal];
                                 [self.detailController.view addMotionEffect:interpolationVertical];
                             } completion:^(BOOL finished) {
                                 
                             }];
        }
    }
}


#pragma mark - SupplyDetailViewControllerDelegate

- (void)dismissBackground
{
    // Remove the WhiteCellView
    [self.whiteCellView removeFromSuperview];
    self.whiteCellView = nil;
    
    if ([UIScreen mainScreen].bounds.size.height == 480.0) {
        [UIView animateWithDuration:0.1 animations:^{
            self.detailController.view.alpha = 0.0;
        }];

        [UIView animateWithDuration:0.38
                              delay:0.0
             usingSpringWithDamping:0.83
              initialSpringVelocity:0.2
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
                             self.darkView.alpha = 0.0;
                         } completion:^(BOOL finished) {
                             
                             // 1. Remove any MotionEffect from the DetailViewController
                             for (UIInterpolatingMotionEffect *effect in self.detailController.view.motionEffects) {
                                 [self.detailController.view removeMotionEffect:effect];
                             }
                             
                             // 2. Remove DetailViewController
                             [self.detailController willMoveToParentViewController:nil];
                             [self.detailController.view removeFromSuperview];
                             [self.detailController removeFromParentViewController];
                             
                             self.detailController.delegate = nil;
                             self.detailController = nil;
                             
                             // 3. Remove the BlurImageView and it´s TapGestureRecognizer
                             [self.darkView removeGestureRecognizer:self.tap];
                             self.tap = nil;
                             
                             [self.darkView removeFromSuperview];
                             self.darkView = nil;
                             
                             // 4. Remove the CellSnapshot
                             [self.cellSnapshotImageView removeFromSuperview];
                             self.cellSnapshotImageView = nil;
                             
                             // 6.
                             self.detailControllerVisible = NO;
                         }];
    } else {
        [UIView animateWithDuration:0.1 animations:^{
            self.detailController.view.alpha = 0.0;
        }];

        [UIView animateWithDuration:0.38
                              delay:0.0
             usingSpringWithDamping:0.83
              initialSpringVelocity:0.2
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
                             self.darkBlurImageView.alpha = 0.0;
                         } completion:^(BOOL finished) {
                             
                             // 1. Remove any MotionEffect from the DetailViewController
                             for (UIInterpolatingMotionEffect *effect in self.detailController.view.motionEffects) {
                                 [self.detailController.view removeMotionEffect:effect];
                             }
                             
                             // 2. Remove DetailViewController
                             [self.detailController willMoveToParentViewController:nil];
                             [self.detailController.view removeFromSuperview];
                             [self.detailController removeFromParentViewController];
                             
                             self.detailController.delegate = nil;
                             self.detailController = nil;
                             
                             // 3. Remove the BlurImageView and it´s TapGestureRecognizer
                             [self.darkBlurImageView removeGestureRecognizer:self.tap];
                             self.tap = nil;
                             
                             [self.darkBlurImageView removeFromSuperview];
                             self.darkBlurImageView = nil;
                             
                             // 4. Remove the CellSnapshot
                             [self.cellSnapshotImageView removeFromSuperview];
                             self.cellSnapshotImageView = nil;
                             
                             // 6.
                             self.detailControllerVisible = NO;
                         }];
    }
}

- (void)dismissButtonClicked:(SupplyDetailViewController *)sDetail
{
    if ([UIScreen mainScreen].bounds.size.height == 480.0) {
        [UIView animateWithDuration:0.1 animations:^{
            self.detailController.view.alpha = 0.0;
        }];

        [UIView animateWithDuration:0.38
                              delay:0.0
             usingSpringWithDamping:0.83
              initialSpringVelocity:0.2
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
                             self.darkView.alpha = 0.0;
                             self.detailController.view.frame = self.currentDetailCellRect;
                             self.cellSnapshotImageView.frame = self.currentDetailCellRect;
                             self.cellSnapshotImageView.alpha = 1.0;
                         } completion:^(BOOL finished) {
                             
                             // 1. Remove any MotionEffect from the DetailViewController
                             for (UIInterpolatingMotionEffect *effect in self.detailController.view.motionEffects) {
                                 [self.detailController.view removeMotionEffect:effect];
                             }
                             
                             // 2. Remove DetailViewController
                             [self.detailController willMoveToParentViewController:nil];
                             [self.detailController.view removeFromSuperview];
                             [self.detailController removeFromParentViewController];
                             
                             self.detailController.delegate = nil;
                             self.detailController = nil;
                             
                             // 3. Remove the BlurImageView and it´s TapGestureRecognizer
                             [self.darkView removeGestureRecognizer:self.tap];
                             self.tap = nil;
                             
                             [self.darkView removeFromSuperview];
                             self.darkView = nil;
                             
                             // 4. Remove the CellSnapshot
                             [self.cellSnapshotImageView removeFromSuperview];
                             self.cellSnapshotImageView = nil;
                             
                             // 5. Remove the WhiteCellView
                             [self.whiteCellView removeFromSuperview];
                             self.whiteCellView = nil;
                             
                             // 6.
                             self.detailControllerVisible = NO;
                         }];
    } else {
        [UIView animateWithDuration:0.1 animations:^{
            self.detailController.view.alpha = 0.0;
        }];
        
        [UIView animateWithDuration:0.38
                              delay:0.0
             usingSpringWithDamping:0.83
              initialSpringVelocity:0.2
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
                             self.darkBlurImageView.alpha = 0.0;
                             self.detailController.view.frame = self.currentDetailCellRect;
                             self.cellSnapshotImageView.frame = self.currentDetailCellRect;
                             self.cellSnapshotImageView.alpha = 1.0;
                         } completion:^(BOOL finished) {
                             
                             // 1. Remove any MotionEffect from the DetailViewController
                             for (UIInterpolatingMotionEffect *effect in self.detailController.view.motionEffects) {
                                 [self.detailController.view removeMotionEffect:effect];
                             }
                             
                             // 2. Remove DetailViewController
                             [self.detailController willMoveToParentViewController:nil];
                             [self.detailController.view removeFromSuperview];
                             [self.detailController removeFromParentViewController];
                             
                             self.detailController.delegate = nil;
                             self.detailController = nil;
                             
                             // 3. Remove the BlurImageView and it´s TapGestureRecognizer
                             [self.darkBlurImageView removeGestureRecognizer:self.tap];
                             self.tap = nil;
                             
                             [self.darkBlurImageView removeFromSuperview];
                             self.darkBlurImageView = nil;
                             
                             // 4. Remove the CellSnapshot
                             [self.cellSnapshotImageView removeFromSuperview];
                             self.cellSnapshotImageView = nil;
                             
                             // 5. Remove the WhiteCellView
                             [self.whiteCellView removeFromSuperview];
                             self.whiteCellView = nil;
                             
                             // 6.
                             self.detailControllerVisible = NO;
                         }];
    }
}


#pragma mark - SupplyCellDelegate

- (void)infoButtonClicked:(SupplyCell *)sCell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:sCell];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    CGRect rect = [self.tableView rectForRowAtIndexPath:indexPath];
    CGRect convertedRect = [self.tableView convertRect:rect toView:self.tableView.superview];
    
    self.detailSupply = self.filteredArray[indexPath.row + [self numberOfRowsInFrontOfIndex:indexPath]];
    
    // Snapshot of the selected Cell
    UIGraphicsBeginImageContextWithOptions(cell.bounds.size, 0, 0);
    [cell drawViewHierarchyInRect:CGRectMake(0, 0, cell.bounds.size.width, cell.bounds.size.height) afterScreenUpdates:NO];
    
    UIImage *cellSnapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    
    [self showDetailViewWithTransitionImage:cellSnapshotImage fromRect:convertedRect];
}


#pragma mark - Orientation

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationPortrait | UIInterfaceOrientationPortraitUpsideDown | UIInterfaceOrientationLandscapeLeft | UIInterfaceOrientationLandscapeRight;
    } else {
        return UIInterfaceOrientationPortrait;
    }
    return UIInterfaceOrientationPortrait;
}

- (BOOL)shouldAutorotate
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    } else {
        return NO;
    }
    return 0;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationMaskAll;
    } else {
        return UIInterfaceOrientationMaskPortrait;
    }
    return 0;
}

@end