//
//  WebsiteViewController.m
//  AKG
//
//  Created by Fabian Ehlert on 30.01.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "WebsiteViewController.h"

@interface WebsiteViewController () <UIWebViewDelegate>

// iOS 7
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@property (weak, nonatomic) IBOutlet UILabel *connectionErrorLabel;

@property (weak, nonatomic) IBOutlet UIButton *backwardButtonLandscape;
@property (weak, nonatomic) IBOutlet UIButton *forwardButtonLandscape;

@property (strong, nonatomic) UIBarButtonItem *backwardItem;
@property (strong, nonatomic) UIBarButtonItem *forwardItem;


@end

@implementation WebsiteViewController

- (void)dealloc
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    self.webView = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.connectionErrorLabel.alpha = 0.0;
    self.connectionErrorLabel.text = FELocalized(@"WEB_ERROR_LOADING");
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    
    [self setupMenu];
    [self setupWebView];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
}

- (void)setupWebView
{
    self.webView.delegate = self;
    
    NSURL *akgWebsiteURL = [NSURL URLWithString:@"http://www.akg-bensheim.de"];
    [self.webView loadRequest:[NSURLRequest requestWithURL:akgWebsiteURL]];
    
    self.backwardItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"BackwardButton"]
                                                         style:UIBarButtonItemStyleBordered
                                                        target:self
                                                        action:@selector(goBackWard)];

    self.forwardItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ForwardButton"]
                                                         style:UIBarButtonItemStyleBordered
                                                        target:self
                                                        action:@selector(goForward)];

    self.navigationItem.rightBarButtonItems = @[self.forwardItem, self.backwardItem];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self.backwardButtonLandscape addTarget:self
                                         action:@selector(goBackWard)
                               forControlEvents:UIControlEventTouchUpInside];
        
        [self.forwardButtonLandscape addTarget:self
                                        action:@selector(goForward)
                              forControlEvents:UIControlEventTouchUpInside];
        
        self.forwardButtonLandscape.userInteractionEnabled = NO;
        self.backwardButtonLandscape.userInteractionEnabled = NO;
        
        self.forwardButtonLandscape.alpha = 0.0;
        self.backwardButtonLandscape.alpha = 0.0;
    }

    [self updateBackForwardItems];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Actions

- (void)goForward
{
    if ([self.webView canGoForward]) {
        [self.webView goForward];
    }
    
    [self updateBackForwardItems];
}

- (void)goBackWard
{
    if ([self.webView canGoBack]) {
        [self.webView goBack];
    }
    
    [self updateBackForwardItems];
}

- (void)updateBackForwardItems
{
    if ([self.webView canGoForward]) {
        self.forwardItem.enabled = YES;
        self.forwardButtonLandscape.enabled = YES;
    } else {
        self.forwardItem.enabled = NO;
        self.forwardButtonLandscape.enabled = NO;
    }
    
    if ([self.webView canGoBack]) {
        self.backwardItem.enabled = YES;
        self.backwardButtonLandscape.enabled = YES;
    } else {
        self.backwardItem.enabled = NO;
        self.backwardButtonLandscape.enabled = NO;
    }
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
    self.navigationItem.title = FELocalized(@"WEBSITE_KEY");
}

- (void)showMenu
{
    [self.sideMenuViewController presentLeftMenuViewController];
}


#pragma mark - Progress Indicator

- (void)setupProgressIndicator {
    
}


#pragma mark - Rotation

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
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
        if (UIDeviceOrientationIsLandscape((UIDeviceOrientation)toInterfaceOrientation)) {
            self.sideMenuViewController.panGestureEnabled = NO;
            [self.navigationController setNavigationBarHidden:YES animated:NO];
            [[UIApplication sharedApplication] setStatusBarHidden:YES];
            
            self.forwardButtonLandscape.userInteractionEnabled = YES;
            self.backwardButtonLandscape.userInteractionEnabled = YES;
            
            self.forwardButtonLandscape.alpha = 1.0;
            self.backwardButtonLandscape.alpha = 1.0;
        } else {
            self.forwardButtonLandscape.userInteractionEnabled = NO;
            self.backwardButtonLandscape.userInteractionEnabled = NO;
            
            self.forwardButtonLandscape.alpha = 0.0;
            self.backwardButtonLandscape.alpha = 0.0;
        }
    }
    [self updateBackForwardItems];
}


#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [self updateBackForwardItems];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{    
    [self updateBackForwardItems];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    [UIView animateWithDuration:0.26 animations:^{
        self.connectionErrorLabel.alpha = 0.0;
        self.webView.alpha = 1.0;
    }];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self updateBackForwardItems];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    [UIView animateWithDuration:0.26 animations:^{
        self.connectionErrorLabel.alpha = 1.0;
        self.webView.alpha = 0.0;
    }];
}

@end
