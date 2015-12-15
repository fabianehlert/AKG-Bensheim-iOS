//
//  HomeworkTableViewController.m
//  AKG
//
//  Created by Fabian Ehlert on 09.02.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "HomeworkTableViewController.h"

#import "AppDelegate.h"

#import "Homework.h"
#import "HomeworkTableViewCell.h"
#import "CreateHomeworkTableViewController.h"
#import "EditHomeworkTableViewController.h"

@interface HomeworkTableViewController () <NSFetchedResultsControllerDelegate, EditHomeworkTableViewControllerDelegate, HomeworkTableViewCellDelegate>

@property (assign, nonatomic) BOOL nullCountVisible;
@property (strong, nonatomic) UILabel *nullCountLabel;

@property (nonatomic, strong) AppDelegate *appDelegate;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

@end

@implementation HomeworkTableViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 50, 0, 0)];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView setSeparatorInset:UIEdgeInsetsMake(0, 50, 0, 0)];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"DE_ACTIVATE_PAN" object:nil];
    
    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [self setupMenu];
    
    NSError *error = nil;
    [_fetchedResultsController performFetch:&error];
    
    if (!error) {
        [self.tableView reloadData];
        [self checkForChangesAndUpdate];
    } else {
        NSLog(@"%s, line %lu * Error= %@",__PRETTY_FUNCTION__, (unsigned long)__LINE__, error);
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
        
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ACTIVATE_PAN" object:nil];
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
    self.title = FELocalized(@"HOMEWORK_KEY");
}

- (void)showMenu
{
    [self.sideMenuViewController presentLeftMenuViewController];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.fetchedResultsController.sections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> info = self.fetchedResultsController.sections[section];
    return [info numberOfObjects];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 56.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.0f;
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HomeworkTableViewCell *cell = (HomeworkTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"HCell"
                                                                                           forIndexPath:indexPath];

    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    HomeworkTableViewCell *homeworkCell = (HomeworkTableViewCell *)cell;
    homeworkCell.delegate = self;
    
    Homework *homework = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEEE, dd.MMM"];
    
    NSMutableAttributedString *taskString = [[NSMutableAttributedString alloc] initWithString:FESWF(@"%@: %@", homework.subject, homework.taskTitle)];
    
    UIFont *mediumFont = [UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0];
    if ([FEVersionChecker version] >= 9.0) {
        mediumFont = [UIFont systemFontOfSize:17.0 weight:UIFontWeightMedium];
    }

    UIFont *regularFont = [UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0];
    if ([FEVersionChecker version] >= 9.0) {
        mediumFont = [UIFont systemFontOfSize:17.0 weight:UIFontWeightRegular];
    }

    
    [taskString addAttributes:@{NSFontAttributeName: mediumFont,
                                NSForegroundColorAttributeName: [UIColor colorWithWhite:0.0 alpha:1.0]}
                        range:NSMakeRange(0, homework.subject.length + 1)];
    [taskString addAttributes:@{NSFontAttributeName: regularFont,
                                NSForegroundColorAttributeName: [UIColor colorWithWhite:0.33 alpha:1.0]}
                        range:NSMakeRange(homework.subject.length + 2, homework.taskTitle.length)];
    
    homeworkCell.taskIsDone = [homework.done unsignedIntegerValue];
    homeworkCell.taskLabel.attributedText = taskString;
    homeworkCell.dateLabel.text = FESWF(@"%@", [dateFormatter stringFromDate:homework.dueDate]);
    
    if ([self taskIsDue:homework.dueDate] && [homework.done unsignedIntegerValue] == 0) {
        homeworkCell.dateLabel.textColor = [UIColor redColor];
    } else {
        homeworkCell.dateLabel.textColor = [UIColor colorWithWhite:0.57 alpha:1.0];
    }
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Homework *homework = [self.fetchedResultsController objectAtIndexPath:indexPath];
        NSManagedObjectContext *context = [self.appDelegate managedObjectContext];
        [context deleteObject:homework];
        
        NSError *error = nil;
        
        if (![context save:&error]) {
            NSLog(@"%s, line %lu * Error= %@", __PRETTY_FUNCTION__, (unsigned long)__LINE__, error);
            abort();
        } else {
            [self checkForChangesAndUpdate];
        }
    }
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"EDIT_HOMEWORK"]) {
        EditHomeworkTableViewController *editController = [segue destinationViewController];
        editController.homework = [self.fetchedResultsController objectAtIndexPath:self.tableView.indexPathForSelectedRow];
        editController.delegate = self;
    }
}


