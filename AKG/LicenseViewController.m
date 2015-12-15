//
//  LicenseViewController.m
//  AKG
//
//  Created by Fabian Ehlert on 01.02.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "LicenseViewController.h"

@interface LicenseViewController () <UIWebViewDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@property (strong, nonatomic) NSURL *urlToOpen;

@end

@implementation LicenseViewController

- (void)dealloc
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.webView.delegate = self;
    
    self.navigationItem.title = FELocalized(@"LEGAL_NOTICE_KEY");

    NSURL *pathUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"akgapplicense" ofType:@"html"] isDirectory:NO];
    [self.webView loadRequest:[NSURLRequest requestWithURL:pathUrl]];
    
    self.urlToOpen = [[NSURL alloc] init];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [SVProgressHUD dismiss];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	if (navigationType ==  UIWebViewNavigationTypeLinkClicked) {
        self.urlToOpen = request.URL;
        
        if ([FEVersionChecker version] >= 8.0) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:FELocalized(@"EXTERN_WEB_ALERT_TITLE_KEY")
                                                                           message:FELocalized(@"EXTERN_WEB_ALERT_MESSAGE_KEY")
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:FELocalized(@"CANCEL_TITLE_KEY")
                                                      style:UIAlertActionStyleCancel
                                                    handler:^(UIAlertAction *action) {
                                                        [alert dismissViewControllerAnimated:YES completion:nil];
                                                    }]];
            [alert addAction:[UIAlertAction actionWithTitle:FELocalized(@"EXTERN_WEB_ALERT_OPEN_KEY")
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction *action) {
                                                        [[UIApplication sharedApplication] openURL:self.urlToOpen];
            }]];
            
            [self presentViewController:alert animated:YES completion:nil];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:FELocalized(@"EXTERN_WEB_ALERT_TITLE_KEY")
                                                            message:FELocalized(@"EXTERN_WEB_ALERT_MESSAGE_KEY")
                                                           delegate:self
                                                  cancelButtonTitle:FELocalized(@"CANCEL_TITLE_KEY")
                                                  otherButtonTitles:FELocalized(@"EXTERN_WEB_ALERT_OPEN_KEY"), nil];
            alert.tag = 100;
            [alert show];
        }
		return NO;
	} else {
		return YES;
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 100 && buttonIndex == 1) {
        [[UIApplication sharedApplication] openURL:self.urlToOpen];
    }
}

@end
