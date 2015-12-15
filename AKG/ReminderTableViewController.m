//
//  ReminderTableViewController.m
//  AKG
//
//  Created by Fabian Ehlert on 08.09.13.
//  Copyright (c) 2013 Fabian Ehlert. All rights reserved.
//

#import "ReminderTableViewController.h"
#import <EventKit/EventKit.h>
#import "SVProgressHUD.h"

@interface ReminderTableViewController () <UIScrollViewDelegate, UIAlertViewDelegate, UIPickerViewDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButtonItem;
@property (weak, nonatomic) IBOutlet UITextField *titleTextField;
@property (weak, nonatomic) IBOutlet UITextField *notesTextField;
@property (weak, nonatomic) IBOutlet UILabel *timeDescriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationDescriptionLabel;

@property (weak, nonatomic) IBOutlet UIDatePicker *reminderDatePicker;
@property (weak, nonatomic) IBOutlet UISwitch *locationOnOffSwitch;
@property (weak, nonatomic) IBOutlet UILabel *reminderDateLabel;

@property (strong, nonatomic) EKEventStore *reminderStore;

@property (strong, nonatomic) CLLocation *akgLocaton;

@property (assign, nonatomic) BOOL pickerIsVisible;

@end

@implementation ReminderTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = FELocalized(@"REMINDER_TITLE");
    
    [self.tableView setKeyboardDismissMode:UIScrollViewKeyboardDismissModeOnDrag];
    
    self.pickerIsVisible = NO;
    
    [self setupLabels];
    
    self.titleTextField.delegate = self;
    self.notesTextField.delegate = self;
    
    self.titleTextField.text = self.titleString;
    self.notesTextField.text = self.notesString;

    self.reminderDatePicker.date = self.date;
    
    NSDateFormatter *dfForDateDisplay = [[NSDateFormatter alloc] init];
    [dfForDateDisplay setDateFormat:@"EEEE, dd. MMM HH:mm"];
    
    NSString *stringForDateDisplay = [dfForDateDisplay stringFromDate:self.date];
    self.reminderDateLabel.text = stringForDateDisplay;
    
    self.akgLocaton = [[CLLocation alloc] initWithLatitude:49.689337 longitude:8.61798];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)setupLabels
{
    self.doneButtonItem.title = FELocalized(@"ADD_KEY");
    self.cancelButtonItem.title = FELocalized(@"CANCEL_TITLE_KEY");
    self.titleTextField.placeholder = FELocalized(@"TITLE_PLACEHOLDER_KEY");
    self.notesTextField.placeholder = FELocalized(@"NOTES_PLACEHOLDER_KEY");
    self.timeDescriptionLabel.text = FELocalized(@"TIME_DESCRIPTION_KEY");
    self.locationDescriptionLabel.text = FELocalized(@"LOCATION_DESCRIPTION_KEY");
}

#pragma mark - IBActions

- (IBAction)datePickerValueChanged:(UIDatePicker *)dPicker
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEEE, dd. MMM HH:mm"];
    
    NSString *displayString = [dateFormatter stringFromDate:dPicker.date];
    self.reminderDateLabel.text = displayString;
    
    self.date = dPicker.date;
}

- (IBAction)cancelReminder:(id)sender
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    [self dismissViewControllerAnimated:YES completion:^{
        [self didCancel];
    }];
}

#pragma mark - UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 18.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 1.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [[UIView alloc] init];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return [[UIView alloc] init];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = [super tableView:tableView heightForRowAtIndexPath:indexPath];
    
    if (indexPath.row == 2) {
        if (self.pickerIsVisible) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.15 animations:^{
                    self.reminderDatePicker.alpha = 1.0;
                    self.reminderDatePicker.userInteractionEnabled = YES;
                    self.reminderDatePicker.hidden = NO;
                }];
            });
            
            return height;
        } else {
            [UIView animateWithDuration:0.15 animations:^{
                self.reminderDatePicker.alpha = 0.0;
                self.reminderDatePicker.userInteractionEnabled = NO;
            } completion:^(BOOL finished) {
                self.reminderDatePicker.hidden = YES;
            }];
            
            return 0;
        }
    }
    
    return height;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == 0) {
        [self.titleTextField becomeFirstResponder];
    }
    
    if (indexPath.row == 1) {
        self.pickerIsVisible = !self.pickerIsVisible;
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
    }
    
    if (indexPath.row == 4) {
        [self.notesTextField becomeFirstResponder];
    }
}


