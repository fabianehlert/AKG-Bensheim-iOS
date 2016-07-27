//
//  SupplyPadViewController.m
//  AKG
//
//  Created by Fabian Ehlert on 19.03.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "SupplyPadViewController.h"
#import "FEMultiColumnView.h"
#import "FEIndexPath.h"

#import "SupplyItem.h"
#import "SupplyCell.h"
#import "FESupplyFetcher.h"
#import "SupplyHelper.h"

#import "SupplyDetailViewController.h"

#import "UIImage+ImageEffects.h"
#import "FBShimmeringView.h"

@interface SupplyPadViewController () <FEMultiColumnViewDataSource, FEMultiColumnViewDelegate, SupplyCellDelegate, SupplyDetailViewControllerDelegate, FESupplyFetcherDelegate>

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

@property (strong, nonatomic) UIView *darkView;
@property (strong, nonatomic) UITapGestureRecognizer *tap;

@property (strong, nonatomic) FEMultiColumnView *multiColumnView;

@end

@implementation SupplyPadViewController

- (void)dealloc
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [FEVersionChecker version];
    
    dispatch_async(dispatch_queue_create("com.fabianehlert.offlinesupply", NULL), ^{
        [self loadOfflineData];
    });
    
    CGRect rect;
    
    if ([FEVersionChecker version] >= 8.0) {
        rect = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    } else {
        rect = CGRectMake(0, 64.0, self.view.frame.size.width, self.view.frame.size.height - 64.0);
    }
    
    self.multiColumnView = [[FEMultiColumnView alloc] initWithFrame:rect];
    self.multiColumnView.dataSource = self;
    self.multiColumnView.delegate = self;
    
    [self.view addSubview:self.multiColumnView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.nullCountVisible = NO;
    
    self.title = FELocalized(@"SUPPLY_PLAN_KEY");
    
    UIBarButtonItem *reloadItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ReloadButton"]
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(loadOnlineData)];
    self.navigationItem.rightBarButtonItem = reloadItem;
    
    [self setupMenu];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    CGRect rect;
    
    if ([FEVersionChecker version] >= 8.0) {
        rect = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    } else {
        rect = CGRectMake(0, 64.0, self.view.frame.size.width, self.view.frame.size.height - 64.0);
    }
    
    self.multiColumnView.frame = rect;
    
    [self.multiColumnView updateBounds];
}


#pragma mark - Menu

- (void)setupMenu
{
    // SideMenuButton
    UIBarButtonItem *sideMenuItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"MenuIcon"]
                                                                     style:UIBarButtonItemStylePlain
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
        
        // Reload the Table
        [self.multiColumnView reloadTableViewContents];
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        if (type == FESupplyFetcherDataTypeOffline) {
            // Start loading online data
            [self loadOnlineData];
        }
    });
}

#pragma mark - FEMultiColumnViewDataSource

- (NSUInteger)multiColumnView:(FEMultiColumnView *)controller numberOfRowsInColumn:(NSUInteger)column
{
    return [[self.sectionArray[column] valueForKey:@"itemsInSection"] integerValue];
}

- (NSUInteger)numberOfColumnsInMultiColumnView:(FEMultiColumnView *)controller
{
    return [self.sectionArray count];
}

- (CGFloat)multiColumnView:(FEMultiColumnView *)view heightForRowAtIndexPath:(FEIndexPath *)indexPath
{
    return 74.0;
}

- (CGFloat)widthForColumnInMultiColumnView:(FEMultiColumnView *)view
{
    return 384.0;
}

- (CGFloat)multiColumnView:(FEMultiColumnView *)view heightForHeaderInColumn:(NSUInteger)column
{
    return 26.0;
}

