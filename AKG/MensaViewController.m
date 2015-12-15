//
//  MensaViewController.m
//  AKG
//
//  Created by Fabian Ehlert on 29.01.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

static CGFloat kDefaultMenuItemHeight = 40.0;
static CGFloat kDefaultMenuItemHeightForAnimation = 46.0;

#import "MensaViewController.h"
#import "FEActionsMenuItemsStorage.h"

#import "UIImage+ImageEffects.h"

@interface MensaViewController () <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *mensaWebView;
@property (strong, nonatomic) IBOutlet UILabel *noMenuLabel;

@property (weak, nonatomic) IBOutlet UIView *navigationBarView;
@property (weak, nonatomic) IBOutlet UILabel *navTitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *navActionImageView;

@property (assign, nonatomic) BOOL navActionsRevealed;
@property (assign, nonatomic) BOOL noMenuLabelVisible;

@property (strong, nonatomic) UITapGestureRecognizer *navigationActionViewTapGestureRecognizer;

@property (strong, nonatomic) FEActionsMenuItemsStorage *itemsStorage;

@property (strong, nonatomic) UIBarButtonItem *reloadButton;
@property (strong, nonatomic) UIImageView *darkBlurBackgroundImageView;
@property (strong, nonatomic) UIView *darkPadView;
@property (strong, nonatomic) UITapGestureRecognizer *tap;

@property (assign, nonatomic) NSUInteger selectedWeek;

@end

@implementation MensaViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.translucent = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self setupMenuItems];
    
    self.selectedWeek = 0;
    [self loadMensaMenuForWeek:self.selectedWeek];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    
    self.navActionImageView.image = [[UIImage imageNamed:@"ArrowDown"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    self.navTitleLabel.text = FELocalized(@"CURRENT_WEEK");
    
    self.mensaWebView.delegate = self;
    self.noMenuLabel.alpha = 0.0;
    self.noMenuLabel.text = FELocalized(@"MENSA_NOT_AVAILABLE");
    
    self.reloadButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ReloadButton"]
                                                         style:UIBarButtonItemStyleBordered
                                                        target:self
                                                        action:@selector(reloadMensaMenu)];
    self.navigationItem.rightBarButtonItem = self.reloadButton;
    
    [self setupMenu];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [SVProgressHUD dismiss];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    self.mensaWebView = nil;
    self.itemsStorage = nil;
    self.navigationActionViewTapGestureRecognizer = nil;
    self.tap = nil;
    self.navActionImageView = nil;
    self.darkBlurBackgroundImageView = nil;
}

#pragma mark - Mensa

- (void)reloadMensaMenu {
    [self loadMensaMenuForWeek:self.selectedWeek];
}

- (void)loadMensaMenuForWeek:(NSUInteger)week {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD show];
        });
        
        NSString *menuContent;
        NSError *error = nil;
        menuContent = [[NSString alloc] initWithContentsOfURL:[self mensaURLForWeek:week] encoding:NSASCIIStringEncoding error:&error];
        
        if (menuContent.length > 0 && error == nil) {
            NSURLRequest *mensaRequest = [NSURLRequest requestWithURL:[self mensaURLForWeek:week]];
            [self.mensaWebView loadRequest:mensaRequest];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideNullCountLabel];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showNullCountLabel];
                [SVProgressHUD dismiss];
            });
        }
    });
}

- (NSURL *)mensaURLForWeek:(NSUInteger)week {
    
    NSDateComponents *dateComponents;

    if (week == 0) {
        dateComponents = [[NSCalendar currentCalendar] components:NSWeekOfYearCalendarUnit fromDate:[NSDate date]];
    } else if (week == 1) {
        dateComponents = [[NSCalendar currentCalendar] components:NSWeekOfYearCalendarUnit fromDate:[NSDate dateWithTimeIntervalSinceNow:60*60*24*7]];
    }

    NSInteger calendarweek = [dateComponents weekOfYear];
    
    NSLog(@"week= %ld", (long)calendarweek);
    
    NSString *weekString = @"";
    
    if (calendarweek < 10) {
        weekString = [NSString stringWithFormat:@"0%ld", (long)calendarweek];
    } else if (calendarweek >= 10) {
        weekString = [NSString stringWithFormat:@"%ld", (long)calendarweek];
    }
    
    NSString *url = [NSString stringWithFormat:@"http://www.akg-bensheim.de/files/%@Woche.pdf", weekString];
    
    NSLog(@"MensaURL= %@", url);
    
    return [NSURL URLWithString:url];
}

#pragma mark - Menu

- (void)showMenu
{
    [self.sideMenuViewController presentLeftMenuViewController];
}

