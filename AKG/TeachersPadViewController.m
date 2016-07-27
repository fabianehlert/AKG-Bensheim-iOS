//
//  TeachersPadViewController.m
//  AKG
//
//  Created by Fabian Ehlert on 20.04.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "TeachersPadViewController.h"
#import "TeacherDetailTableViewCell.h"
#import "Teacher.h"
#import "TeacherLoader.h"
#import "TeacherCell.h"

#import <MessageUI/MessageUI.h>

#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@interface TeachersPadViewController () <UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate, ABNewPersonViewControllerDelegate, UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UITableView *contentTableView;

@property (strong, nonatomic) NSArray *teachersArray;
@property (strong, nonatomic) NSArray *filteredTeachersArray;

@property (strong, nonatomic) Teacher *detailTeacher;

@property (strong, nonatomic) UIRefreshControl *reloadControl;

@property (weak, nonatomic) IBOutlet UISearchBar *contentSearchBar;

@property (strong, nonatomic) UILabel *noResultsLabel;

// DETAIL
@property (weak, nonatomic) IBOutlet UILabel *shortNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@property (weak, nonatomic) IBOutlet UIView *circleView;
@property (weak, nonatomic) IBOutlet UITableView *contactTableView;

@property (weak, nonatomic) IBOutlet UIImageView *kingImageView;

@property (strong, nonatomic) MFMailComposeViewController *mailComposer;
@property (strong, nonatomic) UINavigationController *navController;


@end

@implementation TeachersPadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.noResultsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 104, 320, 35)];
    self.noResultsLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    self.noResultsLabel.translatesAutoresizingMaskIntoConstraints = YES;
    self.noResultsLabel.backgroundColor = [UIColor clearColor];
    self.noResultsLabel.textColor = [UIColor colorWithWhite:0.59 alpha:1.0];
    
    if ([FEVersionChecker version] >= 9.0) {
        self.noResultsLabel.font = [UIFont systemFontOfSize:28.0 weight:UIFontWeightLight];
    } else {
        self.noResultsLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:28.0];
    }
    
    self.noResultsLabel.text = FELocalized(@"NO_RESULTS");
    self.noResultsLabel.textAlignment = NSTextAlignmentCenter;
    self.noResultsLabel.alpha = 0.0;

    [self.contentTableView addSubview:self.noResultsLabel];
    
    // 1. Setup the Menu Controls
    [self setupMenu];
    // 2. Set the inset for the separator lines
    self.contentTableView.separatorInset = UIEdgeInsetsMake(0, 62, 0, 0);
    // 3. Set scope titles
    [self.contentSearchBar setScopeButtonTitles:@[FELocalized(@"FIRST_NAME"), FELocalized(@"SURNAME"), FELocalized(@"ABBREVIATION"), FELocalized(@"SUBJECTS")]];
    [self.contentSearchBar setShowsScopeBar:YES];
    [self.contentSearchBar sizeToFit];
    
    // 3.1 SearchBar UI
    [self.contentSearchBar setBarTintColor:[UIColor colorWithRed:(215.0/255.0) green:(215.0/255.0) blue:(217.0/255.0) alpha:1.0]];
    
    UIView *topLine = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.contentSearchBar.frame.size.width, 1)];
    topLine.backgroundColor = [UIColor colorWithRed:(215.0/255.0) green:(215.0/255.0) blue:(217.0/255.0) alpha:1.0];
    [self.contentSearchBar addSubview:topLine];
    
    UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0, self.contentSearchBar.frame.size.height - 1, self.contentSearchBar.frame.size.width, 1)];
    bottomLine.backgroundColor = [UIColor colorWithRed:(215.0/255.0) green:(215.0/255.0) blue:(217.0/255.0) alpha:1.0];
    [self.contentSearchBar addSubview:bottomLine];

    
    // 4. Create and set the RefreshControl
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.contentTableView;
    
    self.reloadControl = [[UIRefreshControl alloc] init];
    [self.reloadControl addTarget:self action:@selector(refreshTeachers) forControlEvents:UIControlEventValueChanged];
    tableViewController.refreshControl = self.reloadControl;
    
    // 5. Load offline data
    [self loadSavedTeachers];
    
    
    // DETAILVIEW
    self.circleView.layer.cornerRadius = self.circleView.frame.size.width / 2.0;
    self.circleView.layer.masksToBounds = YES;
    
    self.contactTableView.dataSource = self;
    self.contactTableView.delegate = self;
    
    
    Teacher *defaultDetailTeacher = [[Teacher alloc] initWithFirstName:@"-" lastName:@"" shortName:@"-" subjects:@"-" mail:@"-"];
    [self showDetailItem:defaultDetailTeacher];
}

- (void)updateNoResultsLabel {
    if ([self.filteredTeachersArray count] == 0) {
        self.noResultsLabel.alpha = 1.0;
    } else {
        self.noResultsLabel.alpha = 0.0;
    }
}

#pragma mark - Loading

- (void)loadSavedTeachers {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.teachersArray = [TeacherLoader savedTeachers];
        self.filteredTeachersArray = self.teachersArray;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.contentTableView reloadData];
            [self updateNoResultsLabel];
        });
    });
}

