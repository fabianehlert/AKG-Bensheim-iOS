//
//  CoursesAddEditTableViewController.m
//  AKG
//
//  Created by Fabian Ehlert on 12.02.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "CoursesAddEditTableViewController.h"

@interface CoursesAddEditTableViewController () <UIPickerViewDataSource, UIPickerViewDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *finishButtonOutlet;

@property (weak, nonatomic) IBOutlet UIPickerView *subjectPickerView;
@property (weak, nonatomic) IBOutlet UIPickerView *courseNumberPickerView;

@property (strong, nonatomic) NSArray *subjectArray;
@property (strong, nonatomic) NSArray *coursesNumberArray;

@property (assign, nonatomic) BOOL subjectPickerVisible;
@property (assign, nonatomic) BOOL coursesNumberPickerVisible;

@property (strong, nonatomic) Course *course;

@property (weak, nonatomic) IBOutlet UILabel *subjectLabel;
@property (weak, nonatomic) IBOutlet UILabel *courseLabel;

@property (weak, nonatomic) IBOutlet UISwitch *isLKSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *isTutorSwitch;

@property (weak, nonatomic) IBOutlet UILabel *subjectDescriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *courseNumberDescriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *lkDescriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *tutorDescriptionLabel;

@end

@implementation CoursesAddEditTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setLabels];
    [self setup];

    if (self.courseToEdit) {
        self.title = FELocalized(@"EDIT_COURSE");
        self.finishButtonOutlet.title = FELocalized(@"SAVE_KEY");
        self.course = self.courseToEdit;
        self.subjectLabel.text = self.course.subject;
        self.courseLabel.text = self.course.courseNumberString;
        self.isLKSwitch.on = self.course.isLK;
        self.isTutorSwitch.on = self.course.isTutor;
        
        NSInteger sbjIdx = [self.subjectArray indexOfObject:self.course.subject];
        NSInteger crsIdx = [self.coursesNumberArray indexOfObject:self.course.courseNumberString];
        
        [self.subjectPickerView selectRow:sbjIdx inComponent:0 animated:NO];
        [self.courseNumberPickerView selectRow:crsIdx inComponent:0 animated:NO];
    } else {
        self.title = FELocalized(@"NEW_COURSE");
        self.finishButtonOutlet.title = FELocalized(@"ADD_KEY");
        self.isLKSwitch.on = NO;
        self.isTutorSwitch.on = NO;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)setLabels
{
    self.subjectDescriptionLabel.text = FELocalized(@"SUBJECT_KEY");
    self.courseNumberDescriptionLabel.text = FELocalized(@"COURSE_NR_KEY");
    self.lkDescriptionLabel.text = FELocalized(@"LEISTUNGSKURS");
    self.tutorDescriptionLabel.text = FELocalized(@"TUTORKURS");
}

#pragma mark - IBActions

- (IBAction)saveAction:(id)sender
{
    if (!self.courseToEdit) {
        ///////******* Add Course
        self.course = [[Course alloc] init];
        self.course.subject = self.subjectLabel.text;
        self.course.courseNumberString = self.courseLabel.text;
        self.course.isLK = self.isLKSwitch.on;
        self.course.isTutor = self.isTutorSwitch.on;
        
        NSUserDefaults *groupDefaults = [NSUserDefaults standardUserDefaults];
        if (![self courseExists:self.course]) {
            NSData *savedData = [groupDefaults objectForKey:[NSString stringWithFormat:@"COURSES_ARRAY"]];
            NSMutableArray *mutableCoursesArray = [[NSMutableArray alloc] init];
            if (savedData) {
                NSArray *coursesArray = [NSKeyedUnarchiver unarchiveObjectWithData:savedData];
                mutableCoursesArray = [coursesArray mutableCopy];
                
                [mutableCoursesArray addObject:self.course];
            } else {
                mutableCoursesArray = [[NSMutableArray alloc] initWithObjects:self.course, nil];
            }
            
            [groupDefaults setObject:[NSKeyedArchiver archivedDataWithRootObject:[NSArray arrayWithArray:mutableCoursesArray]] forKey:[NSString stringWithFormat:@"COURSES_ARRAY"]];
            [groupDefaults synchronize];
            
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"UPDATE_COURSES_LIST" object:nil];
            }
            
            [self dismissViewControllerAnimated:YES completion:nil];
        } else {
            if ([FEVersionChecker version] >= 8.0) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:FELocalized(@"COURSE_EXISTS_TITLE")
                                                                               message:FELocalized(@"COURSE_EXISTS_MESSAGE")
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction *action) {
                    [alert dismissViewControllerAnimated:YES completion:nil];
                }]];
                
                [self presentViewController:alert animated:YES completion:nil];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:FELocalized(@"COURSE_EXISTS_TITLE")
                                                                message:FELocalized(@"COURSE_EXISTS_MESSAGE")
                                                               delegate:self
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"OK", nil];
                [alert show];
            }
        }
    } else {
        ///////******* Update Course
        self.course.subject = self.subjectLabel.text;
        self.course.courseNumberString = self.courseLabel.text;
        self.course.isLK = self.isLKSwitch.on;
        self.course.isTutor = self.isTutorSwitch.on;
        
        NSUserDefaults *groupDefaults = [NSUserDefaults standardUserDefaults];
        if (![self courseExists:self.course]) {
            NSData *savedData = [groupDefaults objectForKey:[NSString stringWithFormat:@"COURSES_ARRAY"]];
            NSMutableArray *mutableCoursesArray = [[NSMutableArray alloc] init];
            if (savedData) {
                NSArray *coursesArray = [NSKeyedUnarchiver unarchiveObjectWithData:savedData];
                mutableCoursesArray = [coursesArray mutableCopy];
                
                [mutableCoursesArray replaceObjectAtIndex:self.editIdx withObject:self.course];
            }
            
            [groupDefaults setObject:[NSKeyedArchiver archivedDataWithRootObject:[NSArray arrayWithArray:mutableCoursesArray]] forKey:[NSString stringWithFormat:@"COURSES_ARRAY"]];
            [groupDefaults synchronize];
            
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"UPDATE_COURSES_LIST" object:nil];
            }
            
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            if ([FEVersionChecker version] >= 8.0) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:FELocalized(@"COURSE_EXISTS_TITLE")
                                                                               message:FELocalized(@"COURSE_EXISTS_MESSAGE")
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction *action) {
                    [alert dismissViewControllerAnimated:YES completion:nil];
                }]];
                
                [self presentViewController:alert animated:YES completion:nil];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:FELocalized(@"COURSE_EXISTS_TITLE")
                                                                message:FELocalized(@"COURSE_EXISTS_MESSAGE")
                                                               delegate:self
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:@"OK", nil];
                [alert show];
            }
        }
    }
}

