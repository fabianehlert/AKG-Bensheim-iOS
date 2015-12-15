//
//  FAQViewController.m
//  AKG
//
//  Created by Fabian Ehlert on 01.02.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "FAQViewController.h"

@interface FAQViewController () <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UILabel *connectionErrorLabel;

@end

@implementation FAQViewController

- (void)dealloc
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
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
    
    UIBarButtonItem *reloadButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ReloadButton"]
                                                                     style:UIBarButtonItemStyleBordered
                                                                    target:self
                                                                    action:@selector(loadFAQ)];
    self.navigationItem.rightBarButtonItem = reloadButton;

    self.navigationItem.title = FELocalized(@"QNA_KEY");

    self.webView.delegate = self;
    [self loadFAQ];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Loading

- (void)loadFAQ
{
    NSURL *url = [NSURL URLWithString:@"http://akgbensheim.de/support/akgsupport.html"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [SVProgressHUD show];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [SVProgressHUD dismiss];
    
    [UIView animateWithDuration:0.26 animations:^{
        self.connectionErrorLabel.alpha = 0.0;
        self.webView.alpha = 1.0;
    }];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [SVProgressHUD dismiss];
    
    [UIView animateWithDuration:0.26 animations:^{
        self.connectionErrorLabel.alpha = 1.0;
        self.webView.alpha = 0.0;
    }];
}

@end
