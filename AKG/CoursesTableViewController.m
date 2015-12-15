//
//  CoursesTableViewController.m
//  AKG
//
//  Created by Fabian Ehlert on 08.02.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "CoursesTableViewController.h"
#import "CoursesAddEditTableViewController.h"
#import "Course.h"

@interface CoursesTableViewController ()

@property (strong, nonatomic) Course *course;
@property (assign, nonatomic) NSInteger editIndex;

@property (strong, nonatomic) UILabel *nullCountLabel;
@property (assign, nonatomic) BOOL nullCountVisible;

@end

@implementation CoursesTableViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateWithReloadType:0];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
 
    self.editIndex = -1;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateContent) name:@"UPDATE_COURSES_LIST" object:nil];
    }
    
    [self setup];
    [self updateWithReloadType:0];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Private

- (void)setup
{
    self.title = FELocalized(@"COURSES_KEY");
}

- (void)updateWithReloadType:(NSInteger)type
{
    if (type == 0) {
        [self.tableView reloadData];
    } else if (type == 1) {
       // [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    }
    NSUserDefaults *groupDefaults = [NSUserDefaults standardUserDefaults];
    NSData *savedData = [groupDefaults objectForKey:[NSString stringWithFormat:@"COURSES_ARRAY"]];
    NSArray *coursesArray = @[];
    if (savedData) {
        coursesArray = [NSKeyedUnarchiver unarchiveObjectWithData:savedData];
    }
    
    if ([coursesArray count] == 0) {
        [self showNullCountLabel];
    } else {
        [self hideNullCountLabel];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UPDATE_COURSES_COUNT" object:nil];
}

- (void)updateContent
{
    [self updateWithReloadType:0];
}

- (IBAction)closeAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSUserDefaults *groupDefaults = [NSUserDefaults standardUserDefaults];
    NSData *savedData = [groupDefaults objectForKey:[NSString stringWithFormat:@"COURSES_ARRAY"]];
    if (savedData) {
        NSArray *coursesArray = [NSKeyedUnarchiver unarchiveObjectWithData:savedData];
        if (coursesArray) {
            return [coursesArray count];
        }
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    NSUserDefaults *groupDefaults = [NSUserDefaults standardUserDefaults];
    NSData *savedData = [groupDefaults objectForKey:[NSString stringWithFormat:@"COURSES_ARRAY"]];
    if (savedData) {
        NSArray *coursesArray = [NSKeyedUnarchiver unarchiveObjectWithData:savedData];
        if (coursesArray) {
            Course *course = coursesArray[indexPath.row];
            cell.textLabel.text = [NSString stringWithFormat:@"%@", [course courseString]];
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUserDefaults *groupDefaults = [NSUserDefaults standardUserDefaults];
    NSData *savedData = [groupDefaults objectForKey:[NSString stringWithFormat:@"COURSES_ARRAY"]];
    if (savedData) {
        NSArray *coursesArray = [NSKeyedUnarchiver unarchiveObjectWithData:savedData];
        self.course = coursesArray[indexPath.row];
        self.editIndex = indexPath.row;
    } else {
        self.course = nil;
    }
    
    [self performSegueWithIdentifier:@"EDIT_COURSE" sender:self];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUserDefaults *groupDefaults = [NSUserDefaults standardUserDefaults];
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSData *savedData = [groupDefaults objectForKey:[NSString stringWithFormat:@"COURSES_ARRAY"]];
        NSMutableArray *mutableCoursesArray = [[NSMutableArray alloc] init];
        if (savedData) {
            NSArray *coursesArray = [NSKeyedUnarchiver unarchiveObjectWithData:savedData];
            mutableCoursesArray = [coursesArray mutableCopy];
        }

        if ([mutableCoursesArray count] > 0) {
            [mutableCoursesArray removeObjectAtIndex:indexPath.row];
            NSUserDefaults *groupDefaults = [NSUserDefaults standardUserDefaults];
            [groupDefaults setObject:[NSKeyedArchiver archivedDataWithRootObject:[NSArray arrayWithArray:mutableCoursesArray]] forKey:[NSString stringWithFormat:@"COURSES_ARRAY"]];
            [groupDefaults synchronize];
        }
        
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self updateWithReloadType:1];
    }
}


#pragma mark - NullCountLabel
- (void)showNullCountLabel
{
    if (!self.nullCountVisible) {
        self.nullCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 45)];
        self.nullCountLabel.center = CGPointMake(self.view.frame.size.width / 2, (self.view.frame.size.height - 64) / 2);
        self.nullCountLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
        
        self.nullCountLabel.backgroundColor = [UIColor clearColor];
        self.nullCountLabel.textColor = [UIColor colorWithWhite:0.59 alpha:1.0];
        self.nullCountLabel.highlightedTextColor = self.nullCountLabel.textColor;
        
        if ([FEVersionChecker version] >= 9.0) {
            self.nullCountLabel.font = [UIFont systemFontOfSize:28.0 weight:UIFontWeightLight];
        } else {
            self.nullCountLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:28.0];
        }

        self.nullCountLabel.textAlignment = NSTextAlignmentCenter;
        self.nullCountLabel.text = FELocalized(@"COURSES_NOT_AVLBL_KEY");
        self.nullCountLabel.alpha = 0.0;
        
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        [self.view addSubview:self.nullCountLabel];
        self.nullCountVisible = YES;
        
        [UIView animateWithDuration:0.24 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.nullCountLabel.alpha = 1.0;
        } completion:^(BOOL finished) {
            
        }];
    }
}

- (void)hideNullCountLabel
{
    if (self.nullCountVisible) {
        [UIView animateWithDuration:0.16 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.nullCountLabel.alpha = 0.0;
            self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        } completion:^(BOOL finished) {
            [self.nullCountLabel removeFromSuperview];
            self.nullCountVisible = NO;
        }];
    }
}


#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"EDIT_COURSE"]) {
        CoursesAddEditTableViewController *destinationController = [segue destinationViewController];
        destinationController.courseToEdit = self.course;
        destinationController.editIdx = self.editIndex;
    }
}

@end
