//
//  AppointmentsPadViewController.m
//  AKG
//
//  Created by Fabian Ehlert on 21.04.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "AppointmentsPadViewController.h"

#import "Appointment.h"
#import "AppointmentsLoader.h"

#import "AppointmentsCell.h"

#import <EventKit/EventKit.h>
#import <EventKitUI/EventKitUI.h>
#import <MessageUI/MessageUI.h>

#import "NHCalendarActivity.h"

@interface AppointmentsPadViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, NHCalendarActivityDelegate>

@property (weak, nonatomic) IBOutlet UITableView *contentTableView;

@property (strong, nonatomic) NSArray *appointments;
@property (strong, nonatomic) NSArray *filteredAppointments;

@property (strong, nonatomic) UILabel *nullCountLabel;
@property (assign, nonatomic) BOOL nullCountVisible;

@property (strong, nonatomic) UIRefreshControl *reloadControl;

@property (strong, nonatomic) Appointment *detailAppointment;

@property (weak, nonatomic) IBOutlet UISearchBar *contentSearchBar;


// DETAIL
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) MFMailComposeViewController *mailComposer;

@end

@implementation AppointmentsPadViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.nullCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 60, 320, 35)];
    self.nullCountLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    self.nullCountLabel.translatesAutoresizingMaskIntoConstraints = YES;
    self.nullCountLabel.backgroundColor = [UIColor clearColor];
    self.nullCountLabel.textColor = [UIColor colorWithWhite:0.59 alpha:1.0];
    
    if ([FEVersionChecker version] >= 9.0) {
        self.nullCountLabel.font = [UIFont systemFontOfSize:28.0 weight:UIFontWeightLight];
    } else {
        self.nullCountLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:28.0];
    }
    
    self.nullCountLabel.text = FELocalized(@"APPOINTMENTS_NOT_AVLBL_KEY");
    self.nullCountLabel.textAlignment = NSTextAlignmentCenter;
    self.nullCountLabel.alpha = 0.0;
    
    [self.contentTableView addSubview:self.nullCountLabel];
    
    
    self.contentTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.contentTableView.separatorInset = UIEdgeInsetsMake(0, 60, 0, 0);
    
    
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.contentTableView;
    
    self.reloadControl = [[UIRefreshControl alloc] init];
    [self.reloadControl addTarget:self action:@selector(startInitialLoading) forControlEvents:UIControlEventValueChanged];
    tableViewController.refreshControl = self.reloadControl;
    
    [self showDetailItem:nil];
    
    [self setupMenu];
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
    self.navigationItem.title = FELocalized(@"APPOINTMENTS_KEY");
    
    [self startInitialLoading];
}

- (void)showMenu
{
    [self.sideMenuViewController presentLeftMenuViewController];
}


#pragma mark - Loading

- (void)startInitialLoading
{
    // 3.1 SearchBar UI
    [self.contentSearchBar setBarTintColor:[UIColor colorWithRed:(215.0/255.0) green:(215.0/255.0) blue:(217.0/255.0) alpha:1.0]];
    
    UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.contentSearchBar.frame.size.width, 1)];
    topLine.backgroundColor = [UIColor colorWithRed:(215.0/255.0) green:(215.0/255.0) blue:(217.0/255.0) alpha:1.0];
    [self.contentSearchBar addSubview:topLine];
    
    UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0, self.contentSearchBar.frame.size.height - 1, self.contentSearchBar.frame.size.width, 1)];
    bottomLine.backgroundColor = [UIColor colorWithRed:(215.0/255.0) green:(215.0/255.0) blue:(217.0/255.0) alpha:1.0];
    [self.contentSearchBar addSubview:bottomLine];

    
    [self.contentSearchBar setShowsCancelButton:NO animated:YES];
    [self.contentSearchBar resignFirstResponder];
    [self.contentSearchBar setText:@""];
    
    NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"title != nil"];
    
    self.filteredAppointments = [self.appointments filteredArrayUsingPredicate:searchPredicate];
    [self.contentTableView reloadData];
    
    if ([self.filteredAppointments count] == 0) {
        [self showNullCountLabel];
    } else {
        [self hideNullCountLabel];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Setting saved data
        self.appointments = [AppointmentsLoader savedAppointmentsFeed];
        self.filteredAppointments = self.appointments;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self finishOfflineSetup];
        });
    });
}