#pragma mark - NullCountLabel & ObjectsCount

- (NSUInteger)unDoneHomeworkObjectsCount
{
    NSManagedObjectContext *context = [self.appDelegate managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Homework"];
    
    NSError *error = nil;
    NSArray *homeworkObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    if (!error) {
        __block NSUInteger unDoneCount = 0;
        [homeworkObjects enumerateObjectsUsingBlock:^(Homework *homework, NSUInteger idx, BOOL *stop) {
            if ([homework.done unsignedIntegerValue] == (long)0) {
                unDoneCount++;
            }
        }];
        return unDoneCount;
    } else {
        NSLog(@"%s, line %lu * Error= %@", __PRETTY_FUNCTION__, (unsigned long)__LINE__, error);
        return 0;
    }
}

- (void)checkForChangesAndUpdate
{
    NSUInteger unDoneCount = [self unDoneHomeworkObjectsCount];
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:unDoneCount];
    if ([self.fetchedResultsController.fetchedObjects count] == 0) {
        [self showNullCountLabel];
    } else {
        [self hideNullCountLabel];
    }
}

- (void)showNullCountLabel
{
    if (!self.nullCountVisible) {
        self.nullCountVisible = YES;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            self.nullCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.tableView.frame.size.height / 2, self.tableView.frame.size.width, 45)];
            
            
            self.nullCountLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
            
            self.nullCountLabel.center = CGPointMake(self.tableView.frame.size.width / 2, ([UIScreen mainScreen].bounds.size.height - 64) / 2);
        } else {
            self.nullCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.tableView.frame.size.height / 2, self.tableView.frame.size.width, 45)];
            self.nullCountLabel.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
            self.nullCountLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
        }
        
        self.nullCountLabel.backgroundColor = [UIColor clearColor];
        self.nullCountLabel.textColor = [UIColor colorWithWhite:0.59 alpha:1.0];
        self.nullCountLabel.highlightedTextColor = self.nullCountLabel.textColor;
        
        if ([FEVersionChecker version] >= 9.0) {
            self.nullCountLabel.font = [UIFont systemFontOfSize:28.0 weight:UIFontWeightLight];
        } else {
            self.nullCountLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:28.0];
        }
        
        self.nullCountLabel.textAlignment = NSTextAlignmentCenter;
        self.nullCountLabel.text = FELocalized(@"HOMEWORK_NOT_AVLBL_KEY");
        self.nullCountLabel.alpha = 0.0;
        
        [self.view addSubview:self.nullCountLabel];
        
        
        [UIView animateWithDuration:0.24
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
                             self.nullCountLabel.alpha = 1.0;
                         } completion:nil];
    }
}

- (void)hideNullCountLabel
{
    if (self.nullCountVisible) {
        [UIView animateWithDuration:0.16
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             self.nullCountLabel.alpha = 0.0;
                             self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
                         } completion:^(BOOL finished) {
                             [self.nullCountLabel removeFromSuperview];
                             self.nullCountVisible = NO;
                         }];
    }
}


#pragma mark - HomeworkTableViewCellDelegate

- (void)checkCircleTapped:(HomeworkTableViewCell *)cell currentDoneValue:(BOOL)done
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    BOOL taskIsDone = !done;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    Homework *homework = [self.fetchedResultsController objectAtIndexPath:indexPath];
    homework.done = [NSNumber numberWithUnsignedInteger:taskIsDone];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.appDelegate saveContext];
        [self.tableView reloadData];
    });
}