- (void)setupMenu
{
    // SideMenuButton
    UIBarButtonItem *sideMenuItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"MenuIcon"]
                                                                     style:UIBarButtonItemStyleBordered
                                                                    target:self
                                                                    action:@selector(showMenu)];
    
    self.navigationItem.leftBarButtonItem = sideMenuItem;
    self.navigationItem.title = FELocalized(@"MENU_PLAN_KEY");
    
    // Gesture Recognizer
    self.navigationActionViewTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(navActionViewTapped:)];
    self.navigationActionViewTapGestureRecognizer.numberOfTapsRequired = 1;
    self.navigationActionViewTapGestureRecognizer.numberOfTouchesRequired = 1;
    
    [self.navigationBarView addGestureRecognizer:self.navigationActionViewTapGestureRecognizer];
}

- (void)setupMenuItems
{
    // Menu
    __weak MensaViewController *weakSelf = self;
    
    self.itemsStorage = [[FEActionsMenuItemsStorage alloc] init];
    
    UIFont *mediumFont = [UIFont fontWithName:@"HelveticaNeue-Medium" size:22.0];
    if ([FEVersionChecker version] >= 9.0) {
        mediumFont = [UIFont systemFontOfSize:22.0 weight:UIFontWeightMedium];
    }

    UIFont *lightFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:22.0];
    if ([FEVersionChecker version] >= 9.0) {
        lightFont = [UIFont systemFontOfSize:22.0 weight:UIFontWeightLight];
    }

    
    [self.itemsStorage addMenuItemWithTitle:FELocalized(@"CURRENT_WEEK") andItemSize:CGSizeMake(200, kDefaultMenuItemHeight) actions:^(FEActionsMenuItem *menuItem) {
        weakSelf.selectedWeek = 0;
        [weakSelf loadMensaMenuForWeek:weakSelf.selectedWeek];
        weakSelf.navTitleLabel.text = menuItem.title;
        
        menuItem.titleLabel.textColor = [UIColor colorWithWhite:1.0 alpha:1.0];
        menuItem.titleLabel.font = mediumFont;
        
        FEActionsMenuItem *otherItem = (FEActionsMenuItem *)weakSelf.itemsStorage.menuItems[1];
        otherItem.titleLabel.textColor = [UIColor colorWithWhite:0.75 alpha:1.0];
        otherItem.titleLabel.font = lightFont;
        
        [weakSelf hideMenuItems];
        weakSelf.navActionsRevealed = NO;
    }];
    
    [self.itemsStorage addMenuItemWithTitle:FELocalized(@"NEXT_WEEK") andItemSize:CGSizeMake(200, kDefaultMenuItemHeight) actions:^(FEActionsMenuItem *menuItem) {
        weakSelf.selectedWeek = 1;
        [weakSelf loadMensaMenuForWeek:weakSelf.selectedWeek];
        weakSelf.navTitleLabel.text = menuItem.title;
        
        menuItem.titleLabel.textColor = [UIColor colorWithWhite:1.0 alpha:1.0];
        menuItem.titleLabel.font = mediumFont;
        
        FEActionsMenuItem *otherItem = (FEActionsMenuItem *)weakSelf.itemsStorage.menuItems[0];
        otherItem.titleLabel.textColor = [UIColor colorWithWhite:0.75 alpha:1.0];
        otherItem.titleLabel.font = lightFont;
        
        [weakSelf hideMenuItems];
        weakSelf.navActionsRevealed = NO;
    }];
    
    [self.itemsStorage.menuItems enumerateObjectsUsingBlock:^(FEActionsMenuItem *item, NSUInteger idx, BOOL *stop) {
        item.frame = CGRectMake(0, -kDefaultMenuItemHeight, item.frame.size.width, item.frame.size.height);
        item.center = CGPointMake(self.view.frame.size.width / 2.0, item.center.y);
        item.backgroundColor = [UIColor clearColor];
        
        if (idx == 0) {
            item.titleLabel.textColor = [UIColor colorWithWhite:1.0 alpha:1.0];
            item.titleLabel.font = mediumFont;
        }
        
        [self.view addSubview:item];
    }];
}

- (void)navActionViewTapped:(UITapGestureRecognizer *)tap
{
    if (!self.navActionsRevealed) {
        self.navActionsRevealed = YES;
        [self revealMenuItems];
    } else {
        self.navActionsRevealed = NO;
        [self hideMenuItems];
    }
}

