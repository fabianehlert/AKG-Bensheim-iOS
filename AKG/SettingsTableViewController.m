//
//  SettingsTableViewController.m
//  AKG
//
//  Created by Fabian Ehlert on 29.01.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "UIImage+OrientationFix.h"
#import "UIImage+ImageEffects.h"

static NSString *defaultMenuBackgroundImageName = @"MenuBackground";

@interface SettingsTableViewController () <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *classLabel;
@property (weak, nonatomic) IBOutlet UIPickerView *classPickerView;

@property (assign, nonatomic) BOOL classPickerVisible;

@property (weak, nonatomic) IBOutlet UILabel *coursesLabel;
@property (weak, nonatomic) IBOutlet UISwitch *filterCoursesSwitch;

@property (weak, nonatomic) IBOutlet UISwitch *applyColorsSwitch;

@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UISwitch *applyBlurSwitch;

@property (weak, nonatomic) IBOutlet UILabel *classTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *filterCoursesLabel;
@property (weak, nonatomic) IBOutlet UILabel *coursesTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *showColorsLabel;
@property (weak, nonatomic) IBOutlet UILabel *colorsTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *blurLabel;

@property (strong, nonatomic) UIActionSheet *imageOptionsSheet;

@property (strong, nonatomic) UIImagePickerController *imagePickerController;

@property (strong, nonatomic) NSArray *stufenArray;
@property (strong, nonatomic) NSArray *klassenArray;

@end

@implementation SettingsTableViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateCountLabel];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setLabels];
    [self setupMenu];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCountLabel) name:@"UPDATE_COURSES_COUNT" object:nil];
    }
    
    // Klasse
    self.stufenArray = @[@"Alle", @"5", @"6", @"7", @"8", @"9", @"10", @"11", @"12", @"13", @"K_Abi"];
    self.klassenArray = @[@"", @"a", @"b", @"c", @"d", @"e", @"f", @"g", @"h", @"s"];
    
    self.classPickerVisible = NO;
    
    self.classPickerView.dataSource = self;
    self.classPickerView.delegate = self;
    self.classPickerView.showsSelectionIndicator = YES;

    [self.classPickerView selectRow:[self indexForFirstComponent] inComponent:0 animated:NO];
    [self.classPickerView selectRow:[self indexForSecondComponent] inComponent:1 animated:NO];

    // Hintergrundbild
    NSNumber *bgImageType = (NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"BACKGROUND_IMAGE_TYPE"];
    switch (bgImageType.integerValue) {
        case 0:
            // Default
            self.backgroundImageView.image = [UIImage imageNamed:defaultMenuBackgroundImageName];
            break;
        case 1:
            // Documents folder
            self.backgroundImageView.image = [self savedBackgroundImage];
            break;
        default:
            break;
    }
    
    NSUserDefaults *groupDefaults = [NSUserDefaults standardUserDefaults];
    // Switches
    self.filterCoursesSwitch.on = [groupDefaults boolForKey:@"SHOULD_FILTER_COURSES"];
    self.applyColorsSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"SHOULD_APPLY_COLOR_SUPPLY_PLAN"];
    self.applyBlurSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"APPLIES_BLUR_ON_BACKGROUND"];
}

- (void)updateCountLabel
{
    NSUserDefaults *groupDefaults = [NSUserDefaults standardUserDefaults];
    NSData *savedData = [groupDefaults objectForKey:[NSString stringWithFormat:@"COURSES_ARRAY"]];
    NSArray *coursesArray = @[];
    
    if (savedData) {
        coursesArray = [NSKeyedUnarchiver unarchiveObjectWithData:savedData];
    }
    
    if (coursesArray) {
        if ([coursesArray count] == 1) {
            self.coursesLabel.text = FESWF(@"1 %@", FELocalized(@"COURSE_SINGULAR"));
        } else if (coursesArray.count == 0) {
            self.coursesLabel.text = FELocalized(@"COURSES_NOT_AVLBL_KEY");
        } else {
            self.coursesLabel.text = FESWF(@"%lu %@", (unsigned long)coursesArray.count, FELocalized(@"COURSE_PLURAL"));
        }
    } else {
        self.coursesLabel.text = FELocalized(@"COURSES_NOT_AVLBL_KEY");
    }
    
    NSString *filterString = [groupDefaults objectForKey:@"klassefilterstring"];
    self.classLabel.text = filterString;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)setLabels
{
    self.classTitleLabel.text = FELocalized(@"CLASS_TITLE_KEY");
    self.filterCoursesLabel.text = FELocalized(@"FILTER_COURSES");
    self.coursesTitleLabel.text = FELocalized(@"COURSE_PLURAL");
    self.showColorsLabel.text = FELocalized(@"COLORS_SUPPLY_PLAN");
    self.colorsTitleLabel.text = FELocalized(@"COLORS_PLURAL");
    self.blurLabel.text = FELocalized(@"BGIMAGE_BLUR");
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
                                                                     style:UIBarButtonItemStyleBordered
                                                                    target:self
                                                                    action:@selector(showMenu)];
    
    self.navigationItem.leftBarButtonItem = sideMenuItem;
    self.navigationItem.title = FELocalized(@"SETTINGS_KEY");
}


