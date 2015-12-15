//
//  MenuViewController.m
//  AKG
//
//  Created by Fabian Ehlert on 23.01.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "MenuViewController.h"

#import "SupplyTableViewController.h"
#import "SupplyPadViewController.h"

#import "MensaViewController.h"

#import "HomeworkTableViewController.h"

#import "AppointmentsTableViewController.h"
#import "TeachersTableViewController.h"
#import "WebsiteViewController.h"
#import "ContactTableViewController.h"
#import "ContactPadViewController.h"

#import "SettingsTableViewController.h"
#import "HelpTableViewController.h"

#import "MenuTableViewCell.h"

static NSString *supplyPlanControllerID = @"SUPPLY";

static NSString *mensaPlanControllerID = @"MENSA";

static NSString *homeworkControllerID = @"HOMEWORK";

static NSString *appointmentsControllerID = @"APPOINTMENTS";
static NSString *teachersControllerID = @"TEACHERS";
static NSString *websiteControllerID = @"WEBSITE";
static NSString *contactControllerID = @"CONTACT";

static NSString *settingsControllerID = @"SETTINGS";
static NSString *helpControllerID = @"HELP";

@interface MenuViewController ()

@property (strong, nonatomic) UITableView *menuTableView;

@end

@implementation MenuViewController

#pragma mark - ViewController lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor clearColor];
    
    [self initializeMenuTableView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

#pragma mark - private initializers
- (void)initializeMenuTableView
{
    CGRect tableRect = CGRectZero;
    CGFloat topInset = 0.0;
    CGFloat bottomInset = 0.0;
    
    if (self.view.frame.size.height > 496.0) {
        tableRect = CGRectMake(0, (self.view.frame.size.height - 496) / 2.0f, self.view.frame.size.width, 496);
    } else {
        tableRect = CGRectMake(0, 20.0, self.view.frame.size.width, self.view.frame.size.height - 20.0);
        topInset = 30.0;
        bottomInset = 65.0;
    }
    
    self.menuTableView = [[UITableView alloc] initWithFrame:tableRect];
    self.menuTableView.contentInset = UIEdgeInsetsMake(topInset, 0.0, bottomInset, 0.0);
    self.menuTableView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    self.menuTableView.opaque = NO;
    self.menuTableView.backgroundView = nil;
    self.menuTableView.backgroundColor = [UIColor clearColor];
    self.menuTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.menuTableView.scrollsToTop = NO;
    self.menuTableView.showsHorizontalScrollIndicator = NO;
    self.menuTableView.showsVerticalScrollIndicator = NO;
    
    self.menuTableView.delegate = self;
    self.menuTableView.dataSource = self;
    
    [self.view addSubview:self.menuTableView];
}

#pragma mark - orientation
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    /*
     ///---> no longer necessary!!
     ///---> AutoResizingMask solves the problem!
#error don´t implement this!
    CGRect tableRect = CGRectZero;
    CGFloat topInset = 0.0;
    CGFloat bottomInset = 0.0;
    
    if (self.view.frame.size.height > 496.0) {
        tableRect = CGRectMake(0, (self.view.frame.size.height - 496) / 2.0f, self.view.frame.size.width, 496);
    } else {
        tableRect = CGRectMake(0, 20.0, self.view.frame.size.width, self.view.frame.size.height - 20.0);
        topInset = 30.0;
        bottomInset = 65.0;
    }
    
    [self.menuTableView setFrame:tableRect];
    [self.menuTableView setContentInset:UIEdgeInsetsMake(topInset, 0.0, bottomInset, 0.0)];
    [self.menuTableView setNeedsDisplay];
    
    [self.menuTableView beginUpdates];
    [self.menuTableView endUpdates];
    */
}

