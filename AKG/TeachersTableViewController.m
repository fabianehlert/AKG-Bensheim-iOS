//
//  TeachersTableViewController.m
//  AKG
//
//  Created by Fabian Ehlert on 09.02.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "TeachersTableViewController.h"
#import "TeacherDetailViewController.h"
#import "Teacher.h"
#import "TeacherLoader.h"
#import "TeacherCell.h"

@interface TeachersTableViewController ()

@property (strong, nonatomic) NSArray *teachersArray;
@property (strong, nonatomic) NSArray *filteredTeachersArray;

@property (strong, nonatomic) Teacher *detailTeacher;

@property (strong, nonatomic) UIRefreshControl *reloadControl;

@end

@implementation TeachersTableViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    [self.searchDisplayController.searchResultsTableView deselectRowAtIndexPath:self.searchDisplayController.searchResultsTableView.indexPathForSelectedRow animated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // 1. Setup the Menu Controls
    [self setupMenu];
    // 2. Set the inset for the separator lines
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 62, 0, 0);
    self.searchDisplayController.searchResultsTableView.separatorInset = UIEdgeInsetsMake(0, 62, 0, 0);
    // 3. Set scope titles
    [self.searchDisplayController.searchBar setScopeButtonTitles:@[FELocalized(@"FIRST_NAME"), FELocalized(@"SURNAME"), FELocalized(@"ABBREVIATION"), FELocalized(@"SUBJECTS")]];
    // 3.1 SearchBar UI
    [self.searchDisplayController.searchBar setBarTintColor:[UIColor colorWithRed:(215.0/255.0) green:(215.0/255.0) blue:(217.0/255.0) alpha:1.0]];

    UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.searchDisplayController.searchBar.frame.size.width, 1)];
    topLine.backgroundColor = [UIColor colorWithRed:(231.0/255.0) green:(231.0/255.0) blue:(234.0/255.0) alpha:1.0];
    [self.searchDisplayController.searchBar addSubview:topLine];

    UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0, self.searchDisplayController.searchBar.frame.size.height - 1, self.searchDisplayController.searchBar.frame.size.width, 1)];
    bottomLine.backgroundColor = [UIColor colorWithRed:(231.0/255.0) green:(231.0/255.0) blue:(234.0/255.0) alpha:1.0];
    [self.searchDisplayController.searchBar addSubview:bottomLine];
    
    // 4. Create and set the RefreshControl
    self.reloadControl = [[UIRefreshControl alloc] init];
    [self.reloadControl addTarget:self action:@selector(refreshTeachers) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = self.reloadControl;
    // 5. Load offline data
    [self loadSavedTeachers];
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
    
    self.teachersArray = nil;
    self.filteredTeachersArray = nil;
    self.detailTeacher = nil;
}


#pragma mark - Loading

- (void)loadSavedTeachers
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.teachersArray = [TeacherLoader savedTeachers];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    });
}

- (void)refreshTeachers
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.teachersArray = [TeacherLoader latestTeachers];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            [self.reloadControl endRefreshing];
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        });
    });
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
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(showMenu)];
    
    self.navigationItem.leftBarButtonItem = sideMenuItem;
    self.navigationItem.title = FELocalized(@"TEACHERS_KEY");
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
    return 52.0;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.tableView) {
        return [self.teachersArray count];
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [self.filteredTeachersArray count];
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TeacherCell *cell = nil;
    
    if (cell == nil) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    }
    
    
    UIFont *mediumFont = [UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0];
    if ([FEVersionChecker version] >= 9.0) {
        mediumFont = [UIFont systemFontOfSize:17.0 weight:UIFontWeightMedium];
    }
    
    UIFont *regularFont = [UIFont fontWithName:@"HelveticaNeue" size:17.0];
    if ([FEVersionChecker version] >= 9.0) {
        regularFont = [UIFont systemFontOfSize:17.0 weight:UIFontWeightRegular];
    }
    

    if (tableView == self.tableView) {
        Teacher *tc = self.teachersArray[indexPath.row];
        
        NSMutableAttributedString *fullName = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@", tc.firstName, tc.lastName]];
        [fullName addAttributes:@{NSFontAttributeName: regularFont} range:NSMakeRange(0, tc.firstName.length + 1)];
        [fullName addAttributes:@{NSFontAttributeName: mediumFont} range:NSMakeRange(tc.firstName.length + 1, tc.lastName.length)];
        
        cell.nameLabel.attributedText = fullName;
        cell.subjectsLabel.text = tc.subjects;
        cell.shortNameLabel.text = tc.shortName;
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        Teacher *tc = self.filteredTeachersArray[indexPath.row];
        
        NSMutableAttributedString *fullName = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@", tc.firstName, tc.lastName]];
        [fullName addAttributes:@{NSFontAttributeName: regularFont} range:NSMakeRange(0, tc.firstName.length + 1)];
        [fullName addAttributes:@{NSFontAttributeName: mediumFont} range:NSMakeRange(tc.firstName.length + 1, tc.lastName.length)];
        
        cell.nameLabel.attributedText = fullName;
        cell.subjectsLabel.text = tc.subjects;
        cell.shortNameLabel.text = tc.shortName;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableView) {
        self.detailTeacher = self.teachersArray[indexPath.row];
    } else if (tableView == self.searchDisplayController.searchResultsTableView) {
        self.detailTeacher = self.filteredTeachersArray[indexPath.row];
    }
    [self performSegueWithIdentifier:@"SHOW_TEACHER_DETAIL" sender:self];
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"SHOW_TEACHER_DETAIL"]) {
        TeacherDetailViewController *destination = [segue destinationViewController];
        destination.teacher = self.detailTeacher;
    }
}

#pragma mark - Filter

- (void)filterContentForSearchText:(NSString *)searchText scope:(NSInteger)searchOption
{
    NSPredicate *searchPredicate = [[NSPredicate alloc] init];
    
    switch (searchOption) {
        case 0:
            searchPredicate = [NSPredicate predicateWithFormat:@"(firstName contains[cd] %@)", searchText];
            break;
        case 1:
            searchPredicate = [NSPredicate predicateWithFormat:@"(lastName contains[cd] %@)", searchText];
            break;
        case 2:
            searchPredicate = [NSPredicate predicateWithFormat:@"(shortName contains[cd] %@)", searchText];
            break;
        case 3:
            searchPredicate = [NSPredicate predicateWithFormat:@"(subjects contains[cd] %@)", searchText];
            break;
        default:
            break;
    }
    
    self.filteredTeachersArray = [self.teachersArray filteredArrayUsingPredicate:searchPredicate];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    [self filterContentForSearchText:[controller.searchBar text] scope:searchOption];
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString scope:[controller.searchBar selectedScopeButtonIndex]];
    return YES;
}

@end
