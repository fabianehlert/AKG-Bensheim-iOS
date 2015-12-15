//
//  TeacherDetailViewController.m
//  AKG
//
//  Created by Fabian Ehlert on 15.02.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "TeacherDetailViewController.h"
#import "TeacherDetailTableViewCell.h"

#import <MessageUI/MessageUI.h>

#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@interface TeacherDetailViewController () <UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate, ABNewPersonViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *shortNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@property (weak, nonatomic) IBOutlet UIView *circleView;
@property (weak, nonatomic) IBOutlet UITableView *contactTableView;

@property (weak, nonatomic) IBOutlet UIImageView *kingImageView;

@property (strong, nonatomic) MFMailComposeViewController *mailComposer;
@property (strong, nonatomic) UINavigationController *navController;

@end

@implementation TeacherDetailViewController

- (void)dealloc
{
    NSLog(@"%s", __PRETTY_FUNCTION__);

    self.teacher = nil;
    self.mailComposer = nil;
    self.navController = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.teacher) {
        if ([self.teacher.firstName isEqualToString:@"Florian"] && [self.teacher.lastName isEqualToString:@"König"]) {
            self.kingImageView.alpha = 1.0;
            self.shortNameLabel.alpha = 0.0;
        } else {
            self.kingImageView.alpha = 0.0;
            self.shortNameLabel.alpha = 1.0;
            self.shortNameLabel.text = self.teacher.shortName;
        }
        self.nameLabel.text = [NSString stringWithFormat:@"%@ %@", self.teacher.firstName, self.teacher.lastName];
    }
    
    self.circleView.layer.cornerRadius = self.circleView.frame.size.width / 2.0;
    self.circleView.layer.masksToBounds = YES;
    
    self.contactTableView.dataSource = self;
    self.contactTableView.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 1.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [[UIView alloc] init];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return [[UIView alloc] init];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TeacherDetailTableViewCell *cell = nil;
    
    switch (indexPath.row) {
        case 0:
        {
            cell = [self.contactTableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.descriptionLabel.text = FELocalized(@"SUBJECTS");
            if (self.teacher) {
                cell.titleLabel.text = self.teacher.subjects;
            }
        }
            break;
        case 1:
        {
            cell = [self.contactTableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.descriptionLabel.text = @"Mail";
            if (self.teacher) {
                cell.titleLabel.text = self.teacher.mail;
            }
        }
            break;
        case 2:
        {
            cell = [self.contactTableView dequeueReusableCellWithIdentifier:@"BCell" forIndexPath:indexPath];
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
            cell.titleLabel.text = FELocalized(@"ADD_TO_CONTACTS");
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
    switch (indexPath.row) {
        case 1:
        {
            self.mailComposer = [[MFMailComposeViewController alloc] init];
            self.mailComposer.mailComposeDelegate = self;
            self.mailComposer.modalPresentationStyle = UIModalPresentationFormSheet;
            self.mailComposer.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            if (self.teacher) {
                [self.mailComposer setToRecipients:@[self.teacher.mail]];
                [self presentViewController:self.mailComposer animated:YES completion:nil];
            }
        }
            break;
        case 2:
        {
            ABNewPersonViewController *personController = [[ABNewPersonViewController alloc] init];
            personController.modalPresentationStyle = UIModalPresentationFormSheet;
            personController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            personController.newPersonViewDelegate = self;
            
            if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined || ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
                // Access granted
                CFErrorRef error = nil;
                ABRecordRef newPerson = ABPersonCreate();
                ABRecordSetValue(newPerson, kABPersonFirstNameProperty, (__bridge CFTypeRef)(self.teacher.firstName), &error);
                ABRecordSetValue(newPerson, kABPersonLastNameProperty, (__bridge CFTypeRef)(self.teacher.lastName), &error);
                
                ABMutableMultiValueRef mail = ABMultiValueCreateMutable(kABMultiStringPropertyType);
                ABMultiValueAddValueAndLabel(mail, (__bridge CFTypeRef)(self.teacher.mail), kABWorkLabel, NULL);
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
            break;
        default:
            break;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - ABNewPersonViewControllerDelegate

- (void)newPersonViewController:(ABNewPersonViewController *)newPersonView didCompleteWithNewPerson:(ABRecordRef)person
{
    [self.navController dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
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

@end
