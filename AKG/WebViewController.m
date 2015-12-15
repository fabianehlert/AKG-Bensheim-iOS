//
//  WebViewController.m
//  AKG
//
//  Created by Fabian Ehlert on 15.11.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "WebViewController.h"
#import <WebKit/WebKit.h>

@interface WebViewController () <WKNavigationDelegate>

@property (strong, nonatomic) CADisplayLink *displayLink;
@property (strong, nonatomic) WKWebView *akgWebView;

@property (strong, nonatomic) UIProgressView *progressIndicator;

@end

@implementation WebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
