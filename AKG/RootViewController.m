//
//  RootViewController.m
//  AKG
//
//  Created by Fabian Ehlert on 23.01.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "RootViewController.h"
#import "MenuViewController.h"

#import "MensaViewController.h"
#import "WebsiteViewController.h"

#import "UIImage+ImageEffects.h"

#import "Course.h"
#import "Teacher.h"

static NSString *contentControllerID = @"CONTENT";
static NSString *menuControllerID = @"MENU";

static NSString *defaultMenuBackgroundImageName = @"MenuBackground";
static NSString *defaultBlurredMenuBackgroundImageName = @"BlurredMenuBackground";

@interface RootViewController () <UIAlertViewDelegate>

@end

@implementation RootViewController

#pragma mark -
- (void)awakeFromNib
{
    [super awakeFromNib];

    [SVProgressHUD setBackgroundColor:[UIColor colorWithWhite:0.95 alpha:0.95]];
    [SVProgressHUD setForegroundColor:[UIColor colorWithWhite:0.0 alpha:1.0]];
    [SVProgressHUD setRingThickness:2.0];
    
    NSUserDefaults *groupDefaults = [NSUserDefaults standardUserDefaults];
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"V4_FIRST_START"]) {
        
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
        
        [self removeOldDataBases];
        
        [self transferOldData];
        // [self readTeachersOnce];
        
        NSArray *typeArray = @[@{@"name": @"Vertretung", @"color": @"0"},
                               @{@"name": @"Fällt aus", @"color": @"1"},
                               @{@"name": @"Raumvertretung", @"color": @"2"},
                               @{@"name": @"Veranstaltung", @"color": @"3"},
                               @{@"name": @"Sondereinstellung", @"color": @"4"},
                               @{@"name": @"Unterricht geändert", @"color": @"5"},
                               @{@"name": @"Freisetzung", @"color": @"6"},
                               @{@"name": @"Betreuung", @"color": @"7"},
                               @{@"name": @"Tausch", @"color": @"8"},
                               @{@"name": @"Andere", @"color": @"9"}];
        
        [groupDefaults setObject:typeArray forKey:@"vtypearray"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"SHOULD_APPLY_COLOR_SUPPLY_PLAN"];
        [[NSUserDefaults standardUserDefaults] setObject:@0 forKey:@"BACKGROUND_IMAGE_TYPE"];
        [groupDefaults setObject:@"Alle" forKey:@"klassefilterstring"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"SHOULD_APPLY_COLOR_SUPPLY_PLAN"];
        [groupDefaults setBool:NO forKey:@"SHOULD_FILTER_COURSES"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"APPLIES_BLUR_ON_BACKGROUND"];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"V4_FIRST_START"];

        [groupDefaults synchronize];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"V4_1_IOS8_FIRST_START"]) {
        [self removeOldUserDefaults];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"V4_1_IOS8_FIRST_START"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"V4_2_IOS9_FIRST_START"]) {
        
        NSArray *typeArray = @[@{@"name": @"Vertretung", @"color": @"0"},
                               @{@"name": @"Fällt aus", @"color": @"1"},
                               @{@"name": @"Raumvertretung", @"color": @"2"},
                               @{@"name": @"Veranstaltung", @"color": @"3"},
                               @{@"name": @"Sondereinstellung", @"color": @"4"},
                               @{@"name": @"Unterricht geändert", @"color": @"5"},
                               @{@"name": @"Freisetzung", @"color": @"6"},
                               @{@"name": @"Betreuung", @"color": @"7"},
                               @{@"name": @"Tausch", @"color": @"8"},
                               @{@"name": @"Andere", @"color": @"9"}];
        
        [[NSUserDefaults standardUserDefaults] setObject:typeArray forKey:@"vtypearray"];

        [[NSUserDefaults standardUserDefaults] setObject:@"Alle" forKey:@"klassefilterstring"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"COURSES_ARRAY"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SUPPLY_DATA"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"vtypearray"];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"SHOULD_FILTER_COURSES"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"SHOULD_APPLY_COLOR_SUPPLY_PLAN"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"V4_2_IOS9_FIRST_START"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    // SideMenu init
    self.contentViewController = [self.storyboard instantiateViewControllerWithIdentifier:contentControllerID];
    self.leftMenuViewController = [self.storyboard instantiateViewControllerWithIdentifier:menuControllerID];
    
    self.contentViewShadowEnabled = YES;
    self.contentViewShadowColor = [UIColor blackColor];
    self.contentViewShadowOffset = CGSizeMake(0.0, 0.0);
    self.contentViewShadowOpacity = 0.23;
    self.contentViewShadowRadius = 3.0;
    
    ///
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"APPLIES_BLUR_ON_BACKGROUND"]) {
        NSNumber *bgImageType = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"BACKGROUND_IMAGE_TYPE"];
        switch (bgImageType.integerValue) {
            case 0:
            {
                // Default
                self.backgroundImage = [UIImage imageNamed:defaultBlurredMenuBackgroundImageName];
            }
                break;
            case 1:
            {
                // Documents folder
                self.backgroundImage = [self savedBlurredBackgroundImage];
            }
                break;
            default:
                break;
        }
    } else {
        NSNumber *bgImageType = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"BACKGROUND_IMAGE_TYPE"];
        switch (bgImageType.integerValue) {
            case 0:
                // Default
                self.backgroundImage = [UIImage imageNamed:defaultMenuBackgroundImageName];
                break;
            case 1:
            {
                // Documents folder
                UIImage *bgImage = [self savedBackgroundImage];
                self.backgroundImage = bgImage;
            }
                break;
            default:
                break;
        }
    }
    
    self.delegate = (MenuViewController *)self.leftMenuViewController;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(changeBackgroundImage)
                                                 name:@"BG_IMAGE_CHANGED"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(activatePanGesture)
                                                 name:@"ACTIVATE_PAN"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deactivatePanGesture)
                                                 name:@"DE_ACTIVATE_PAN"
                                               object:nil];
    
    // Detect first launch
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"APP_LAUNCH_DIALOG"]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"APP_LAUNCH_DIALOG"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"COURSES_DIALOG"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else if (![[NSUserDefaults standardUserDefaults] boolForKey:@"COURSES_DIALOG"]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"COURSES_DIALOG"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}


