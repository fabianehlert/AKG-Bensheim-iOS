//
//  ContactTableViewController.m
//  AKG
//
//  Created by Fabian Ehlert on 01.02.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "ContactTableViewController.h"
#import "ContactTableViewCell.h"
#import <MessageUI/MessageUI.h>
#import <MapKit/MapKit.h>

@interface ContactTableViewController () <UIAlertViewDelegate, MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;
@property (weak, nonatomic) IBOutlet UILabel *akgDirektionLabel;
@property (weak, nonatomic) IBOutlet UILabel *directionsLabel;

@property (strong, nonatomic) MFMailComposeViewController *mailComposer;

@end

@implementation ContactTableViewController

- (void)dealloc
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    self.mailComposer = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setLabels];
    
    [self setupMenu];
}

- (void)setLabels
{
    self.addressLabel.text = FELocalized(@"ADDRESS_KEY");
    self.phoneLabel.text = FELocalized(@"PHONE_KEY");
    self.akgDirektionLabel.text = FELocalized(@"AKG_DIREKTION_KEY");
    self.directionsLabel.text = FELocalized(@"MAP_DIRECTIONS_KEY");
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
    self.navigationItem.title = FELocalized(@"CONTACT_KEY");
}

- (void)showMenu
{
    [self.sideMenuViewController presentLeftMenuViewController];
}


#pragma mark - MAP