#pragma mark - UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = [super tableView:tableView heightForRowAtIndexPath:indexPath];
    
    if (indexPath.section == 0 && indexPath.row == 1) {
        if (self.classPickerVisible) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.15 animations:^{
                    self.classPickerView.alpha = 1.0;
                    self.classPickerView.userInteractionEnabled = YES;
                    self.classPickerView.hidden = NO;
                }];
            });
            return height;
        } else {
            [UIView animateWithDuration:0.15 animations:^{
                self.classPickerView.alpha = 0.0;
                self.classPickerView.userInteractionEnabled = NO;
            } completion:^(BOOL finished) {
                self.classPickerView.hidden = YES;
            }];
            return 0;
        }
    }
    return height;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return FELocalized(@"SUPPLY_PLAN_KEY");
    } else if (section == 2) {
        return FELocalized(@"BACKGROUNDIMAGE_TITLE_KEY");
    }
    return @"";
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            self.classPickerVisible = !self.classPickerVisible;
            [self.tableView beginUpdates];
            [self.tableView endUpdates];
        }
    }

    if (indexPath.section == 2 && indexPath.row == 0) {
        if ([FEVersionChecker version] >= 8.0) {
            UIAlertController *imageSheet = [UIAlertController alertControllerWithTitle:FELocalized(@"CHOOSE_IMAGE_TITLE")
                                                                                message:nil
                                                                         preferredStyle:UIAlertControllerStyleActionSheet];
            [imageSheet addAction:[UIAlertAction actionWithTitle:FELocalized(@"CANCEL_TITLE_KEY")
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {
                                                             [imageSheet dismissViewControllerAnimated:YES completion:nil];
                                                         }]];
            [imageSheet addAction:[UIAlertAction actionWithTitle:FELocalized(@"PHOTO_LIB_KEY")
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             [self setBackgroundImageFromSourceType:0];
            }]];
            [imageSheet addAction:[UIAlertAction actionWithTitle:FELocalized(@"CAMERA_KEY")
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             [self setBackgroundImageFromSourceType:1];
                                                         }]];
            [imageSheet addAction:[UIAlertAction actionWithTitle:FELocalized(@"LOAD_FROM_URL")
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             [self setBackgroundImageFromSourceType:2];
                                                         }]];
            [imageSheet addAction:[UIAlertAction actionWithTitle:FELocalized(@"USE_DEFAULT_IMG")
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             [self setBackgroundImageFromSourceType:3];
                                                         }]];
            
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                [imageSheet setModalPresentationStyle:UIModalPresentationPopover];
                
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                
                UIPopoverPresentationController *popPresenter = [imageSheet popoverPresentationController];
                popPresenter.sourceView = cell;
                popPresenter.sourceRect = cell.bounds;
            }
            
            [self presentViewController:imageSheet animated:YES completion:nil];
        } else {
            self.imageOptionsSheet = [[UIActionSheet alloc] initWithTitle:FELocalized(@"CHOOSE_IMAGE_TITLE")
                                                                 delegate:self
                                                        cancelButtonTitle:FELocalized(@"CANCEL_TITLE_KEY")
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:FELocalized(@"PHOTO_LIB_KEY"), FELocalized(@"CAMERA_KEY"), FELocalized(@"LOAD_FROM_URL"), FELocalized(@"USE_DEFAULT_IMG"), nil];
            self.imageOptionsSheet.tag = 100;
            
            [self.imageOptionsSheet showInView:self.view];
        }
    }
}

#pragma mark - Rotation

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if ([FEVersionChecker version] < 8.0) {
        [self.imageOptionsSheet dismissWithClickedButtonIndex:-1 animated:YES];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if ([FEVersionChecker version] < 8.0) {
        self.imageOptionsSheet = [[UIActionSheet alloc] initWithTitle:FELocalized(@"CHOOSE_IMAGE_TITLE")
                                                             delegate:self
                                                    cancelButtonTitle:FELocalized(@"CANCEL_TITLE_KEY")
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:FELocalized(@"PHOTO_LIB_KEY"), FELocalized(@"CAMERA_KEY"), FELocalized(@"LOAD_FROM_URL"), FELocalized(@"USE_DEFAULT_IMG"), nil];
        self.imageOptionsSheet.tag = 100;
        
        [self.imageOptionsSheet showInView:self.view];
    }
}