#pragma mark - Initial setup process

- (void)setupWatch {
    NSUserDefaults *groupDefaults = [NSUserDefaults standardUserDefaults];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"SUPPLY_DATA"]) {
        [groupDefaults setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"SUPPLY_DATA"] forKey:@"SUPPLY_DATA"];
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"klassefilterstring"]) {
        [groupDefaults setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"klassefilterstring"] forKey:@"klassefilterstring"];
    } else {
        [groupDefaults setObject:@"Alle" forKey:@"klassefilterstring"];
    }
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SHOULD_FILTER_COURSES"]) {
        [groupDefaults setBool:[[NSUserDefaults standardUserDefaults] boolForKey:@"SHOULD_FILTER_COURSES"] forKey:@"SHOULD_FILTER_COURSES"];
    } else {
        [groupDefaults setBool:NO forKey:@"SHOULD_FILTER_COURSES"];
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"COURSES_ARRAY"]) {
        [groupDefaults setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"COURSES_ARRAY"] forKey:@"COURSES_ARRAY"];
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"vtypearray"]) {
        [groupDefaults setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"vtypearray"] forKey:@"vtypearray"];
    }
    
    [groupDefaults synchronize];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SUPPLY_DATA"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"klassefilterstring"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SHOULD_FILTER_COURSES"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"COURSES_ARRAY"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"vtypearray"];

    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)removeOldUserDefaults {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[NSString stringWithFormat:@"TERMINE_KEY"]];
}

- (void)removeOldDataBases
{
    NSURL *documentsURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    
    NSURL *dbV2URL = [documentsURL URLByAppendingPathComponent:@"AKG.sqlite"];
    NSError *errorV2 = nil;
    [[NSFileManager defaultManager] removeItemAtURL:dbV2URL error:&errorV2];
    
    if (errorV2) {
        NSLog(@"ErrorV2= %@", errorV2);
    }
    
    NSURL *dbV3URL = [documentsURL URLByAppendingPathComponent:@"AKGModel.sqlite"];
    NSError *errorV3 = nil;
    [[NSFileManager defaultManager] removeItemAtURL:dbV3URL error:&errorV3];
    
    if (errorV3) {
        NSLog(@"ErrorV3= %@", errorV3);
    }
}

