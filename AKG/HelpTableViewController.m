//
//  HelpTableViewController.m
//  AKG
//
//  Created by Fabian Ehlert on 14.02.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "HelpTableViewController.h"
#import <MessageUI/MessageUI.h>

@interface HelpTableViewController () <UIActionSheetDelegate, UIAlertViewDelegate, MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *feedbackLabel;
@property (weak, nonatomic) IBOutlet UILabel *qnaLabel;
@property (weak, nonatomic) IBOutlet UILabel *licenseLabel;
@property (weak, nonatomic) IBOutlet UILabel *versionLabelOutlet;

@property (strong, nonatomic) UIActionSheet *feedbackActionSheet;

@property (strong, nonatomic) MFMailComposeViewController *mailComposeViewController;

@end

@implementation HelpTableViewController

- (void)dealloc
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [SVProgressHUD dismiss];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = FELocalized(@"HELP_KEY");

    [self setLabels];

    [self setupMenu];
}

- (void)setLabels
{
    self.feedbackLabel.text = FELocalized(@"FEEDBACK_KEY");
    self.qnaLabel.text = FELocalized(@"QNA_KEY");
    self.licenseLabel.text = FELocalized(@"LEGAL_NOTICE_KEY");
    
    NSString *versionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    self.versionLabelOutlet.text = versionString;
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
    self.navigationItem.title = FELocalized(@"HELP_KEY");
}