#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == 100) {
        [self setBackgroundImageFromSourceType:buttonIndex];
    }
}

#pragma mark - Klasse

- (NSUInteger)indexForFirstComponent
{
    NSUserDefaults *groupDefaults = [NSUserDefaults standardUserDefaults];
    NSUInteger index = 0;
    NSString *filterString = [groupDefaults objectForKey:@"klassefilterstring"];
    
    NSMutableString *stufeString = [[NSMutableString alloc] init];
    
    if ([filterString isEqualToString:@"Alle"]) {
        index = 0;
    } else if ([filterString isEqualToString:@"K_Abi"]) {
        index = [self.klassenArray count];
    } else {
                for (NSUInteger i = 0; i < filterString.length; i++) {
            char c = [filterString characterAtIndex:i];
            
            if (c >= '0' && c <= '9') {
                [stufeString appendString:[NSString stringWithFormat:@"%c", c]];
            }
        }
        index = [self.stufenArray indexOfObject:stufeString];
    }
    return index;
}

- (NSUInteger)indexForSecondComponent
{
    NSUserDefaults *groupDefaults = [NSUserDefaults standardUserDefaults];
    NSUInteger index = 0;
    NSString *filterString = [groupDefaults objectForKey:@"klassefilterstring"];
    NSString *klasseString = nil;
    
    if ([filterString isEqualToString:@"Alle"] || [filterString isEqualToString:@"10"] || [filterString isEqualToString:@"11"] || [filterString isEqualToString:@"12"] || [filterString isEqualToString:@"13"] || [filterString isEqualToString:@"K_Abi"]) {
        index = 0;
    } else {
        if (filterString.length > 1) {
            klasseString = [NSString stringWithFormat:@"%c", [filterString characterAtIndex:filterString.length - 1]];
            
            index = [self.klassenArray indexOfObject:klasseString];
        } else {
            index = 0;
        }
    }
    return index;
}


#pragma mark - UIPickerView

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return 40.0;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 2;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (component == 0) {
        return [self.stufenArray count];
    } else if (component == 1) {
        return [self.klassenArray count];
    }
    return 0;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (component == 0) {
        return self.stufenArray[row];
    } else if (component == 1) {
        return self.klassenArray[row];
    }
    return 0;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSString *stufeString = self.stufenArray[[self.classPickerView selectedRowInComponent:0]];
    NSString *klasseString = self.klassenArray[[self.classPickerView selectedRowInComponent:1]];
    
    if ([self.classPickerView selectedRowInComponent:0] == 0) {
        [self.classPickerView selectRow:0 inComponent:1 animated:YES];
        [self performSelector:@selector(setNeedsClassUpdate) withObject:nil afterDelay:0.2];
    }
    
    if ([stufeString isEqualToString:@"Alle"] || [stufeString isEqualToString:@"10"] || [stufeString isEqualToString:@"11"] || [stufeString isEqualToString:@"12"] || [stufeString isEqualToString:@"13"] || [stufeString isEqualToString:@"K_Abi"]) {
        [self.classPickerView selectRow:0 inComponent:1 animated:YES];
        [self performSelector:@selector(setNeedsClassUpdate) withObject:nil afterDelay:0.2];
    }
    
    if (![klasseString isEqualToString:@""]) {
        stufeString = self.stufenArray[[self.classPickerView selectedRowInComponent:0]];
        
        if ([stufeString isEqualToString:@"10"] || [stufeString isEqualToString:@"11"] || [stufeString isEqualToString:@"12"] || [stufeString isEqualToString:@"13"] || [stufeString isEqualToString:@"K_Abi"]) {
            [self.classPickerView selectRow:0 inComponent:1 animated:YES];
            [self performSelector:@selector(setNeedsClassUpdate) withObject:nil afterDelay:0.2];
        }
    }
    
    if (stufeString != nil && klasseString != nil) {
        [self setzeKlasseFuerFilterMitStufe:stufeString undSubKlasse:klasseString];
    }
}