- (BOOL)courseExists:(Course *)crs
{
    NSUserDefaults *groupDefaults = [NSUserDefaults standardUserDefaults];
    NSData *savedData = [groupDefaults objectForKey:[NSString stringWithFormat:@"COURSES_ARRAY"]];
    NSArray *coursesArray = @[];
    if (savedData) {
        coursesArray = [NSKeyedUnarchiver unarchiveObjectWithData:savedData];
    }
    
    for (Course *course in coursesArray) {
        if ([[crs courseString] isEqualToString:[course courseString]]) {
            return YES;
        }
    }
    
    return NO;
}

- (IBAction)dismissAction:(id)sender
{
    if (!self.courseToEdit) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}


#pragma mark - Private

- (void)setup
{
    self.subjectPickerVisible = NO;
    self.coursesNumberPickerVisible = NO;
    
    self.coursesNumberArray = @[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10", @"11", @"12", @"13", @"14", @"15", @"16", @"17", @"18", @"19", @"20"];
    self.subjectArray = @[@"Biologie", @"Chemie", @"Deutsch", @"Englisch", @"Französisch", @"Geschichte", @"Griechisch", @"Latein", @"Mathematik", @"Musik", @"Physik", @"PoWi", @"Sport", @"Erdkunde", @"Ethik", @"Informatik", @"Italienisch", @"Kunst", @"Philosophie", @"Religion (evangelisch)", @"Religion (katholisch)", @"Spanisch"];
    self.subjectArray = [self.subjectArray sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}


#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (pickerView == self.subjectPickerView) {
        return [self.subjectArray count];
    } else if (pickerView == self.courseNumberPickerView) {
        return [self.coursesNumberArray count];
    }
    
    return 0;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (pickerView == self.subjectPickerView) {
        return self.subjectArray[row];
    } else if (pickerView == self.courseNumberPickerView) {
        return self.coursesNumberArray[row];
    }
    
    return @"";
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return 40.0;
}

#pragma mark - UIPickerViewDelegate

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (pickerView == self.subjectPickerView) {
        self.subjectLabel.text = self.subjectArray[row];
    }
    
    if (pickerView == self.courseNumberPickerView) {
        self.courseLabel.text = self.coursesNumberArray[row];
    }
}

#pragma mark - UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = [super tableView:tableView heightForRowAtIndexPath:indexPath];
    
    if (indexPath.section == 0 && indexPath.row == 1) {
        if (self.subjectPickerVisible) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.15 animations:^{
                    self.subjectPickerView.alpha = 1.0;
                    self.subjectPickerView.userInteractionEnabled = YES;
                    self.subjectPickerView.hidden = NO;
                }];
            });
            return height;
        } else {
            [UIView animateWithDuration:0.15 animations:^{
                self.subjectPickerView.alpha = 0.0;
                self.subjectPickerView.userInteractionEnabled = NO;
            } completion:^(BOOL finished) {
                self.subjectPickerView.hidden = YES;
            }];
            return 0;
        }
    }
    
    if (indexPath.section == 0 && indexPath.row == 3) {
        if (self.coursesNumberPickerVisible) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.15 animations:^{
                    self.courseNumberPickerView.alpha = 1.0;
                    self.courseNumberPickerView.userInteractionEnabled = YES;
                    self.courseNumberPickerView.hidden = NO;
                }];
            });
            return height;
        } else {
            [UIView animateWithDuration:0.15 animations:^{
                self.courseNumberPickerView.alpha = 0.0;
                self.courseNumberPickerView.userInteractionEnabled = NO;
            } completion:^(BOOL finished) {
                self.courseNumberPickerView.hidden = YES;
            }];
            return 0;
        }
    }
    
    return height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    return cell;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row == 0) {
        self.subjectPickerVisible = !self.subjectPickerVisible;
    } else if (indexPath.section == 0 && indexPath.row == 2) {
        self.coursesNumberPickerVisible = !self.coursesNumberPickerVisible;
    }
    
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
