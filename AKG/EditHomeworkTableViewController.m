//
//  EditHomeworkTableViewController.m
//  AKG
//
//  Created by Fabian Ehlert on 08.03.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "EditHomeworkTableViewController.h"
#import "AppDelegate.h"

@interface EditHomeworkTableViewController () <UIActionSheetDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *subjectTextField;
@property (weak, nonatomic) IBOutlet UITextField *taskTitleTextField;
@property (weak, nonatomic) IBOutlet UITextView *taskNotesTextView;
@property (weak, nonatomic) IBOutlet UIDatePicker *dueDatePicker;
@property (weak, nonatomic) IBOutlet UILabel *taskNotesDescriptionLabel;

@property (weak, nonatomic) IBOutlet UILabel *toggleDoneLabel;
@property (weak, nonatomic) IBOutlet UILabel *deleteLabel;

@property (strong, nonatomic) UIBarButtonItem *closeButton;
@property (strong, nonatomic) UIBarButtonItem *saveButton;

@property (assign, nonatomic) NSNumber *taskIsDone;

@property (strong, nonatomic) AppDelegate *appDelegate;

@end

@implementation EditHomeworkTableViewController

- (void)dealloc
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    self.title = FELocalized(@"TASK_TITLE");
    [self.subjectTextField setPlaceholder:FELocalized(@"SUBJECT_TITLE")];
    [self.taskTitleTextField setPlaceholder:FELocalized(@"TASK_TITLE")];
    [self.taskNotesDescriptionLabel setText:FELocalized(@"TASK_NOTES")];
    self.deleteLabel.text = FELocalized(@"DELETE_TASK_TITLE");

    self.subjectTextField.delegate = self;
    self.taskTitleTextField.delegate = self;

    self.closeButton = [[UIBarButtonItem alloc] initWithTitle:FELocalized(@"CLOSE_TITLE")
                                                        style:UIBarButtonItemStylePlain
                                                       target:self
                                                       action:@selector(closeAction)];
    self.navigationItem.leftBarButtonItem = self.closeButton;
    
    self.saveButton = [[UIBarButtonItem alloc] initWithTitle:FELocalized(@"SAVE_KEY")
                                                        style:UIBarButtonItemStyleDone
                                                       target:self
                                                       action:@selector(saveAction)];
    self.navigationItem.rightBarButtonItem = self.saveButton;

    if (self.homework) {
        self.subjectTextField.text = self.homework.subject;
        self.taskTitleTextField.text = self.homework.taskTitle;
        self.taskNotesTextView.text = self.homework.taskNote;
        self.dueDatePicker.date = self.homework.dueDate;

        self.taskIsDone = self.homework.done;
        if ([self.taskIsDone unsignedIntegerValue] == (long)0) {
            self.toggleDoneLabel.text = FELocalized(@"MARK_TASK_AS_DONE");
            self.toggleDoneLabel.textColor = [UIColor colorWithRed:0.0 green:0.88 blue:0.0 alpha:1.0];
        } else if ([self.taskIsDone unsignedIntegerValue] == (long)1) {
            self.toggleDoneLabel.text = FELocalized(@"MARK_TASK_AS_UN_DONE");
            self.toggleDoneLabel.textColor = [UIColor colorWithWhite:0.45 alpha:1.0];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - Actions

- (void)closeAction
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)saveAction
{
    [self saveChanges];
    
    if ([self.delegate respondsToSelector:@selector(shouldUpdateContent)]) {
        [self.delegate shouldUpdateContent];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Private

- (void)saveChanges
{
    self.homework.subject = self.subjectTextField.text;
    self.homework.taskTitle = self.taskTitleTextField.text;
    self.homework.taskNote = self.taskNotesTextView.text;
    self.homework.dueDate = self.dueDatePicker.date;
    self.homework.done = self.taskIsDone;
    
    [self.appDelegate saveContext];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == 100) {
        switch (buttonIndex) {
            case 0:
                if ([self.delegate respondsToSelector:@selector(willDeleteHomework:)]) {
                    [self.delegate willDeleteHomework:self.homework];
                    [self closeAction];
                }
                break;
                
            default:
                break;
        }
    }
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 3 && indexPath.row == 0) {
        [self.taskNotesTextView becomeFirstResponder];
    }
    
    if (indexPath.section == 4 && indexPath.row == 0) {
        // Toggle done
        if ([self.taskIsDone unsignedIntegerValue] == (long)0) {
            self.taskIsDone = [NSNumber numberWithUnsignedInteger:(long)1];
        } else if ([self.taskIsDone unsignedIntegerValue] == (long)1) {
            self.taskIsDone = [NSNumber numberWithUnsignedInteger:(long)0];
        }
        
        if ([self.taskIsDone unsignedIntegerValue] == (long)0) {
            self.toggleDoneLabel.text = FELocalized(@"MARK_TASK_AS_DONE");
            self.toggleDoneLabel.textColor = [UIColor colorWithRed:0.0 green:0.88 blue:0.0 alpha:1.0];
        } else if ([self.taskIsDone unsignedIntegerValue] == (long)1) {
            self.toggleDoneLabel.text = FELocalized(@"MARK_TASK_AS_UN_DONE");
            self.toggleDoneLabel.textColor = [UIColor colorWithWhite:0.45 alpha:1.0];
        }
    }
    
    if (indexPath.section == 5 && indexPath.row == 0) {
        if ([FEVersionChecker version] >= 8.0) {
            UIAlertController *deleteSheet = [UIAlertController alertControllerWithTitle:FELocalized(@"DELETE_TASK_QUESTION")
                                                                                 message:nil
                                                                          preferredStyle:UIAlertControllerStyleActionSheet];
            [deleteSheet addAction:[UIAlertAction actionWithTitle:FELocalized(@"CANCEL_TITLE_KEY")
                                                            style:UIAlertActionStyleCancel
                                                          handler:^(UIAlertAction *action) {
                                                              [deleteSheet dismissViewControllerAnimated:YES completion:nil];
                                                          }]];
            [deleteSheet addAction:[UIAlertAction actionWithTitle:FELocalized(@"DELETE_TITLE") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                if ([self.delegate respondsToSelector:@selector(willDeleteHomework:)]) {
                    [self.delegate willDeleteHomework:self.homework];
                    [self closeAction];
                }
            }]];
            
            [self presentViewController:deleteSheet animated:YES completion:nil];
        } else {
            UIActionSheet *deleteSheet = [[UIActionSheet alloc] initWithTitle:FELocalized(@"DELETE_TASK_QUESTION")
                                                                     delegate:self
                                                            cancelButtonTitle:FELocalized(@"CANCEL_TITLE_KEY")
                                                       destructiveButtonTitle:FELocalized(@"DELETE_TITLE")
                                                            otherButtonTitles:nil];
            deleteSheet.tag = 100;
            [deleteSheet showInView:self.view];
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

@end