- (UIView *)multiColumnView:(FEMultiColumnView *)view viewForHeaderInColumn:(NSUInteger)column
{
    // BackgroundView
    UIView *hView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [view.dataSource widthForColumnInMultiColumnView:view], [view.dataSource multiColumnView:view heightForHeaderInColumn:column])];
    hView.alpha = 1.0f;
    hView.backgroundColor = [UIColor colorWithWhite:0.965 alpha:1.0];
    
    // SupplyItem which carries information about the date
    SupplyItem *supply = self.filteredArray[[self numberOfRowsInFrontOfSection:column]];
    
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
    if (column == [FESupplyFetcher sharedFetcher].todaySection) {
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
    
    if (column == [FESupplyFetcher sharedFetcher].todaySection) {
        shimmeringView.shimmering = YES;
        titleLabel.textColor = [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:1.0];
        titleLabel.attributedText = [self attributedStringWithFirstString:FELocalized(@"todayTitleString") secondString:@""];
    } else if (column == [FESupplyFetcher sharedFetcher].tomorrowSection) {
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

- (UITableViewCell *)multiColumnView:(FEMultiColumnView *)view cellForRowAtIndexPath:(FEIndexPath *)indexPath inTableViewColumn:(UITableView *)tv
{
    SupplyCell *cell = [tv dequeueReusableCellWithIdentifier:@"Cell"];
    cell.delegate = self;
    if (!cell) {
        [tv registerNib:[UINib nibWithNibName:@"SupplyCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"Cell"];
        cell = [tv dequeueReusableCellWithIdentifier:@"Cell"];
    }
    
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

- (NSInteger)numberOfRowsInFrontOfIndex:(FEIndexPath *)indexPath
{
    NSInteger returnInteger = 0;
    
    for (NSUInteger d = 0; d < indexPath.column; d++) {
        NSInteger rowsInSectionD = [[self.sectionArray[d] valueForKey:@"itemsInSection"] integerValue];
        returnInteger = returnInteger + rowsInSectionD;
    }
    
    return returnInteger;
}

- (NSInteger)numberOfRowsInFrontOfSection:(NSUInteger)section
{
    NSInteger returnInteger = 0;
    
    for (NSUInteger d = 0; d < section; d++) {
        NSInteger rowsInSectionD = [[self.sectionArray[d] valueForKey:@"itemsInSection"] integerValue];
        returnInteger = returnInteger + rowsInSectionD;
    }
    
    return returnInteger;
}


#pragma mark - FEMultiColumnViewDelegate

- (void)multiColumnView:(FEMultiColumnView *)view didSelectRowAtIndexPath:(FEIndexPath *)indexPath
{
    UITableView *tableView = [self.multiColumnView tableViewInColumn:indexPath.column];
    NSIndexPath *idxPath = [NSIndexPath indexPathForRow:indexPath.row inSection:0];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:idxPath];
    CGRect rect = [tableView rectForRowAtIndexPath:idxPath];
    CGRect convertedRect = [tableView convertRect:rect toView:tableView.superview];
    
    self.detailSupply = self.filteredArray[indexPath.row + [self numberOfRowsInFrontOfIndex:indexPath]];
    
    
    // Snapshot of the selected Cell
    UIGraphicsBeginImageContextWithOptions(cell.bounds.size, 0, 0);
    [cell drawViewHierarchyInRect:CGRectMake(0, 0, cell.bounds.size.width, cell.bounds.size.height) afterScreenUpdates:NO];
    
    UIImage *cellSnapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    
    [self showDetailViewWithTransitionImage:cellSnapshotImage fromRect:convertedRect];
    
    [tableView deselectRowAtIndexPath:idxPath animated:YES];
}


#pragma mark - SupplyCellDelegate

- (void)infoButtonClicked:(SupplyCell *)sCell
{
    FEIndexPath *fidxPath = [self.multiColumnView indexPathForCell:sCell];
    
    UITableView *tableView = [self.multiColumnView tableViewInColumn:fidxPath.column];
    NSIndexPath *idxPath = [NSIndexPath indexPathForRow:fidxPath.row inSection:0];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:idxPath];
    CGRect rect = [tableView rectForRowAtIndexPath:idxPath];
    CGRect convertedRect = [tableView convertRect:rect toView:tableView.superview];
    
    self.detailSupply = self.filteredArray[fidxPath.row + [self numberOfRowsInFrontOfIndex:fidxPath]];
    
    // Snapshot of the selected Cell
    UIGraphicsBeginImageContextWithOptions(cell.bounds.size, 0, 0);
    [cell drawViewHierarchyInRect:CGRectMake(0, 0, cell.bounds.size.width, cell.bounds.size.height) afterScreenUpdates:NO];
    
    UIImage *cellSnapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    
    [self showDetailViewWithTransitionImage:cellSnapshotImage fromRect:convertedRect];
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
            self.nullCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height / 2, self.view.frame.size.width, 45)];
            self.nullCountLabel.center = CGPointMake(self.view.frame.size.width / 2, ([UIScreen mainScreen].bounds.size.height - 64) / 2);
        } else {
            self.nullCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height / 2, self.view.frame.size.width, 45)];
            self.nullCountLabel.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
            self.nullCountLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
        }
        
        self.nullCountLabel.backgroundColor = [UIColor clearColor];
        self.nullCountLabel.textColor = [UIColor colorWithWhite:0.33 alpha:1.0];
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
                         } completion:^(BOOL finished) {
                             [self.nullCountLabel removeFromSuperview];
                             self.nullCountVisible = NO;
                         }];
    }
}