- (void)setNeedsClassUpdate
{
    NSString *stufeString = self.stufenArray[[self.classPickerView selectedRowInComponent:0]];
    NSString *klasseString = self.klassenArray[[self.classPickerView selectedRowInComponent:1]];
    
    if (stufeString != nil && klasseString != nil) {
        [self setzeKlasseFuerFilterMitStufe:stufeString undSubKlasse:klasseString];
    }
}

- (void)setzeKlasseFuerFilterMitStufe:(NSString *)stufe undSubKlasse:(NSString *)klasse
{
    NSUserDefaults *groupDefaults = [NSUserDefaults standardUserDefaults];
    if (![stufe isEqualToString:@"Alle"]) {
        NSString *filterString = [stufe stringByAppendingString:klasse];
        self.classLabel.text = filterString;
        
        [groupDefaults setObject:filterString forKey:@"klassefilterstring"];
        [groupDefaults synchronize];
    } else {
        NSString *filterString = @"Alle";
        self.classLabel.text = filterString;
        
        [groupDefaults setObject:filterString forKey:@"klassefilterstring"];
        [groupDefaults synchronize];
    }
}

#pragma mark - Hintergrundbild

- (void)setBackgroundImageFromSourceType:(NSInteger)type
{
    switch (type) {
        case 0:
            // Photo Library
            self.imagePickerController = [[UIImagePickerController alloc] init];
            [self.imagePickerController setDelegate:self];
            [self.imagePickerController setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
            [self.imagePickerController setAllowsEditing:NO];
            [self presentViewController:self.imagePickerController animated:YES completion:nil];
            break;

        case 1:
            // Take from camera
            self.imagePickerController = [[UIImagePickerController alloc] init];
            [self.imagePickerController setDelegate:self];
            [self.imagePickerController setSourceType:UIImagePickerControllerSourceTypeCamera];
            [self.imagePickerController setAllowsEditing:NO];
            [self presentViewController:self.imagePickerController animated:YES completion:nil];
            break;
            
        case 2:
        {
            // Von URL laden
            if ([FEVersionChecker version] >= 8.0) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:FELocalized(@"ENTER_URL_KEY")
                                                                               message:FELocalized(@"URL_MESSAGE_KEY")
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                    [textField setPlaceholder:@"http://www.sample.com/photo.jpg"];
                    [textField setKeyboardType:UIKeyboardTypeURL];
                }];
                [alert addAction:[UIAlertAction actionWithTitle:FELocalized(@"CANCEL_TITLE_KEY")
                                                          style:UIAlertActionStyleCancel
                                                        handler:^(UIAlertAction *action) {
                                                            [alert dismissViewControllerAnimated:YES completion:nil];
                                                        }]];
                [alert addAction:[UIAlertAction actionWithTitle:FELocalized(@"LOAD_KEY")
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction *action) {
                                                            UITextField *txt = (UITextField *)[alert.textFields firstObject];
                                                            [self loadImageFromURL:[NSURL URLWithString:txt.text]];
                                                            
                                                        }]];
                [self presentViewController:alert animated:YES completion:nil];
            } else {
                UIAlertView *urlAlert = [[UIAlertView alloc] initWithTitle:FELocalized(@"ENTER_URL_KEY")
                                                                   message:FELocalized(@"URL_MESSAGE_KEY")
                                                                  delegate:self
                                                         cancelButtonTitle:FELocalized(@"CANCEL_TITLE_KEY")
                                                         otherButtonTitles:FELocalized(@"LOAD_KEY"), nil];
                
                urlAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
                [[urlAlert textFieldAtIndex:0] setPlaceholder:@"http://www.sample.com/photo.jpg"];
                [[urlAlert textFieldAtIndex:0] setKeyboardType:UIKeyboardTypeURL];
                urlAlert.tag = 100;
                
                [urlAlert show];
            }
        }
            break;
            
        case 3:
            // Default-Bild verwenden
            [[NSUserDefaults standardUserDefaults] setObject:@0 forKey:@"BACKGROUND_IMAGE_TYPE"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            self.backgroundImageView.image = [UIImage imageNamed:defaultMenuBackgroundImageName];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"BG_IMAGE_CHANGED" object:nil];

            // Delete saved images
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSLog(@"Deleting saved images");
                NSURL *documentsURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
                
                NSURL *bgImageURL = [documentsURL URLByAppendingPathComponent:@"BackgroundImage.JPG"];
                NSError *errorBG = nil;
                [[NSFileManager defaultManager] removeItemAtURL:bgImageURL error:&errorBG];
                
                if (errorBG) {
                    NSLog(@"ErrorBG= %@", errorBG);
                }
                
                NSURL *bgBlurImageURL = [documentsURL URLByAppendingPathComponent:@"BlurredBackgroundImage.JPG"];
                NSError *errorBGBlur = nil;
                [[NSFileManager defaultManager] removeItemAtURL:bgBlurImageURL error:&errorBGBlur];
                
                if (errorBGBlur) {
                    NSLog(@"ErrorBG_Blur= %@", errorBGBlur);
                }
            });
            break;
        default:
            break;
    }
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
    if (alertView.tag == 100) {
        if ([alertView textFieldAtIndex:0].text.length > 11) {
            return YES;
        }
    }
    return NO;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 100 && buttonIndex == 1) {
        [self loadImageFromURL:[NSURL URLWithString:[alertView textFieldAtIndex:0].text]];
    }
}

