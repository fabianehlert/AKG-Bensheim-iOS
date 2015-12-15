//
//  AppointmentDetailViewController.m
//  AKG
//
//  Created by Fabian Ehlert on 08.02.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "AppointmentDetailViewController.h"
#import "NHCalendarActivity.h"

@interface AppointmentDetailViewController () <UIWebViewDelegate, NHCalendarActivityDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareItem;

@end

@implementation AppointmentDetailViewController

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self hideNullCountLabel];
    
    if (self.appointment) {
        NSString *urlString = self.appointment.details;
        NSURL *url = [NSURL URLWithString:urlString];
        
        [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    } else {
        [self showNullCountLabel];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [SVProgressHUD dismiss];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - IBActions

- (IBAction)shareAction:(id)sender {
    NHCalendarEvent *calendarEvent = [self createCalendarEvent];
    
    NHCalendarActivity *calendarActivity = [[NHCalendarActivity alloc] init];
    calendarActivity.delegate = self;
    
    NSDate *date = [self appointmentDate];
    
    NSDateFormatter *formatter2 = [[NSDateFormatter alloc] init];
    [formatter2 setLocale:[NSLocale currentLocale]];
    [formatter2 setDateFormat:@"dd MMMM yyyy"];
    NSString *dateString = [formatter2 stringFromDate:date];

    UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[[NSString stringWithFormat:@"%@: %@", dateString, self.appointment.title], calendarEvent, [NSURL URLWithString:self.appointment.details]] applicationActivities:@[calendarActivity]];
    
    [self presentViewController:activity animated:YES completion:nil];
}

- (NHCalendarEvent *)createCalendarEvent {
    NSDate *date = [self appointmentDate];

    NHCalendarEvent *calendarEvent = [[NHCalendarEvent alloc] init];
    
    calendarEvent.title = self.appointment.title;
    calendarEvent.startDate = date;
    calendarEvent.endDate = date;
    calendarEvent.allDay = YES;
    calendarEvent.URL = [NSURL URLWithString:self.appointment.details];
    
    return calendarEvent;
}

- (NSDate *)appointmentDate {
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setLocale:[NSLocale currentLocale]];
    [formatter setDateFormat:@"yyyy/MM/dd/HH"];
    return [formatter dateFromString:self.appointment.date];
}

#pragma mark - Error Label

- (void)showNullCountLabel
{
    [UIView animateWithDuration:0.26 animations:^{
        self.webView.alpha = 0.0;
        self.errorLabel.alpha = 1.0;
    }];
}

- (void)hideNullCountLabel
{
    [UIView animateWithDuration:0.26 animations:^{
        self.webView.alpha = 1.0;
        self.errorLabel.alpha = 0.0;
    }];
}


#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [SVProgressHUD show];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self hideNullCountLabel];
    [SVProgressHUD dismiss];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self showNullCountLabel];
    [SVProgressHUD dismiss];
}


#pragma mark - NHCalendarActivityDelegate

- (void)calendarActivityDidFinish:(NHCalendarEvent *)event {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showSuccessWithStatus:FELocalized(@"EVENT_CREATED")];
    });
}

- (void)calendarActivityDidFail:(NHCalendarEvent *)event withError:(NSError *)error {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showErrorWithStatus:FELocalized(@"ERROR_KEY")];
    });
}

@end