- (void)finishOfflineSetup
{
    [self.contentTableView reloadData];
    
    [self.contentSearchBar setShowsCancelButton:NO animated:YES];
    [self.contentSearchBar resignFirstResponder];
    [self.contentSearchBar setText:@""];
    
    NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"title != nil"];
    
    self.filteredAppointments = [self.appointments filteredArrayUsingPredicate:searchPredicate];
    [self.contentTableView reloadData];
    
    if ([self.filteredAppointments count] == 0) {
        [self showNullCountLabel];
    } else {
        [self hideNullCountLabel];
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.appointments = [AppointmentsLoader latestAppointmentsFeed];
        self.filteredAppointments = self.appointments;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.reloadControl endRefreshing];
            [self.contentTableView reloadData];
            
            if ([self.filteredAppointments count] == 0) {
                [self showNullCountLabel];
            } else {
                [self hideNullCountLabel];
            }
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        });
    });
}


#pragma mark - NullCountLabel
- (void)showNullCountLabel
{
    if (!self.nullCountVisible) {
        self.contentTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.nullCountVisible = YES;
        
        [UIView animateWithDuration:0.24 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.nullCountLabel.alpha = 1.0;
        } completion:^(BOOL finished) {
            
        }];
    }
}

- (void)hideNullCountLabel
{
    if (self.nullCountVisible) {
        [UIView animateWithDuration:0.16 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.nullCountLabel.alpha = 0.0;
            self.contentTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        } completion:^(BOOL finished) {
            self.nullCountVisible = NO;
        }];
    }
}

#pragma mark - Table view data source

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 12)];
    header.alpha = 0.f;
    header.backgroundColor = [UIColor clearColor];
    
    return header;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 12)];
    footer.alpha = 0.f;
    footer.backgroundColor = [UIColor clearColor];
    
    return footer;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60.0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    return [self.filteredAppointments count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AppointmentsCell *cell = nil;
    
    if (cell == nil) {
        cell = [self.contentTableView dequeueReusableCellWithIdentifier:@"AppointmentCell" forIndexPath:indexPath];
    }
    
    Appointment *appointment = [[Appointment alloc] init];
    appointment = self.filteredAppointments[indexPath.row];
    
    cell.titleLabel.text = appointment.title;
    cell.detailsLabel.text = appointment.details;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setLocale:[NSLocale currentLocale]];
    [formatter setDateFormat:@"yyyy/MM/dd/HH"];
    NSDate *date = [formatter dateFromString:[NSString stringWithFormat:@"%@", appointment.date]];
    
    NSDateFormatter *monthFormatter = [[NSDateFormatter alloc] init];
    [monthFormatter setLocale:[NSLocale currentLocale]];
    [monthFormatter setDateFormat:@"MMM"];
    NSString *finalMonth = [monthFormatter stringFromDate:date];
    
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *dateComponents = [gregorianCalendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:date];
    NSDateComponents *todayComponents = [gregorianCalendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:[NSDate date]];
    
    NSString *day = [NSString stringWithFormat:@"%ld", (unsigned long)[dateComponents day]];
    if ([day characterAtIndex:0] == '0') {
        day = [day stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
    }
    
    if ([todayComponents year] == [dateComponents year] && [todayComponents month] == [dateComponents month] && [todayComponents day] == [dateComponents day]) {
        cell.dayLabel.textColor = [UIColor colorWithRed:0.1 green:0.44 blue:0.9 alpha:1.0];
        cell.monthLabel.textColor = [UIColor colorWithRed:0.1 green:0.44 blue:0.9 alpha:1.0];
    } else {
        cell.dayLabel.textColor = [UIColor colorWithWhite:0.15 alpha:1.0];
        cell.monthLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    }
    
    cell.dayLabel.text = day;
    cell.monthLabel.text = [[finalMonth uppercaseString] stringByReplacingOccurrencesOfString:@"." withString:@""];
    
    return cell;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self showDetailItem:self.filteredAppointments[indexPath.row]];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)showDetailItem:(Appointment *)_appointment
{
    if (_appointment) {
        self.detailAppointment = _appointment;
        
        if (self.detailAppointment) {
            NSString *urlString = self.detailAppointment.details;
            NSURL *url = [NSURL URLWithString:urlString];
            
            [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
        }
    }
}


#pragma mark - Filter

// BEGIN
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:YES animated:YES];
    [self filterContentForSearchText:searchBar.text];
    
    return YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [searchBar setShowsCancelButton:YES animated:YES];
    [self filterContentForSearchText:searchText];
}