#pragma mark - UITableViewControllerDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
            if (indexPath.row == 1) {
                if ([FEVersionChecker version] >= 8.0) {
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:FELocalized(@"EXTERN_WEB_ALERT_TITLE_KEY")
                                                                                   message:FELocalized(@"EXTERN_WEB_ALERT_MESSAGE_KEY")
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:FELocalized(@"CANCEL_TITLE_KEY")
                                                              style:UIAlertActionStyleCancel
                                                            handler:^(UIAlertAction *action) {
                                                                [alert dismissViewControllerAnimated:YES completion:nil];
                                                            }]];
                    [alert addAction:[UIAlertAction actionWithTitle:FELocalized(@"EXTERN_WEB_ALERT_OPEN_KEY")
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction *action) {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.akgbensheim.de/"]];
                    }]];
                    
                    [self presentViewController:alert animated:YES completion:nil];
                } else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:FELocalized(@"EXTERN_WEB_ALERT_TITLE_KEY")
                                                                    message:FELocalized(@"EXTERN_WEB_ALERT_MESSAGE_KEY")
                                                                   delegate:self
                                                          cancelButtonTitle:FELocalized(@"CANCEL_TITLE_KEY")
                                                          otherButtonTitles:FELocalized(@"EXTERN_WEB_ALERT_OPEN_KEY"), nil];
                    alert.tag = 101;
                    [alert show];
                }
            }
            break;
        case 1:
            if (indexPath.row == 1) {
                if ([FEVersionChecker version] >= 8.0) {
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:FELocalized(@"EXTERN_WEB_ALERT_TITLE_KEY")
                                                                                   message:FELocalized(@"EXTERN_APPSTORE_ALERT_MESSAGE_KEY")
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:FELocalized(@"CANCEL_TITLE_KEY")
                                                              style:UIAlertActionStyleCancel
                                                            handler:^(UIAlertAction *action) {
                                                                [alert dismissViewControllerAnimated:YES completion:nil];
                                                            }]];
                    [alert addAction:[UIAlertAction actionWithTitle:FELocalized(@"EXTERN_WEB_ALERT_OPEN_KEY")
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction *action) {
                                                                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/app/akgbensheim/id573003773"]];
                                                            }]];
                    
                    [self presentViewController:alert animated:YES completion:nil];
                } else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:FELocalized(@"EXTERN_WEB_ALERT_TITLE_KEY")
                                                                    message:FELocalized(@"EXTERN_APPSTORE_ALERT_MESSAGE_KEY")
                                                                   delegate:self
                                                          cancelButtonTitle:FELocalized(@"CANCEL_TITLE_KEY")
                                                          otherButtonTitles:FELocalized(@"EXTERN_WEB_ALERT_OPEN_KEY"), nil];
                    alert.tag = 102;
                    [alert show];
                }
            }
            break;
        case 2:
            if (indexPath.row == 0) {
                [self showFeedbackSheetFromIndexPath:indexPath];
            }
            break;
        default:
            break;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)showFeedbackSheetFromIndexPath:(NSIndexPath *)idxPath
{
    if ([FEVersionChecker version] >= 8.0) {
        UIAlertController *feedbackSheet = [UIAlertController alertControllerWithTitle:nil
                                                                               message:nil
                                                                        preferredStyle:UIAlertControllerStyleActionSheet];
        [feedbackSheet addAction:[UIAlertAction actionWithTitle:FELocalized(@"CANCEL_TITLE_KEY")
                                                          style:UIAlertActionStyleCancel
                                                        handler:^(UIAlertAction *action) {
                                                            [feedbackSheet dismissViewControllerAnimated:YES completion:nil];
                                                        }]];
        [feedbackSheet addAction:[UIAlertAction actionWithTitle:FELocalized(@"FEEDBACK_GENERAL")
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction *action) {
                                                            if ([MFMailComposeViewController canSendMail]) {
                                                                self.mailComposeViewController = [[MFMailComposeViewController alloc] init];
                                                                [self.mailComposeViewController setMailComposeDelegate:self];
                                                                [self.mailComposeViewController setToRecipients:@[@"app@akgbensheim.de"]];
                                                                
                                                                [self.mailComposeViewController setSubject:@"Feedback - AKG Bensheim iOS App"];
                                                                
                                                                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                                                                    if ([FEVersionChecker version] >= 8.0) {
                                                                        [self.mailComposeViewController setModalPresentationStyle:UIModalPresentationOverCurrentContext];
                                                                    } else {
                                                                        [self.mailComposeViewController setModalPresentationStyle:UIModalPresentationPageSheet];
                                                                    }
                                                                } else {
                                                                    [self.mailComposeViewController setModalPresentationStyle:UIModalPresentationFormSheet];
                                                                }
                                                                
                                                                [self presentViewController:self.mailComposeViewController animated:YES completion:nil];
                                                            } else {
                                                                [SVProgressHUD showErrorWithStatus:FELocalized(@"MAIL_ERROR_KEY")];
                                                            }
                                                        }]];
        [feedbackSheet addAction:[UIAlertAction actionWithTitle:FELocalized(@"FEEDBACK_HELP")
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction *action) {
                                                            if ([MFMailComposeViewController canSendMail]) {
                                                                self.mailComposeViewController = [[MFMailComposeViewController alloc] init];
                                                                [self.mailComposeViewController setMailComposeDelegate:self];
                                                                [self.mailComposeViewController setToRecipients:@[@"app@akgbensheim.de"]];
                                                                
                                                                [self.mailComposeViewController setSubject:@"Hilfe - AKG Bensheim iOS App"];
                                                                
                                                                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                                                                    if ([FEVersionChecker version] >= 8.0) {
                                                                        [self.mailComposeViewController setModalPresentationStyle:UIModalPresentationOverCurrentContext];
                                                                    } else {
                                                                        [self.mailComposeViewController setModalPresentationStyle:UIModalPresentationPageSheet];
                                                                    }
                                                                } else {
                                                                    [self.mailComposeViewController setModalPresentationStyle:UIModalPresentationFormSheet];
                                                                }
                                                                
                                                                [self presentViewController:self.mailComposeViewController animated:YES completion:nil];
                                                            } else {
                                                                [SVProgressHUD showErrorWithStatus:FELocalized(@"MAIL_ERROR_KEY")];
                                                            }
                                                        }]];
        [feedbackSheet addAction:[UIAlertAction actionWithTitle:FELocalized(@"FEEDBACK_BUG")
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction *action) {
                                                            if ([MFMailComposeViewController canSendMail]) {
                                                                self.mailComposeViewController = [[MFMailComposeViewController alloc] init];
                                                                [self.mailComposeViewController setMailComposeDelegate:self];
                                                                [self.mailComposeViewController setToRecipients:@[@"app@akgbensheim.de"]];
                                                                
                                                                [self.mailComposeViewController setSubject:@"Fehler melden - AKG Bensheim iOS App"];
                                                                
                                                                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                                                                    if ([FEVersionChecker version] >= 8.0) {
                                                                        [self.mailComposeViewController setModalPresentationStyle:UIModalPresentationOverCurrentContext];
                                                                    } else {
                                                                        [self.mailComposeViewController setModalPresentationStyle:UIModalPresentationPageSheet];
                                                                    }
                                                                } else {
                                                                    [self.mailComposeViewController setModalPresentationStyle:UIModalPresentationFormSheet];
                                                                }
                                                                
                                                                [self presentViewController:self.mailComposeViewController animated:YES completion:nil];
                                                            } else {
                                                                [SVProgressHUD showErrorWithStatus:FELocalized(@"MAIL_ERROR_KEY")];
                                                            }
                                                        }]];
        [self presentViewController:feedbackSheet animated:YES completion:nil];
    } else {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            self.feedbackActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                   delegate:self
                                                          cancelButtonTitle:FELocalized(@"CANCEL_TITLE_KEY")
                                                     destructiveButtonTitle:nil
                                                          otherButtonTitles:FELocalized(@"FEEDBACK_GENERAL"), FELocalized(@"FEEDBACK_HELP"), FELocalized(@"FEEDBACK_BUG"), nil];
            self.feedbackActionSheet.tag = 100;
            
            [self.feedbackActionSheet showInView:self.view];
        } else {
            self.feedbackActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                   delegate:self
                                                          cancelButtonTitle:FELocalized(@"CANCEL_TITLE_KEY")
                                                     destructiveButtonTitle:nil
                                                          otherButtonTitles:FELocalized(@"FEEDBACK_GENERAL"), FELocalized(@"FEEDBACK_HELP"), FELocalized(@"FEEDBACK_BUG"), nil];
            self.feedbackActionSheet.tag = 100;
            
            CGRect rect = [self.tableView rectForRowAtIndexPath:idxPath];
            [self.feedbackActionSheet showFromRect:rect inView:self.view animated:YES];
        }
    }
}

