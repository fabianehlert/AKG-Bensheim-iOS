//
//  AppointmentsTableViewController.m
//  AKG
//
//  Created by Fabian Ehlert on 08.02.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "AppointmentsTableViewController.h"

#import "Appointment.h"
#import "AppointmentsLoader.h"

#import "AppointmentsCell.h"

#import "AppointmentDetailViewController.h"

@interface AppointmentsTableViewController ()

@property (strong, nonatomic) NSArray *appointments;
@property (strong, nonatomic) NSArray *filteredAppointments;

@property (strong, nonatomic) UIRefreshControl *reloadControl;

@property (strong, nonatomic) UILabel *nullCountLabel;
@property (assign, nonatomic) BOOL nullCountVisible;

@property (strong, nonatomic) Appointment *detailAppointment;

@end

@implementation AppointmentsTableViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    [self.searchDisplayController.searchResultsTableView deselectRowAtIndexPath:self.searchDisplayController.searchResultsTableView.indexPathForSelectedRow animated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 61, 0, 0);
    self.searchDisplayController.searchResultsTableView.separatorInset = UIEdgeInsetsMake(0, 70, 0, 0);
    self.clearsSelectionOnViewWillAppear = YES;
    
    // 3.1 SearchBar UI
    [self.searchDisplayController.searchBar setBarTintColor:[UIColor colorWithRed:(215.0/255.0) green:(215.0/255.0) blue:(217.0/255.0) alpha:1.0]];
    
    UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.searchDisplayController.searchBar.frame.size.width, 1)];
    topLine.backgroundColor = [UIColor colorWithRed:(231.0/255.0) green:(231.0/255.0) blue:(234.0/255.0) alpha:1.0];
    [self.searchDisplayController.searchBar addSubview:topLine];
    
    UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0, self.searchDisplayController.searchBar.frame.size.height - 1, self.searchDisplayController.searchBar.frame.size.width, 1)];
    bottomLine.backgroundColor = [UIColor colorWithRed:(231.0/255.0) green:(231.0/255.0) blue:(234.0/255.0) alpha:1.0];
    [self.searchDisplayController.searchBar addSubview:bottomLine];

    [self setupMenu];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    self.searchDisplayController.delegate = nil;
    self.searchDisplayController.searchResultsDelegate = nil;
    self.searchDisplayController.searchResultsDataSource = nil;
    
    self.appointments = nil;
    self.filteredAppointments = nil;
    self.detailAppointment = nil;
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
    self.navigationItem.title = FELocalized(@"APPOINTMENTS_KEY");
    
    //Reload-Control
    self.reloadControl = [[UIRefreshControl alloc] init];
    [self.reloadControl addTarget:self action:@selector(startInitialLoading) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = self.reloadControl;
    
    [self startInitialLoading];
}

- (void)showMenu
{
    [self.sideMenuViewController presentLeftMenuViewController];
}


#pragma mark - Loading

- (void)startInitialLoading
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Setting saved data
        self.appointments = [AppointmentsLoader savedAppointmentsFeed];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self finishOfflineSetup];
        });
    });
}

- (void)finishOfflineSetup
{
    [self.tableView reloadData];
    
    if ([self.appointments count] == 0) {
        [self showNullCountLabel];
    } else {
        [self hideNullCountLabel];
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.appointments = [AppointmentsLoader latestAppointmentsFeed];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.reloadControl endRefreshing];
            [self.tableView reloadData];

            if ([self.appointments count] == 0) {
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
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            self.nullCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.tableView.frame.size.height / 2, self.tableView.frame.size.width, 45)];
            self.nullCountLabel.center = CGPointMake(self.tableView.frame.size.width / 2, ([UIScreen mainScreen].bounds.size.height - 64) / 2);
            
        } else {
            self.nullCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.tableView.frame.size.height / 2, self.tableView.frame.size.width, 45)];
            self.nullCountLabel.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
            self.nullCountLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
        }
        
        self.nullCountLabel.backgroundColor = [UIColor clearColor];
        self.nullCountLabel.textColor = [UIColor colorWithWhite:0.59 alpha:1.0];
        self.nullCountLabel.highlightedTextColor = self.nullCountLabel.textColor;
        
        if ([FEVersionChecker version] >= 9.0) {
            self.nullCountLabel.font = [UIFont systemFontOfSize:28.0 weight:UIFontWeightLight];
        } else {
            self.nullCountLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:28.0];
        }

        self.nullCountLabel.textAlignment = NSTextAlignmentCenter;
        self.nullCountLabel.text = FELocalized(@"APPOINTMENTS_NOT_AVLBL_KEY");
        self.nullCountLabel.alpha = 0.0;
        
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        [self.view addSubview:self.nullCountLabel];
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
            self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        } completion:^(BOOL finished) {
            [self.nullCountLabel removeFromSuperview];
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
    if (tableView == self.tableView) {
        return [self.appointments count];
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [self.filteredAppointments count];
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AppointmentsCell *cell = nil;
    
    if (cell == nil) {
		cell = [self.tableView dequeueReusableCellWithIdentifier:@"AppointmentCell"];
		// cell = [self.tableView dequeueReusableCellWithIdentifier: @"AppointmentCell" forIndexPath: indexPath];
    }
    
    Appointment *appointment = [[Appointment alloc] init];
    if (tableView == self.tableView) {
        appointment = self.appointments[indexPath.row];
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        appointment = self.filteredAppointments[indexPath.row];
    }
    
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

    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dateComponents = [gregorianCalendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date];
    NSDateComponents *todayComponents = [gregorianCalendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:[NSDate date]];

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
    if (tableView == self.tableView) {
        self.detailAppointment = self.appointments[indexPath.row];
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        self.detailAppointment = self.filteredAppointments[indexPath.row];
    }
    
    [self performSegueWithIdentifier:@"APPOINTMENT_DETAIL" sender:nil];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"APPOINTMENT_DETAIL"]) {
        AppointmentDetailViewController *detailViewController = [segue destinationViewController];
        detailViewController.appointment = self.detailAppointment;
    }
}

#pragma mark - Filter
- (void)filterContentForSearchText:(NSString *)searchText scope:(NSString *)scope
{
    NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"(title contains[cd] %@) OR (date contains[cd] %@)", searchText, searchText];
    self.filteredAppointments = [self.appointments filteredArrayUsingPredicate:resultPredicate];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString scope:[[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    return YES;
}

@end