// CHANGE
- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    [self filterContentForSearchText:searchBar.text];
}

// END
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
    [searchBar setText:@""];
    
    NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"title != nil"];
    
    self.filteredAppointments = [self.appointments filteredArrayUsingPredicate:searchPredicate];
    [self.contentTableView reloadData];
    
    if ([self.filteredAppointments count] == 0) {
        [self showNullCountLabel];
    } else {
        [self hideNullCountLabel];
    }
}

- (void)filterContentForSearchText:(NSString *)searchText
{
    NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"(title contains[cd] %@) OR (date contains[cd] %@)", searchText, searchText];
    
    self.filteredAppointments = [self.appointments filteredArrayUsingPredicate:searchPredicate];
    [self.contentTableView reloadData];
    
    if ([self.filteredAppointments count] == 0) {
        [self showNullCountLabel];
    } else {
        [self hideNullCountLabel];
    }
}


#pragma mark - DetailActions

- (IBAction)shareAction:(UIBarButtonItem *)sender {
    if (self.detailAppointment) {
        
        NHCalendarEvent *calendarEvent = [self createCalendarEvent];
        
        NHCalendarActivity *calendarActivity = [[NHCalendarActivity alloc] init];
        calendarActivity.delegate = self;
        
        NSDate *date = [self appointmentDate];
        
        NSDateFormatter *formatter2 = [[NSDateFormatter alloc] init];
        [formatter2 setLocale:[NSLocale currentLocale]];
        [formatter2 setDateFormat:@"dd MMMM yyyy"];
        NSString *dateString = [formatter2 stringFromDate:date];
        
        if ([FEVersionChecker version] >= 8.0) {
            UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[[NSString stringWithFormat:@"%@: %@", dateString, self.detailAppointment.title], calendarEvent, [NSURL URLWithString:self.detailAppointment.details]] applicationActivities:@[calendarActivity]];

            UIView *v = [sender valueForKey:@"view"];
            
            activity.popoverPresentationController.sourceView = v;
            [self presentViewController:activity animated:YES completion:nil];
        } else {
            UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[[NSString stringWithFormat:@"%@: %@", dateString, self.detailAppointment.title], calendarEvent, [NSURL URLWithString:self.detailAppointment.details]] applicationActivities:@[calendarActivity]];

            [self presentViewController:activity animated:YES completion:nil];
        }
    }
}

- (NHCalendarEvent *)createCalendarEvent {
    NSDate *date = [self appointmentDate];
    
    NHCalendarEvent *calendarEvent = [[NHCalendarEvent alloc] init];
    
    calendarEvent.title = self.detailAppointment.title;
    calendarEvent.startDate = date;
    calendarEvent.endDate = date;
    calendarEvent.allDay = YES;
    calendarEvent.URL = [NSURL URLWithString:self.detailAppointment.details];
    
    return calendarEvent;
}

- (NSDate *)appointmentDate {
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setLocale:[NSLocale currentLocale]];
    [formatter setDateFormat:@"yyyy/MM/dd/HH"];
    return [formatter dateFromString:self.detailAppointment.date];
}


#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [SVProgressHUD show];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [SVProgressHUD dismiss];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
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