- (void)revealMenuItems
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height != 480.0) {
        // Snapshot of the complete TableViewController
        UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, 0, 0);
        [self.view drawViewHierarchyInRect:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height) afterScreenUpdates:NO];
        
        UIImage *backgroundImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        
        UIImage *blurredBG;
        
        blurredBG = [backgroundImage applyBlurWithRadius:4.0 tintColor:[UIColor colorWithWhite:0.0 alpha:0.85] saturationDeltaFactor:2.0 maskImage:nil];
        
        // Blur BG
        self.darkBlurBackgroundImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        self.darkBlurBackgroundImageView.userInteractionEnabled = YES;
        self.darkBlurBackgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.darkBlurBackgroundImageView.image = blurredBG;
        self.darkBlurBackgroundImageView.alpha = 0.0;
        
        self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(navActionViewTapped:)];
        self.tap.numberOfTapsRequired = 1;
        self.tap.numberOfTouchesRequired = 1;
        
        [self.darkBlurBackgroundImageView addGestureRecognizer:self.tap];
        
        [self.view insertSubview:self.darkBlurBackgroundImageView belowSubview:self.view.subviews[4]];
        
        [UIView animateWithDuration:0.1 animations:^{
            self.darkBlurBackgroundImageView.alpha = 1.0;
        }];
    } else {
        self.darkPadView = [[UIView alloc] initWithFrame:self.view.bounds];
        self.darkPadView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        self.darkPadView.userInteractionEnabled = YES;
        self.darkPadView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
        self.darkPadView.alpha = 0.0;
        
        self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(navActionViewTapped:)];
        self.tap.numberOfTapsRequired = 1;
        self.tap.numberOfTouchesRequired = 1;
        
        [self.darkPadView addGestureRecognizer:self.tap];
        
        [self.view insertSubview:self.darkPadView belowSubview:self.view.subviews[4]];
        
        [UIView animateWithDuration:0.1 animations:^{
            self.darkPadView.alpha = 1.0;
        }];
    }
    
    
    FEActionsMenuItem *item1 = self.itemsStorage.menuItems[0];
    FEActionsMenuItem *item2 = self.itemsStorage.menuItems[1];
    
    CGRect finalRect1 = CGRectMake(item1.frame.origin.x, item1.frame.origin.y + kDefaultMenuItemHeightForAnimation, item1.frame.size.width, item1.frame.size.height);
    CGRect finalRect2 = CGRectMake(item2.frame.origin.x, item2.frame.origin.y + (kDefaultMenuItemHeightForAnimation * 2), item2.frame.size.width, item2.frame.size.height);
    
    [UIView animateWithDuration:0.16 animations:^{
        self.navActionImageView.transform = CGAffineTransformMakeRotation(M_PI);
        self.navTitleLabel.alpha = 0.0;
    }];
    
    self.reloadButton.enabled = NO;
    
    [UIView animateWithDuration:0.27 delay:0.04 usingSpringWithDamping:0.62 initialSpringVelocity:0.75 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        item1.frame = finalRect1;
        item2.frame = finalRect2;
    } completion:^(BOOL finished) {
        
        if ([item1.motionEffects count] == 0) {
            [self.itemsStorage.menuItems enumerateObjectsUsingBlock:^(FEActionsMenuItem *item, NSUInteger idx, BOOL *stop) {
                UIInterpolatingMotionEffect *interpolationHorizontal = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
                interpolationHorizontal.minimumRelativeValue = @(-6);
                interpolationHorizontal.maximumRelativeValue = @(6);
                
                UIInterpolatingMotionEffect *interpolationVertical = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
                interpolationVertical.minimumRelativeValue = @(-6);
                interpolationVertical.maximumRelativeValue = @(6);
                
                [item addMotionEffect:interpolationHorizontal];
                [item addMotionEffect:interpolationVertical];
            }];
        }
    }];
}

- (void)hideMenuItems
{
    FEActionsMenuItem *item1 = self.itemsStorage.menuItems[0];
    FEActionsMenuItem *item2 = self.itemsStorage.menuItems[1];
    
    CGRect finalRect1 = CGRectMake(item1.frame.origin.x, item1.frame.origin.y - kDefaultMenuItemHeightForAnimation, item1.frame.size.width, item1.frame.size.height);
    CGRect finalRect2 = CGRectMake(item2.frame.origin.x, item2.frame.origin.y - (kDefaultMenuItemHeightForAnimation * 2), item2.frame.size.width, item2.frame.size.height);
    
    [UIView animateWithDuration:0.2 animations:^{
        self.navActionImageView.transform = CGAffineTransformMakeRotation(0.00001);
        self.navTitleLabel.alpha = 1.0;
    }];
    
    [UIView animateWithDuration:0.35 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:0.16 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        item1.frame = finalRect1;
        item2.frame = finalRect2;
    } completion:^(BOOL finished) {
        for (UIInterpolatingMotionEffect *effect in [item1 motionEffects]) {
            [item1 removeMotionEffect:effect];
        }
        
        for (UIInterpolatingMotionEffect *effect in [item2 motionEffects]) {
            [item2 removeMotionEffect:effect];
        }
    }];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height != 480.0) {
        [UIView animateWithDuration:0.14 animations:^{
            self.darkBlurBackgroundImageView.alpha = 0.0;
        } completion:^(BOOL finished) {
            self.reloadButton.enabled = YES;
            [self.darkBlurBackgroundImageView removeGestureRecognizer:self.tap];
            self.darkBlurBackgroundImageView = nil;
            self.tap = nil;
        }];
    } else {
        [UIView animateWithDuration:0.14 animations:^{
            self.darkPadView.alpha = 0.0;
        } completion:^(BOOL finished) {
            self.reloadButton.enabled = YES;
            [self.darkPadView removeGestureRecognizer:self.tap];
            self.darkPadView = nil;
            self.tap = nil;
        }];
    }
}