#pragma mark - StatusBar

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 1;
            break;
        case 1:
            return 1;
            break;
        case 2:
            return 1;
            break;
        case 3:
            return 4;
            break;
        case 4:
            return 2;
            break;
        default:
            break;
    }
    
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [[UIView alloc] init];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 20.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"Cell";
    
    MenuTableViewCell *cell = (MenuTableViewCell *)[self.menuTableView dequeueReusableCellWithIdentifier:cellID];
    
    if (cell == nil) {
        cell = [[MenuTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
        cell.backgroundColor = [UIColor clearColor];

        if ([FEVersionChecker version] >= 9.0) {
            cell.textLabel.font = [UIFont systemFontOfSize:21.0 weight:UIFontWeightLight];
        } else {
            cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:21.0];
        }
        
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.highlightedTextColor = [UIColor whiteColor];
        
        cell.selectedBackgroundView = ({
            UIView *selectedCellBG = [[UIView alloc] init];
            selectedCellBG.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.22];
            selectedCellBG;
        });
    }
    
    switch (indexPath.section) {
        case 0:
            if (indexPath.row == 0) {
                cell.textLabel.text = FELocalized(@"SUPPLY_PLAN_KEY");
                cell.imageView.image = [UIImage imageNamed:@"SideMenuSupply"];
            }
            break;
        case 1:
            if (indexPath.row == 0) {
                cell.textLabel.text = FELocalized(@"MENU_PLAN_KEY");
                cell.imageView.image = [UIImage imageNamed:@"SideMenuMensa"];
            }
            break;
        case 2:
            if (indexPath.row == 0) {
                cell.textLabel.text = FELocalized(@"HOMEWORK_KEY");
                cell.imageView.image = [UIImage imageNamed:@"SideMenuHomework"];
            }
            break;
        case 3:
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = FELocalized(@"APPOINTMENTS_KEY");
                    cell.imageView.image = [UIImage imageNamed:@"SideMenuCalendar"];
                    break;
                case 1:
                    cell.textLabel.text = FELocalized(@"TEACHERS_KEY");
                    cell.imageView.image = [UIImage imageNamed:@"SideMenuTeachers"];
                    break;
                case 2:
                    cell.textLabel.text = FELocalized(@"WEBSITE_KEY");
                    cell.imageView.image = [UIImage imageNamed:@"SideMenuWebsite"];
                    break;
                case 3:
                    cell.textLabel.text = FELocalized(@"CONTACT_KEY");
                    cell.imageView.image = [UIImage imageNamed:@"SideMenuContact"];
                    break;
                default:
                    break;
            }
            break;
        case 4:
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = FELocalized(@"SETTINGS_KEY");
                    cell.imageView.image = [UIImage imageNamed:@"SideMenuSettings"];
                    break;
                case 1:
                    cell.textLabel.text = FELocalized(@"HELP_KEY");
                    cell.imageView.image = [UIImage imageNamed:@"SideMenuHelp"];
                    break;
                default:
                    break;
            }
            break;
        default:
            break;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
    switch (indexPath.section) {
        case 0:
            if (indexPath.row == 0) {
                [self.sideMenuViewController setContentViewController:[[UINavigationController alloc] initWithRootViewController:[self.storyboard instantiateViewControllerWithIdentifier:supplyPlanControllerID]] animated:YES];
                [self.sideMenuViewController hideMenuViewController];
            }
            break;
        case 1:
            if (indexPath.row == 0) {
                    [self.sideMenuViewController setContentViewController:[[UINavigationController alloc] initWithRootViewController:[self.storyboard instantiateViewControllerWithIdentifier:mensaPlanControllerID]] animated:YES];
                    [self.sideMenuViewController hideMenuViewController];
            }
            break;
        case 2:
            if (indexPath.row == 0) {
                [self.sideMenuViewController setContentViewController:[[UINavigationController alloc] initWithRootViewController:[self.storyboard instantiateViewControllerWithIdentifier:homeworkControllerID]] animated:YES];
                [self.sideMenuViewController hideMenuViewController];
            }
            break;
        case 3:
            switch (indexPath.row) {
                case 0:
                    [self.sideMenuViewController setContentViewController:[[UINavigationController alloc] initWithRootViewController:[self.storyboard instantiateViewControllerWithIdentifier:appointmentsControllerID]] animated:YES];
                    [self.sideMenuViewController hideMenuViewController];
                    break;
                case 1:
                    [self.sideMenuViewController setContentViewController:[[UINavigationController alloc] initWithRootViewController:[self.storyboard instantiateViewControllerWithIdentifier:teachersControllerID]] animated:YES];
                    [self.sideMenuViewController hideMenuViewController];
                    break;
                case 2:
                    [self.sideMenuViewController setContentViewController:[[UINavigationController alloc] initWithRootViewController:[self.storyboard instantiateViewControllerWithIdentifier:websiteControllerID]] animated:YES];
                    [self.sideMenuViewController hideMenuViewController];
                    break;
                case 3:
                    [self.sideMenuViewController setContentViewController:[[UINavigationController alloc] initWithRootViewController:[self.storyboard instantiateViewControllerWithIdentifier:contactControllerID]] animated:YES];
                    [self.sideMenuViewController hideMenuViewController];
                    break;
                default:
                    break;
            }
            break;
        case 4:
            switch (indexPath.row) {
                case 0:
                    [self.sideMenuViewController setContentViewController:[[UINavigationController alloc] initWithRootViewController:[self.storyboard instantiateViewControllerWithIdentifier:settingsControllerID]] animated:YES];
                    [self.sideMenuViewController hideMenuViewController];
                    break;
                case 1:
                    [self.sideMenuViewController setContentViewController:[[UINavigationController alloc] initWithRootViewController:[self.storyboard instantiateViewControllerWithIdentifier:helpControllerID]] animated:YES];
                    [self.sideMenuViewController hideMenuViewController];
                    break;
                default:
                    break;
            }
            break;
        default:
            break;
    }
}

#pragma mark RESideMenu Delegate

- (void)sideMenu:(RESideMenu *)sideMenu needStatusBarStyleUpdateToStyle:(UIStatusBarStyle)style
{
    [[UIApplication sharedApplication] setStatusBarStyle:style animated:YES];
}

- (void)sideMenu:(RESideMenu *)sideMenu willShowMenuViewController:(UIViewController *)menuViewController
{
    self.sideMenuViewController.backgroundImageView.alpha = 1.0;
}

- (void)sideMenu:(RESideMenu *)sideMenu didShowMenuViewController:(UIViewController *)menuViewController
{
    self.sideMenuViewController.backgroundImageView.alpha = 1.0;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
}

- (void)sideMenu:(RESideMenu *)sideMenu willHideMenuViewController:(UIViewController *)menuViewController
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

- (void)sideMenu:(RESideMenu *)sideMenu didHideMenuViewController:(UIViewController *)menuViewController
{
    self.sideMenuViewController.backgroundImageView.alpha = 0.0;
}

@end