#pragma mark - DetailViewController

- (void)showDetailViewWithTransitionImage:(UIImage *)img fromRect:(CGRect)rectx
{
    if (!self.detailControllerVisible) {
        self.detailControllerVisible = YES;
        
        CGRect rect = rectx;
        rect.origin.x = rect.origin.x - [self.multiColumnView horizontalScrollOffset];
        rect.origin.y = rect.origin.y + 64.0;
        
        self.currentDetailCellRect = rect;
        
        // WhiteCellView
        self.whiteCellView = [[UIView alloc] initWithFrame:rect];
        self.whiteCellView.backgroundColor = [UIColor whiteColor];
        self.whiteCellView.alpha = 1.0;
        [self.navigationController.view addSubview:self.whiteCellView];
        
        self.darkView = [[UIView alloc] initWithFrame:self.navigationController.view.frame];
        self.darkView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
        self.darkView.alpha = 0.0;
        self.darkView.userInteractionEnabled = YES;
        
        self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissButtonClicked:)];
        self.tap.numberOfTapsRequired = 1;
        self.tap.numberOfTouchesRequired = 1;
        
        [self.darkView addGestureRecognizer:self.tap];
        
        [self.navigationController.view addSubview:self.darkView];
        
        
        // Cell Snapshot
        self.cellSnapshotImageView = [[UIImageView alloc] initWithImage:img];
        [self.cellSnapshotImageView setFrame:rect];
        
        [self.navigationController.view addSubview:self.cellSnapshotImageView];
        
        
        // DetailController
        self.detailController = [self.storyboard instantiateViewControllerWithIdentifier:@"SUPPLY_DETAIL"];
        self.detailController.delegate = self;
        self.detailController.supply = self.detailSupply;
        [self.navigationController addChildViewController:self.detailController];
        
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
        
        
        [self.navigationController.view addSubview:self.detailController.view];
        [self.detailController didMoveToParentViewController:self.navigationController];
        
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
    }
}


#pragma mark - SupplyDetailViewControllerDelegate

- (void)dismissBackground
{
    // Remove the WhiteCellView
    [self.whiteCellView removeFromSuperview];
    self.whiteCellView = nil;
    
    [UIView animateWithDuration:0.4
                          delay:0.0
         usingSpringWithDamping:0.83
          initialSpringVelocity:0.2
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
                         self.darkView.alpha = 0.0;
                         self.detailController.view.alpha = 0.0;
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
}

- (void)dismissButtonClicked:(SupplyDetailViewController *)sDetail
{
    [UIView animateWithDuration:0.4
                          delay:0.0
         usingSpringWithDamping:0.83
          initialSpringVelocity:0.2
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
                         self.darkView.alpha = 0.0;
                         self.detailController.view.frame = self.currentDetailCellRect;
                         self.cellSnapshotImageView.frame = self.currentDetailCellRect;
                         self.detailController.view.alpha = 0.0;
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
}

- (void)orientationChanged
{
    [UIView animateWithDuration:0.14 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.view.frame = self.navigationController.view.frame;
        
        CGRect rect;
        
        if ([FEVersionChecker version] >= 8.0) {
            rect = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
        } else {
            rect = CGRectMake(0, 64.0, self.view.frame.size.width, self.view.frame.size.height - 64.0);
        }
        
        self.multiColumnView.frame = rect;
        [self.multiColumnView updateBounds];
        
        [self.darkView setFrame:self.navigationController.view.frame];
        
        static CGFloat detailWidth = 300.0;
        static CGFloat detailHeight = 210.0;
        CGFloat detailX = (self.navigationController.view.frame.size.width - detailWidth) / 2.0;
        CGFloat detailY = (self.navigationController.view.frame.size.height / 2.0) - (detailHeight / 2.0);
        
        self.detailController.view.frame = CGRectMake(detailX, detailY, detailWidth, detailHeight);
    } completion:^(BOOL finished) {
        
    }];
}

@end
