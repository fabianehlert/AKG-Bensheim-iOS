//
//  CreateHomeworkTableViewController.m
//  AKG
//
//  Created by Fabian Ehlert on 08.03.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "CreateHomeworkTableViewController.h"
#import "AppDelegate.h"

@interface CreateHomeworkTableViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *subjectTextField;
@property (weak, nonatomic) IBOutlet UITextField *taskTitleTextField;
@property (weak, nonatomic) IBOutlet UITextView *taskNotesTextView;
@property (weak, nonatomic) IBOutlet UIDatePicker *dueDatePicker;
@property (weak, nonatomic) IBOutlet UILabel *taskNotesDescriptionLabel;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addButton;

@property (strong, nonatomic) AppDelegate *appDelegate;

@end

@implementation CreateHomeworkTableViewController

- (void)dealloc
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    self.title = FELocalized(@"NEW_TASK");
    [self.cancelButton setTitle:FELocalized(@"CANCEL_TITLE_KEY")];
    [self.addButton setTitle:FELocalized(@"ADD_KEY")];

    [self.subjectTextField setPlaceholder:FELocalized(@"SUBJECT_TITLE")];
    [self.taskTitleTextField setPlaceholder:FELocalized(@"TASK_TITLE")];
    [self.taskNotesDescriptionLabel setText:FELocalized(@"TASK_NOTES")];
  
    self.subjectTextField.delegate = self;
    self.taskTitleTextField.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self.subjectTextField becomeFirstResponder];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - IBActions

- (IBAction)cancelAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (IBAction)saveAction:(id)sender
{
    Homework *homework = [NSEntityDescription insertNewObjectForEntityForName:@"Homework"
                                                       inManagedObjectContext:self.appDelegate.managedObjectContext];
    
    homework.subject = self.subjectTextField.text;
    homework.taskTitle = self.taskTitleTextField.text;
    homework.taskNote = self.taskNotesTextView.text;
    homework.done = [NSNumber numberWithUnsignedInteger:(long)0];
    homework.dueDate = self.dueDatePicker.date;
    
    [self.appDelegate saveContext];
    
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 3 && indexPath.row == 0) {
        [self.taskNotesTextView becomeFirstResponder];
    }
}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

@end