- (void)showDirections
{
    Class mapItemClass = [MKMapItem class];
    if (mapItemClass && [mapItemClass respondsToSelector:@selector(openMapsWithItems:launchOptions:)]) {
        // Create an MKMapItem to pass to the Maps app
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(49.689337, 8.61798);
        MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:coordinate addressDictionary:nil];
        MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
        [mapItem setName:@"AKG Bensheim"];
        
        // MKLaunchOptionsDirectionsModeDriving
        NSDictionary *launchOptions = @{MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving};
        // Get the "Current User Location" MKMapItem
        MKMapItem *currentLocationMapItem = [MKMapItem mapItemForCurrentLocation];
        // Pass the current location and destination map items to the Maps app
        // Set the direction mode in the launchOptions dictionary
        [MKMapItem openMapsWithItems:@[currentLocationMapItem, mapItem] launchOptions:launchOptions];
    }
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ContactTableViewCell *cell = (ContactTableViewCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        cell.titleLabel.text = @"Wilhelmstraße 62\n64625 Bensheim";
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.section) {
        case 0:
            break;
        case 1:
            if (indexPath.row == 0) {
                if ([[UIDevice currentDevice].model isEqualToString:@"iPhone"]) {
                    if ([FEVersionChecker version] >= 8.0) {
                        UIAlertController *phoneAlert = [UIAlertController alertControllerWithTitle:FELocalized(@"PHONE_ALERT_TITLE_KEY")
                                                                                            message:FELocalized(@"PHONE_ALERT_MESSAGE_KEY")
                                                                                     preferredStyle:UIAlertControllerStyleAlert];
                        [phoneAlert addAction:[UIAlertAction actionWithTitle:FELocalized(@"NO_KEY")
                                                                       style:UIAlertActionStyleCancel
                                                                     handler:^(UIAlertAction *action) {
                                                                         [phoneAlert dismissViewControllerAnimated:YES completion:nil];
                        }]];
                        
                        [phoneAlert addAction:[UIAlertAction actionWithTitle:FELocalized(@"CALL_KEY")
                                                                       style:UIAlertActionStyleDefault
                                                                     handler:^(UIAlertAction *action) {
                                                                         [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"tel:0049625184320"]];
                        }]];
                        
                        [self presentViewController:phoneAlert animated:YES completion:nil];
                    } else {
                        UIAlertView *phoneAlert = [[UIAlertView alloc] initWithTitle:FELocalized(@"PHONE_ALERT_TITLE_KEY")
                                                                             message:FELocalized(@"PHONE_ALERT_MESSAGE_KEY")
                                                                            delegate:self
                                                                   cancelButtonTitle:FELocalized(@"NO_KEY")
                                                                   otherButtonTitles:FELocalized(@"CALL_KEY"), nil];
                        phoneAlert.tag = 100;
                        [phoneAlert show];
                    }
                } else {
                    [SVProgressHUD showErrorWithStatus:FELocalized(@"PHONE_ERROR_TITLE_KEY")];
                }
            }
            break;
        case 2:
            if (indexPath.row == 0) {
                if ([MFMailComposeViewController canSendMail]) {
                    self.mailComposer = [[MFMailComposeViewController alloc] init];
                    [self.mailComposer setMailComposeDelegate:self];
                    [self.mailComposer setSubject:@"AKG Bensheim - Direktion"];
                    [self.mailComposer setToRecipients:@[@"direktion@akg-bensheim.de"]];
                    [self.mailComposer setModalPresentationStyle:UIModalPresentationFormSheet];
                    
                    [self presentViewController:self.mailComposer animated:YES completion:nil];
                } else {
                    [SVProgressHUD showErrorWithStatus:FELocalized(@"MAIL_ERROR_KEY")];
                }
            } else if (indexPath.row == 1) {
                if ([MFMailComposeViewController canSendMail]) {
                    self.mailComposer = [[MFMailComposeViewController alloc] init];
                    [self.mailComposer setMailComposeDelegate:self];
                    [self.mailComposer setSubject:@"AKG Bensheim - Information"];
                    [self.mailComposer setToRecipients:@[@"info@akg-bensheim.de"]];
                    [self.mailComposer setModalPresentationStyle:UIModalPresentationFormSheet];
                    
                    [self presentViewController:self.mailComposer animated:YES completion:nil];
                } else {
                    [SVProgressHUD showErrorWithStatus:FELocalized(@"MAIL_ERROR_KEY")];
                }
            }
            break;
        case 3:
            if (indexPath.row == 0) {
                if ([FEVersionChecker version] >= 8.0) {
                    UIAlertController *mapAlert = [UIAlertController alertControllerWithTitle:FELocalized(@"MAP_ALERT_TITLE_KEY")
                                                                                      message:FELocalized(@"MAP_ALERT_MESSAGE_KEY")
                                                                               preferredStyle:UIAlertControllerStyleAlert];
                    [mapAlert addAction:[UIAlertAction actionWithTitle:FELocalized(@"CANCEL_TITLE_KEY")
                                                                 style:UIAlertActionStyleCancel
                                                               handler:^(UIAlertAction *action) {
                                                                   [mapAlert dismissViewControllerAnimated:YES completion:nil];
                                                               }]];
                    
                    [mapAlert addAction:[UIAlertAction actionWithTitle:FELocalized(@"EXTERN_WEB_ALERT_OPEN_KEY")
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction *action) {
                                                                   [self showDirections];
                                                               }]];
                    
                    [self presentViewController:mapAlert animated:YES completion:nil];
                } else {
                    UIAlertView *mapAlert = [[UIAlertView alloc] initWithTitle:FELocalized(@"MAP_ALERT_TITLE_KEY")
                                                                       message:FELocalized(@"MAP_ALERT_MESSAGE_KEY")
                                                                      delegate:self
                                                             cancelButtonTitle:FELocalized(@"CANCEL_TITLE_KEY")
                                                             otherButtonTitles:FELocalized(@"EXTERN_WEB_ALERT_OPEN_KEY"), nil];
                    mapAlert.tag = 101;
                    [mapAlert show];
                }
            }
            break;
        default:
            break;
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 100 && buttonIndex == 1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"tel:0049625184320"]];
    } else if (alertView.tag == 101 && buttonIndex == 1) {
        [self showDirections];
    }
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    if (controller == self.mailComposer) {
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
                [controller dismissViewControllerAnimated:YES completion:nil];
                break;
        }
    }
}

@end