- (void)refreshTeachers {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.teachersArray = [TeacherLoader latestTeachers];
        self.filteredTeachersArray = self.teachersArray;

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.contentTableView reloadData];
            [self updateNoResultsLabel];
            [self.reloadControl endRefreshing];
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        });
    });
}

#pragma mark - Menu

- (void)showMenu {
    [self.sideMenuViewController presentLeftMenuViewController];
}

- (void)setupMenu {
    // SideMenuButton
    UIBarButtonItem *sideMenuItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"MenuIcon"]
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(showMenu)];
    
    self.navigationItem.leftBarButtonItem = sideMenuItem;
    self.navigationItem.title = FELocalized(@"TEACHERS_KEY");
}

#pragma mark - Table view data source

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (tableView == self.contentTableView) {
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 12)];
        header.alpha = 0.f;
        header.backgroundColor = [UIColor clearColor];
        
        return header;
    } else if (tableView == self.contactTableView) {
        return [[UIView alloc] init];
    }
    return [[UIView alloc] init];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (tableView == self.contentTableView) {
        UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 12)];
        footer.alpha = 0.f;
        footer.backgroundColor = [UIColor clearColor];
        
        return footer;
    } else if (tableView == self.contactTableView) {
        return [[UIView alloc] init];
    }
    return [[UIView alloc] init];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 1.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 52.0;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.contentTableView) {
        return [self.filteredTeachersArray count];
    } else if (tableView == self.contactTableView) {
        return 3;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.contentTableView) {
        TeacherCell *cell = nil;
        
        if (cell == nil) {
            cell = [self.contentTableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
        }
        
//        Teacher *tc = self.filteredTeachersArray[indexPath.row];
//        cell.nameLabel.text = [NSString stringWithFormat:@"%@ %@", tc.firstName, tc.lastName];
//        cell.subjectsLabel.text = tc.subjects;
//        cell.shortNameLabel.text = tc.shortName;

        Teacher *tc = self.filteredTeachersArray[indexPath.row];
        
        UIFont *mediumFont = [UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0];
        if ([FEVersionChecker version] >= 9.0) {
            mediumFont = [UIFont systemFontOfSize:17.0 weight:UIFontWeightMedium];
        }
        
        UIFont *regularFont = [UIFont fontWithName:@"HelveticaNeue" size:17.0];
        if ([FEVersionChecker version] >= 9.0) {
            regularFont = [UIFont systemFontOfSize:17.0 weight:UIFontWeightRegular];
        }
        

        NSMutableAttributedString *fullName = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@", tc.firstName, tc.lastName]];
        [fullName addAttributes:@{NSFontAttributeName: regularFont} range:NSMakeRange(0, tc.firstName.length + 1)];
        [fullName addAttributes:@{NSFontAttributeName: mediumFont} range:NSMakeRange(tc.firstName.length + 1, tc.lastName.length)];
        
        cell.nameLabel.attributedText = fullName;
        cell.subjectsLabel.text = tc.subjects;
        cell.shortNameLabel.text = tc.shortName;

        return cell;
    } else if (tableView == self.contactTableView) {
        TeacherDetailTableViewCell *cell = nil;
        
        switch (indexPath.row) {
            case 0:
            {
                cell = [self.contactTableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.descriptionLabel.text = FELocalized(@"SUBJECTS");
                if (self.detailTeacher) {
                    cell.titleLabel.text = self.detailTeacher.subjects;
                }
            }
                break;
            case 1:
            {
                cell = [self.contactTableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                cell.descriptionLabel.text = @"Mail";
                if (self.detailTeacher) {
                    cell.titleLabel.text = self.detailTeacher.mail;
                }
            }
                break;
            case 2:
            {
                cell = [self.contactTableView dequeueReusableCellWithIdentifier:@"BCell" forIndexPath:indexPath];
                cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                cell.titleLabel.text = FELocalized(@"ADD_TO_CONTACTS");
                
                if ([self.detailTeacher.firstName isEqualToString:@"-"]) {
                    cell.titleLabel.alpha = 0.28;
                } else {
                    cell.titleLabel.alpha = 1.0;
                }
            }
                break;
            default:
                break;
        }
        
        return cell;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView == self.contentTableView) {
        [self showDetailItem:self.filteredTeachersArray[indexPath.row]];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else if (tableView == self.contactTableView) {
        switch (indexPath.row) {
            case 1:
            {
                if (![self.detailTeacher.mail isEqualToString:@"-"]) {
                    self.mailComposer = [[MFMailComposeViewController alloc] init];
                    self.mailComposer.mailComposeDelegate = self;
                    self.mailComposer.modalPresentationStyle = UIModalPresentationFormSheet;
                    self.mailComposer.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                    if (self.detailTeacher) {
                        [self.mailComposer setToRecipients:@[self.detailTeacher.mail]];
                        [self presentViewController:self.mailComposer animated:YES completion:nil];
                    }
                }
            }
                break;
            case 2:
            {
                if (![self.detailTeacher.firstName isEqualToString:@"-"]) {
                    ABNewPersonViewController *personController = [[ABNewPersonViewController alloc] init];
                    personController.modalPresentationStyle = UIModalPresentationFormSheet;
                    personController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                    personController.newPersonViewDelegate = self;
                    
                    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined || ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
                        // Access granted
                        CFErrorRef error = nil;
                        ABRecordRef newPerson = ABPersonCreate();
                        ABRecordSetValue(newPerson, kABPersonFirstNameProperty, (__bridge CFTypeRef)(self.detailTeacher.firstName), &error);
                        ABRecordSetValue(newPerson, kABPersonLastNameProperty, (__bridge CFTypeRef)(self.detailTeacher.lastName), &error);
                        
                        ABMutableMultiValueRef mail = ABMultiValueCreateMutable(kABMultiStringPropertyType);
                        ABMultiValueAddValueAndLabel(mail, (__bridge CFTypeRef)(self.detailTeacher.mail), kABWorkLabel, NULL);
                        ABRecordSetValue(newPerson, kABPersonEmailProperty, mail, nil);
                        CFRelease(mail);
                        
                        personController.displayedPerson = newPerson;
                        
                        self.navController = [[UINavigationController alloc] initWithRootViewController:personController];
                        [self presentViewController:self.navController animated:YES completion:nil];
                    } else {
                        // Access denied
                        if ([FEVersionChecker version] >= 8.0) {
                            UIAlertController *alert = [UIAlertController alertControllerWithTitle:FELocalized(@"ERROR_KEY")
                                                                                           message:FELocalized(@"ADDRESSBOOK_ERROR_MESSAGE")
                                                                                    preferredStyle:UIAlertControllerStyleAlert];
                            [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                                      style:UIAlertActionStyleCancel
                                                                    handler:^(UIAlertAction *action) {
                                                                        [alert dismissViewControllerAnimated:YES completion:nil];
                                                                    }]];
                            [self presentViewController:alert animated:YES completion:nil];
                        } else {
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:FELocalized(@"ERROR_KEY")
                                                                            message:FELocalized(@"ADDRESSBOOK_ERROR_MESSAGE")
                                                                           delegate:self
                                                                  cancelButtonTitle:@"OK"
                                                                  otherButtonTitles:nil];
                            [alert show];
                        }
                    }
                }
            }
                break;
            default:
                break;
        }
        [self.contactTableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - ABNewPersonViewControllerDelegate

- (void)newPersonViewController:(ABNewPersonViewController *)newPersonView didCompleteWithNewPerson:(ABRecordRef)person {
    [self.navController dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    switch (result) {
        case MFMailComposeResultCancelled:
            [controller dismissViewControllerAnimated:YES completion:nil];
            break;
        case MFMailComposeResultSaved:
            [controller dismissViewControllerAnimated:YES completion:nil];
            break;
        case MFMailComposeResultSent:
            [controller dismissViewControllerAnimated:YES completion:nil];
            break;
        case MFMailComposeResultFailed:
            [controller dismissViewControllerAnimated:YES completion:nil];
            break;
        default:
            break;
    }
}

#pragma mark - Navigation

- (void)showDetailItem:(Teacher *)_teacher {
    if (_teacher) {
        self.detailTeacher = _teacher;
        
        [self.contactTableView reloadData];
        
        if ([_teacher.firstName isEqualToString:@"Florian"] && [_teacher.lastName isEqualToString:@"König"]) {
            self.kingImageView.alpha = 1.0;
            self.shortNameLabel.alpha = 0.0;
        } else {
            self.kingImageView.alpha = 0.0;
            self.shortNameLabel.alpha = 1.0;
            self.shortNameLabel.text = _teacher.shortName;
        }
        self.nameLabel.text = [NSString stringWithFormat:@"%@ %@", _teacher.firstName, _teacher.lastName];
    }
}

#pragma mark - Filter

// BEGIN
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    [self.contentSearchBar setShowsCancelButton:YES animated:YES];
    [self.contentSearchBar sizeToFit];

    [self filterContentForSearchText:searchBar.text scope:searchBar.selectedScopeButtonIndex];

    return YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self.contentSearchBar setShowsCancelButton:YES animated:YES];
    [self.contentSearchBar sizeToFit];
    
    [self filterContentForSearchText:searchText scope:searchBar.selectedScopeButtonIndex];
}

// CHANGE
- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
    if (searchBar.text.length > 0) {
        [self filterContentForSearchText:searchBar.text scope:selectedScope];
    }
}

// END
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.contentSearchBar setShowsCancelButton:NO animated:YES];
    [self.contentSearchBar resignFirstResponder];
    [self.contentSearchBar setText:@""];
    
    [self.contentSearchBar sizeToFit];

    [self filterContentForSearchText:@"" scope:4];
}

- (void)filterContentForSearchText:(NSString *)searchText scope:(NSInteger)searchOption {
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
        case 4:
            searchPredicate = [NSPredicate predicateWithFormat:@"firstName != nil"];
        default:
            break;
    }
    
    self.filteredTeachersArray = [self.teachersArray filteredArrayUsingPredicate:searchPredicate];
    [self.contentTableView reloadData];
    [self updateNoResultsLabel];
}

@end