#pragma mark - Rotation

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.feedbackActionSheet dismissWithClickedButtonIndex:-1 animated:YES];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self showFeedbackSheetFromIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 101 && buttonIndex == 1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.akgbensheim.de/"]];
    } else if (alertView.tag == 102 && buttonIndex == 1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/app/akgbensheim/id573003773"]];
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet == self.feedbackActionSheet) {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            [actionSheet dismissWithClickedButtonIndex:-1 animated:YES];
        }

        if ([MFMailComposeViewController canSendMail]) {
            self.mailComposeViewController = [[MFMailComposeViewController alloc] init];
            [self.mailComposeViewController setMailComposeDelegate:self];
            [self.mailComposeViewController setToRecipients:@[@"app@akgbensheim.de"]];
            
            switch (buttonIndex) {
                case 0:
                    [self.mailComposeViewController setSubject:@"Feedback - AKG Bensheim iOS App"];

                    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                        if ([FEVersionChecker version] >= 8.0) {
                            [self.mailComposeViewController setModalPresentationStyle:UIModalPresentationOverCurrentContext];
                        } else {
                            [self.mailComposeViewController setModalPresentationStyle:UIModalPresentationPageSheet];
                        }
                    } else {
                        [self.mailComposeViewController setModalPresentationStyle:UIModalPresentationFormSheet];
                    }

                    [self presentViewController:self.mailComposeViewController animated:YES completion:nil];
                    break;
                case 1:
                    [self.mailComposeViewController setSubject:@"Hilfe - AKG Bensheim iOS App"];
                    [self.mailComposeViewController setModalPresentationStyle:UIModalPresentationFormSheet];
                    [self presentViewController:self.mailComposeViewController animated:YES completion:nil];
                    break;
                case 2:
                    [self.mailComposeViewController setSubject:@"Fehler melden - AKG Bensheim iOS App"];
                    [self.mailComposeViewController setModalPresentationStyle:UIModalPresentationFormSheet];
                    [self presentViewController:self.mailComposeViewController animated:YES completion:nil];
                    break;
                default:
                    break;
            }
        } else {
            [SVProgressHUD showErrorWithStatus:FELocalized(@"MAIL_ERROR_KEY")];
        }
    }
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
            [controller dismissViewControllerAnimated:YES completion:nil];
            break;
    }
}

@end