- (void)loadImageFromURL:(NSURL *)url
{
    [SVProgressHUD show];
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (!error) {
            UIImage *image = [[UIImage alloc] initWithData:data];
            [self saveImageToDocuments:image];

            dispatch_async(dispatch_get_main_queue(), ^{
                self.backgroundImageView.image = image;
                
                [[NSUserDefaults standardUserDefaults] setObject:@1 forKey:@"BACKGROUND_IMAGE_TYPE"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:@"BG_IMAGE_CHANGED" object:nil];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                    [SVProgressHUD dismiss];
                });
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                [SVProgressHUD showErrorWithStatus:FELocalized(@"ERROR_KEY")];
            });
        }
    }] resume];
}


#pragma mark - Switches

- (IBAction)changeFilterCoursesState:(UISwitch *)sw
{
    NSUserDefaults *groupDefaults = [NSUserDefaults standardUserDefaults];
    [groupDefaults setBool:sw.on forKey:@"SHOULD_FILTER_COURSES"];
    [groupDefaults synchronize];
}

- (IBAction)changeApplyColorsState:(UISwitch *)sw
{
    [[NSUserDefaults standardUserDefaults] setBool:sw.on forKey:@"SHOULD_APPLY_COLOR_SUPPLY_PLAN"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)changeApplyBlurState:(UISwitch *)sw
{
    [[NSUserDefaults standardUserDefaults] setBool:sw.on forKey:@"APPLIES_BLUR_ON_BACKGROUND"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BG_IMAGE_CHANGED" object:nil];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeBlack];

    [picker dismissViewControllerAnimated:YES completion:^{
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        if (image) {
            
            self.backgroundImageView.image = image;
            
            [self saveImageToDocuments:image];
            
            [[NSUserDefaults standardUserDefaults] setObject:@1 forKey:@"BACKGROUND_IMAGE_TYPE"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"BG_IMAGE_CHANGED" object:nil];
        }
    }];
}


#pragma mark - Load & save BackgroundImage

- (UIImage *)imageWithImage:(UIImage *)sourceImage scaledToWidth:(CGFloat)wdt
{
    CGFloat oldWidth = sourceImage.size.width;
    CGFloat scaleFactor = wdt / oldWidth;
    
    CGFloat newHeight = sourceImage.size.height * scaleFactor;
    CGFloat newWidth = oldWidth * scaleFactor;
    
    UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
    [sourceImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (UIImage *)imageWithImage:(UIImage *)sourceImage scaledToHeight:(CGFloat)hgt
{
    CGFloat oldHeight = sourceImage.size.height;
    CGFloat scaleFactor = hgt / oldHeight;
    
    CGFloat newWidth = sourceImage.size.width * scaleFactor;
    CGFloat newHeight = oldHeight * scaleFactor;
    
    UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
    [sourceImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (void)saveImageToDocuments:(UIImage *)img
{
    img = [self imageWithImage:img scaledToHeight:1200.0];
    img = [img OrientationFix];
    
    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingString:@"/Documents"];
    NSString *bgPath = [documentsDirectory stringByAppendingString:@"/BackgroundImage.JPG"];
    NSString *blurredBGPath = [documentsDirectory stringByAppendingString:@"/BlurredBackgroundImage.JPG"];
    
    NSData *imgData = UIImageJPEGRepresentation(img, 0.6);
    [imgData writeToFile:bgPath atomically:YES];
    
    UIImage *blurredImage = [img applyBlurWithRadius:16.0
                                           tintColor:[UIColor colorWithWhite:0.14 alpha:0.6]
                               saturationDeltaFactor:1.9
                                           maskImage:nil];
    
    NSData *blurredImgData = UIImageJPEGRepresentation(blurredImage, 0.6);
    [blurredImgData writeToFile:blurredBGPath atomically:YES];

    [SVProgressHUD dismiss];
}

- (UIImage *)savedBackgroundImage
{
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