- (void)transferOldData
{
    NSArray *kurse = [[NSUserDefaults standardUserDefaults] objectForKey:@"kurse"];
    NSMutableArray *transferredCourses = [[NSMutableArray alloc] init];
    for (NSString *krs in kurse) {
        Course *crs = [Course courseOfCourseString:krs];
        [transferredCourses addObject:crs];
    }
    
    NSUserDefaults *groupDefaults = [NSUserDefaults standardUserDefaults];
    [groupDefaults setObject:[NSKeyedArchiver archivedDataWithRootObject:[NSArray arrayWithArray:transferredCourses]] forKey:[NSString stringWithFormat:@"COURSES_ARRAY"]];
    [groupDefaults synchronize];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"kurse"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)readTeachersOnce
{
    NSMutableArray *mutableTeachers = [[NSMutableArray alloc] init];
    NSString *teachersJSONPath = [[NSBundle mainBundle] pathForResource:@"teachers" ofType:@"json"];
    NSData *allTeachersData = [[NSData alloc] initWithContentsOfFile:teachersJSONPath];
    
    NSError *error;
    NSMutableDictionary *allTeachers = [NSJSONSerialization
                                        JSONObjectWithData:allTeachersData
                                        options:NSJSONReadingMutableContainers // kNilOptions
                                        error:&error];
    
    if (error) {
        NSLog(@"%s, ERROR= %@", __PRETTY_FUNCTION__, [error localizedDescription]);
    } else {
        NSArray *teachersArray = allTeachers[@"teachers"];
        for (NSDictionary *tc in teachersArray)
        {
            Teacher *teacher = [[Teacher alloc] initWithFirstName:tc[@"firstname"]
                                                         lastName:tc[@"lastname"]
                                                        shortName:tc[@"shortname"]
                                                         subjects:tc[@"subjects"]
                                                             mail:tc[@"email"]];
            [mutableTeachers addObject:teacher];
        }
        
        [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:[NSArray arrayWithArray:mutableTeachers]] forKey:[NSString stringWithFormat:@"TEACHERS_ARRAY"]];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

#pragma mark -

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    UINavigationController *navigationController = (UINavigationController *)self.contentViewController;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        if (!self.visible) {
            if ([[navigationController.viewControllers lastObject] isKindOfClass:[MensaViewController class]] || [[navigationController.viewControllers lastObject] isKindOfClass:[WebsiteViewController class]]) {
                return UIInterfaceOrientationMaskAllButUpsideDown;
            }
        }
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
    }
    
    return UIInterfaceOrientationMaskAll;
}


#pragma mark - Pan Gesture

- (void)activatePanGesture {
    self.panFromEdge = NO;
}

- (void)deactivatePanGesture {
    self.panFromEdge = YES;
}


#pragma mark - BackgroundImage

- (void)changeBackgroundImage
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"APPLIES_BLUR_ON_BACKGROUND"]) {
        NSNumber *bgImageType = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"BACKGROUND_IMAGE_TYPE"];
        switch (bgImageType.integerValue) {
            case 0:
                // Default
                self.backgroundImage = [UIImage imageNamed:defaultBlurredMenuBackgroundImageName];
                break;
            case 1:
            {
                // Documents folder
                self.backgroundImage = [self savedBlurredBackgroundImage];
            }
                break;
            default:
                break;
        }
    } else {
        NSNumber *bgImageType = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"BACKGROUND_IMAGE_TYPE"];
        switch (bgImageType.integerValue) {
            case 0:
                // Default
                self.backgroundImage = [UIImage imageNamed:defaultMenuBackgroundImageName];
                break;
            case 1:
            {
                // Documents folder
                UIImage *bgImage = [self savedBackgroundImage];
                self.backgroundImage = bgImage;
            }
                break;
            default:
                break;
        }
    }
}

- (UIImage *)savedBlurredBackgroundImage {
    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingString:@"/Documents"];
    NSString *fullPath = [documentsDirectory stringByAppendingString:@"/BlurredBackgroundImage.JPG"];
    
    NSError *error = nil;
    
    NSData *imgData = [[NSData alloc] initWithContentsOfFile:fullPath];
    
    if (error) {
        NSLog(@"ERROR(line %ld)= %@", (long)__LINE__, error);
        return nil;
    }
    
    return [UIImage imageWithData:imgData];
}

- (UIImage *)savedBackgroundImage {
    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingString:@"/Documents"];
    NSString *fullPath = [documentsDirectory stringByAppendingString:@"/BackgroundImage.JPG"];
    
    NSError *error = nil;
    
    NSData *imgData = [[NSData alloc] initWithContentsOfFile:fullPath];
    
    if (error) {
        NSLog(@"ERROR(line %ld)= %@", (long)__LINE__, error);
        return nil;
    }
    
    return [UIImage imageWithData:imgData];
}

@end