#pragma mark - NullCountLabel

- (void)showNullCountLabel
{
    [UIView animateWithDuration:0.26 animations:^{
        self.mensaWebView.alpha = 0.0;
        self.noMenuLabel.alpha = 1.0;
    }];
}

- (void)hideNullCountLabel
{
    [UIView animateWithDuration:0.26 animations:^{
        self.mensaWebView.alpha = 1.0;
        self.noMenuLabel.alpha = 0.0;
    }];
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [SVProgressHUD dismiss];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [SVProgressHUD dismiss];
}


#pragma mark - Rotation

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    FEActionsMenuItem *item1 = self.itemsStorage.menuItems[0];
    FEActionsMenuItem *item2 = self.itemsStorage.menuItems[1];
    
    if (self.navActionsRevealed) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            CGPoint p1 = CGPointMake(self.view.frame.size.width / 2.0, 26);
            CGPoint p2 = CGPointMake(self.view.frame.size.width / 2.0, 72);
            
            [UIView animateWithDuration:0.15 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                item1.center = p1;
                item2.center = p2;
            } completion:nil];
        } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            CGPoint p1 = CGPointMake(self.view.frame.size.width / 2.0, (item1.frame.origin.y - kDefaultMenuItemHeightForAnimation) + (item1.frame.size.height / 2.0));
            CGPoint p2 = CGPointMake(self.view.frame.size.width / 2.0, (item2.frame.origin.y - kDefaultMenuItemHeightForAnimation * 2) + (item2.frame.size.height / 2.0));
            
            item1.center = p1;
            item2.center = p2;
            
            item1.alpha = 1.0;
            item2.alpha = 1.0;
            
            self.navActionsRevealed = NO;
        }
    } else {
        CGPoint p1 = CGPointMake(self.view.frame.size.width / 2.0, item1.center.y);
        CGPoint p2 = CGPointMake(self.view.frame.size.width / 2.0, item2.center.y);
        
        item1.center = p1;
        item2.center = p2;
    }
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (fromInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || fromInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
            if (UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation)) {
                self.sideMenuViewController.panGestureEnabled = YES;
                [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
                [self.navigationController setNavigationBarHidden:NO animated:YES];
            }
        }
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (self.navActionsRevealed) {
            FEActionsMenuItem *item1 = self.itemsStorage.menuItems[0];
            FEActionsMenuItem *item2 = self.itemsStorage.menuItems[1];
            
            self.navActionImageView.transform = CGAffineTransformMakeRotation(0.00001);
            self.navTitleLabel.alpha = 1.0;
            
            for (UIInterpolatingMotionEffect *effect in [item1 motionEffects]) {
                [item1 removeMotionEffect:effect];
            }
            
            for (UIInterpolatingMotionEffect *effect in [item2 motionEffects]) {
                [item2 removeMotionEffect:effect];
            }
            
            [UIView animateWithDuration:0.1 animations:^{
                item1.alpha = 0.0;
                item2.alpha = 0.0;
                
                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height != 480.0) {
                    self.darkBlurBackgroundImageView.alpha = 0.0;
                } else {
                    self.darkPadView.alpha = 0.0;
                }
            } completion:^(BOOL finished) {
                self.reloadButton.enabled = YES;
                
                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height != 480.0) {
                    [self.darkBlurBackgroundImageView removeGestureRecognizer:self.tap];
                    self.darkBlurBackgroundImageView = nil;
                    self.tap = nil;
                } else {
                    [self.darkPadView removeGestureRecognizer:self.tap];
                    self.darkPadView = nil;
                    self.tap = nil;
                }
            }];
        }
        
        if (UIDeviceOrientationIsLandscape((UIDeviceOrientation)toInterfaceOrientation)) {
            self.sideMenuViewController.panGestureEnabled = NO;
            [self.navigationController setNavigationBarHidden:YES animated:NO];
            [[UIApplication sharedApplication] setStatusBarHidden:YES];
        }
    }
}

@end