#pragma mark - Error handling + Protocol

- (void)startDeactivatedInfoinstance
{
    [self performSelectorOnMainThread:@selector(remindersDeactivated) withObject:NULL waitUntilDone:NO];
}

- (void)remindersDeactivated
{
    [self didFail];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)didCreate
{
    if ([self.delegate respondsToSelector:@selector(reminderDidCreate)]) {
        [self.delegate reminderDidCreate];
    }
}

- (void)didCancel
{
    if ([self.delegate respondsToSelector:@selector(reminderDidCancel)]) {
        [self.delegate reminderDidCancel];
    }
}

- (void)didFail
{
    if ([self.delegate respondsToSelector:@selector(reminderDidFail)]) {
        [self.delegate reminderDidFail];
    }
}


#pragma mark - Add Reminder

- (IBAction)addReminder:(id)sender
{
    self.reminderStore = [[EKEventStore alloc] init];
    [self.reminderStore requestAccessToEntityType:EKEntityTypeReminder
                                       completion:^(BOOL granted, NSError *error) {
                                           if (!granted) {
                                               [self startDeactivatedInfoinstance];
                                           } else {
                                               [self startCreatingReminder];
                                           }
                                       }];
}

- (void)startCreatingReminder
{
    [self performSelectorOnMainThread:@selector(createReminder) withObject:nil waitUntilDone:NO];
}

- (void)createReminder
{
    if (self.reminderStore) {
        if (self.locationOnOffSwitch.on) {
            NSDate *finalDate = self.date;
            
            EKReminder *reminder = [EKReminder reminderWithEventStore:self.reminderStore];
            reminder.title = self.titleTextField.text;
            reminder.notes = self.notesTextField.text;
            reminder.calendar = [self.reminderStore defaultCalendarForNewReminders];
            
            EKStructuredLocation *location = [EKStructuredLocation locationWithTitle:@"AKG Bensheim"];
            location.geoLocation = self.akgLocaton;
            
            EKAlarm *alarm = [[EKAlarm alloc] init];
            alarm.structuredLocation = location;
            alarm.proximity = EKAlarmProximityEnter;
            alarm.absoluteDate = finalDate;
            
            [reminder addAlarm:alarm];
            
            NSError *error = nil;
            [self.reminderStore saveReminder:reminder commit:YES error:&error];
            
            if (error) {
                NSLog(@"Line %d, ERROR= %@", __LINE__, error);
            }
            
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
            [self dismissViewControllerAnimated:YES completion:^{
                [self didCreate];
            }];;
        } else {
            NSDate *finalDate = self.date;
            
            EKReminder *reminder = [EKReminder reminderWithEventStore:self.reminderStore];
            reminder.title = self.titleTextField.text;
            reminder.notes = self.notesTextField.text;
            reminder.calendar = [self.reminderStore defaultCalendarForNewReminders];
            [reminder addAlarm:[EKAlarm alarmWithAbsoluteDate:finalDate]];
            
            EKStructuredLocation *location = [EKStructuredLocation locationWithTitle:@"AKG Bensheim"];
            location.geoLocation = self.akgLocaton;
            
            NSError *error = nil;
            [self.reminderStore saveReminder:reminder commit:YES error:&error];
            
            if (error) {
                NSLog(@"Line %d, ERROR= %@", __LINE__, error);
            }
            
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
            [self dismissViewControllerAnimated:YES completion:^{
                [self didCreate];
            }];;
        }
    }
}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}


#pragma mark - Orientation

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationPortrait | UIInterfaceOrientationPortraitUpsideDown | UIInterfaceOrientationLandscapeLeft | UIInterfaceOrientationLandscapeRight;
    } else {
        return UIInterfaceOrientationPortrait;
    }
    return UIInterfaceOrientationPortrait;
}

- (BOOL)shouldAutorotate
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    } else {
        return NO;
    }
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationMaskAll;
    } else {
        return UIInterfaceOrientationMaskPortrait;
    }
    return UIInterfaceOrientationMaskPortrait;
}

@end