#pragma mark - EditHomeworkTableViewControllerDelegate

- (void)shouldUpdateContent
{
    [self.tableView reloadData];
    [self checkForChangesAndUpdate];
}

- (void)willDeleteHomework:(Homework *)homework
{
    NSManagedObjectContext *context = [self.appDelegate managedObjectContext];
    [context deleteObject:homework];
    
    NSError *error = nil;
    
    if (![context save:&error]) {
        NSLog(@"%s, line %lu * Error= %@", __PRETTY_FUNCTION__, (unsigned long)__LINE__, error);
        abort();
    } else {
        [self checkForChangesAndUpdate];
    }
}

#pragma mark - FetchedResultsController

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Homework"];
    [fetchRequest setFetchBatchSize:32];
    
    NSSortDescriptor *sortDone = [NSSortDescriptor sortDescriptorWithKey:@"done" ascending:YES];
    NSSortDescriptor *sortDate = [NSSortDescriptor sortDescriptorWithKey:@"dueDate" ascending:YES];
    NSSortDescriptor *sortSubject = [NSSortDescriptor sortDescriptorWithKey:@"subject" ascending:YES];
    NSSortDescriptor *sortTask = [NSSortDescriptor sortDescriptorWithKey:@"taskTitle" ascending:YES];
    
    fetchRequest.sortDescriptors = @[sortDone, sortDate, sortSubject, sortTask];
    
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                    managedObjectContext:self.appDelegate.managedObjectContext
                                                                      sectionNameKeyPath:nil
                                                                               cacheName:@"Master"];
    _fetchedResultsController.delegate = self;
    
    NSError *error = nil;
    [_fetchedResultsController performFetch:&error];
    
    if (error) {
        NSLog(@"%s, line %lu * Error= %@",__PRETTY_FUNCTION__, (unsigned long)__LINE__, error);
    }
    
    return _fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeMove:
            break;
        case NSFetchedResultsChangeUpdate:
            break;
        default:
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch (type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath]
                    atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
    [self checkForChangesAndUpdate];
}


#pragma mark - Helper

- (BOOL)taskIsDue:(NSDate *)d {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy/MM/dd/HH"];
    NSString *today = [formatter stringFromDate:[NSDate date]];
    
    NSString *yearNow = [today stringByReplacingCharactersInRange:NSMakeRange(4, 9) withString:@""];
    NSString *monthNow = [[today stringByReplacingCharactersInRange:NSMakeRange(0, 5) withString:@""] stringByReplacingCharactersInRange:NSMakeRange(2, 6) withString:@""];
    NSString *dayNow = [[today stringByReplacingCharactersInRange:NSMakeRange(0, 8) withString:@""] stringByReplacingCharactersInRange:NSMakeRange(2, 3) withString:@""];
    
    NSString *date = [formatter stringFromDate:d];
    
    NSString *year = [date stringByReplacingCharactersInRange:NSMakeRange(4, 9) withString:@""];
    NSString *month = [[date stringByReplacingCharactersInRange:NSMakeRange(0, 5) withString:@""] stringByReplacingCharactersInRange:NSMakeRange(2, 6) withString:@""];
    NSString *day = [[date stringByReplacingCharactersInRange:NSMakeRange(0, 8) withString:@""] stringByReplacingCharactersInRange:NSMakeRange(2, 3) withString:@""];
    
    
    if (year.integerValue < yearNow.integerValue) {
        return YES;
    } else if (year.integerValue == yearNow.integerValue) {
        if (month.integerValue < monthNow.integerValue) {
            return YES;
        } else if (month.integerValue == monthNow.integerValue) {
            if (day.integerValue <= dayNow.integerValue) {
                return YES;
            }
        }
    }
    
    return NO;
}

@end
