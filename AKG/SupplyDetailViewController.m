//
//  SupplyDetailViewController.m
//  AKG
//
//  Created by Fabian Ehlert on 21.02.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "SupplyDetailViewController.h"
#import "SupplyHelper.h"
#import "ReminderTableViewController.h"

#import <MessageUI/MessageUI.h>

@interface SupplyDetailViewController () <MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, ReminderDelegate, UIGestureRecognizerDelegate, UIDynamicAnimatorDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *lessonDescriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *lessonLabel;
@property (weak, nonatomic) IBOutlet UILabel *typeLabel;
@property (weak, nonatomic) IBOutlet UILabel *subjectNewLabel;
@property (weak, nonatomic) IBOutlet UILabel *subjectOldLabel;
@property (weak, nonatomic) IBOutlet UILabel *roomNewLabel;
@property (weak, nonatomic) IBOutlet UILabel *roomOldLabel;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;

@property (weak, nonatomic) IBOutlet UILabel *subjectNewDescriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *roomNewDescriptionLabel;

@property (weak, nonatomic) IBOutlet UILabel *subjectOldDescriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *roomOldDescriptionLabel;

@property (weak, nonatomic) IBOutlet UIView *markerView;

@property (weak, nonatomic) IBOutlet UIButton *reminderButton;
@property (weak, nonatomic) IBOutlet UIButton *mailButton;
@property (weak, nonatomic) IBOutlet UIButton *messageButton;

@property (strong, nonatomic) NSString *dateString;

@property (strong, nonatomic) MFMailComposeViewController *mailComposer;

@property (strong, nonatomic) UITapGestureRecognizer *tap;
@property (assign, nonatomic) BOOL infoLabelShowsClass;

@property (assign, nonatomic) CGPoint boxLocation;
@property (assign, nonatomic) CGRect originalRect;

@property (nonatomic, strong) UIPanGestureRecognizer *panRecognizer;

@property (nonatomic, strong) UIDynamicAnimator *animator;
@property (nonatomic, strong) UISnapBehavior *snapBehavior;
@property (nonatomic, strong) UIPushBehavior *pushBehavior;
@property (nonatomic, strong) UIAttachmentBehavior *panAttachmentBehavior;
@property (nonatomic, strong) UIDynamicItemBehavior *itemBehavior;

@property (weak, nonatomic) UIView *detailContainerView;

@end

@implementation SupplyDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Buttons
    [self setupButtons];
    
    // Klasse label
    self.infoLabelShowsClass = NO;
    
    self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleInfoSchoolClassLabel)];
    self.tap.numberOfTapsRequired = 1;
    self.tap.numberOfTouchesRequired = 1;

    [self.view addGestureRecognizer:self.tap];
    
    
    // Description Labels
    NSMutableAttributedString *roomOldDescription = [[NSMutableAttributedString alloc] initWithString:self.roomOldDescriptionLabel.text];
    [roomOldDescription addAttribute:NSStrikethroughStyleAttributeName value:@1 range:NSMakeRange(0, self.roomOldDescriptionLabel.text.length)];
    self.roomOldDescriptionLabel.attributedText = roomOldDescription;
    
    NSMutableAttributedString *subjectOldDescription = [[NSMutableAttributedString alloc] initWithString:self.subjectOldDescriptionLabel.text];
    [subjectOldDescription addAttribute:NSStrikethroughStyleAttributeName value:@1 range:NSMakeRange(0, self.subjectOldDescriptionLabel.text.length)];
    self.subjectOldDescriptionLabel.attributedText = subjectOldDescription;
    
    
    // If a supply was given by the parent Controller, we set the information to the Labels
    if (self.supply) {
        NSDate *date = self.supply.datum;
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"EEEE"];
        NSString *weekDay = [dateFormatter stringFromDate:date];
        
        [dateFormatter setDateFormat:@"dd.MMMM"];
        NSString *day = [dateFormatter stringFromDate:date];
        
        [dateFormatter setDateFormat:@"dd.MM.yy"];
        self.dateString = [dateFormatter stringFromDate:date];
        
        if ([day characterAtIndex:0] == '0') {
            day = [day stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
        }
        
        if ([day characterAtIndex:day.length - 1] == '.') {
            day = [day stringByReplacingCharactersInRange:NSMakeRange(day.length - 1, 1) withString:@""];
        }
        
        self.dateLabel.attributedText = [self attributedStringWithFirstString:weekDay secondString:day];
        self.lessonLabel.text = self.supply.stunde;
        self.typeLabel.text = self.supply.art;
        self.subjectNewLabel.text = self.supply.neuesFach;
        self.roomNewLabel.text = self.supply.neuerRaum;
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SHOULD_APPLY_COLOR_SUPPLY_PLAN"]) {
            self.markerView.backgroundColor = [SupplyHelper colorForType:self.supply.art];
        }
        
        if (self.supply.info == nil) {
            self.infoLabel.text = @"Keine Anmerkungen";
        } else {
            self.infoLabel.text = self.supply.info;
        }
        
        NSMutableAttributedString *subjectOld = [[NSMutableAttributedString alloc] initWithString:self.supply.altesFach];
        [subjectOld addAttribute:NSStrikethroughStyleAttributeName value:@1 range:NSMakeRange(0, self.supply.altesFach.length)];
        self.subjectOldLabel.attributedText = subjectOld;
        
        NSMutableAttributedString *roomOld = [[NSMutableAttributedString alloc] initWithString:self.supply.alterRaum];
        [roomOld addAttribute:NSStrikethroughStyleAttributeName value:@1 range:NSMakeRange(0, self.supply.alterRaum.length)];
        self.roomOldLabel.attributedText = roomOld;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.originalRect = self.view.frame;
        
        [self setupDynamics];
    });
}

- (void)setupButtons
{
    [self.reminderButton setImage:[UIImage imageNamed:@"ReminderButton"]
                         forState:UIControlStateNormal];
    [self.mailButton setImage:[UIImage imageNamed:@"MailButton"]
                     forState:UIControlStateNormal];
    [self.messageButton setImage:[UIImage imageNamed:@"MessageButton"]
                        forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    for (UIGestureRecognizer *gesture in self.view.gestureRecognizers) {
        [self.view removeGestureRecognizer:gesture];
    }
    
    [self.animator removeAllBehaviors];
    self.animator = nil;
}


- (void)setupDynamics
{
    self.panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    self.panRecognizer.delegate = self;
    [self.view addGestureRecognizer:self.panRecognizer];
    
    /* UIDynamics stuff */
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:[UIApplication sharedApplication].keyWindow];
    self.animator.delegate = self;
    
    // snap behavior to keep image view in the center as needed
    self.snapBehavior = [[UISnapBehavior alloc] initWithItem:self.view snapToPoint:self.view.center];
    self.snapBehavior.damping = 1.0f;
    
    self.pushBehavior = [[UIPushBehavior alloc] initWithItems:@[self.view] mode:UIPushBehaviorModeInstantaneous];
    self.pushBehavior.angle = 0.0f;
    self.pushBehavior.magnitude = 0.0f;
    
    self.itemBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.view]];
    self.itemBehavior.elasticity = 0.0f;
    self.itemBehavior.friction = 0.2f;
    self.itemBehavior.allowsRotation = YES;
    self.itemBehavior.density = 1.0;
    self.itemBehavior.resistance = 0.0;
}


#pragma mark - PanHandler

- (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer
{
	UIView *view = gestureRecognizer.view;
    
    // SuperLocation
	CGPoint location = [gestureRecognizer locationInView:[UIApplication sharedApplication].keyWindow];
    
	if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
		[self.animator removeBehavior:self.snapBehavior];
		[self.animator removeBehavior:self.pushBehavior];
		
        self.boxLocation = [gestureRecognizer locationInView:self.view];
        
		UIOffset centerOffset = UIOffsetMake(self.boxLocation.x - CGRectGetMidX(self.view.bounds), self.boxLocation.y - CGRectGetMidY(self.view.bounds));
		self.panAttachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:self.view offsetFromCenter:centerOffset attachedToAnchor:location];

		[self.animator addBehavior:self.panAttachmentBehavior];
		[self.animator addBehavior:self.itemBehavior];
	} else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        [self.panAttachmentBehavior setAnchorPoint:location];
	} else if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
		[self.animator removeBehavior:self.panAttachmentBehavior];
		
		CGFloat deviceVelocityScale = 1.0f;
		CGFloat deviceAngularScale = 1.0f;
		CGPoint velocity = [gestureRecognizer velocityInView:self.view];
		CGFloat velocityAdjust = 10.0f * deviceVelocityScale;
		
		if (fabs(velocity.x / velocityAdjust) > 50.0 || fabs(velocity.y / velocityAdjust) > 50.0) {
			UIOffset offsetFromCenter = UIOffsetMake(self.boxLocation.x - CGRectGetMidX(self.view.bounds), self.boxLocation.y - CGRectGetMidY(self.view.bounds));
			CGFloat radius = sqrtf(powf(offsetFromCenter.horizontal, 2.0f) + powf(offsetFromCenter.vertical, 2.0f));
			CGFloat pushVelocity = sqrtf(powf(velocity.x, 2.0f) + powf(velocity.y, 2.0f));
			
			// calculate angles needed for angular velocity formula
			CGFloat velocityAngle = atan2f(velocity.y, velocity.x);
			CGFloat locationAngle = atan2f(offsetFromCenter.vertical, offsetFromCenter.horizontal);
			if (locationAngle > 0) {
				locationAngle -= M_PI * 2;
			}
			
			// angle (θ) is the angle between the push vector (V) and vector component parallel to radius, so it should always be positive
			CGFloat angle = fabs(fabs(velocityAngle) - fabs(locationAngle));
			// angular velocity formula: w = (abs(V) * sin(θ)) / abs(r)
			CGFloat angularVelocity = fabs((fabs(pushVelocity) * sinf(angle)) / fabs(radius));
			
			// rotation direction is dependent upon which corner was pushed relative to the center of the view
			// when velocity.y is positive, pushes to the right of center rotate clockwise, left is counterclockwise
			CGFloat direction = (location.x < view.center.x) ? -1.0f : 1.0f;
			// when y component of velocity is negative, reverse direction
			if (velocity.y < 0) { direction *= -1; }
			
			// amount of angular velocity should be relative to how close to the edge of the view the force originated
			// angular velocity is reduced the closer to the center the force is applied
			// for angular velocity: positive = clockwise, negative = counterclockwise
			CGFloat xRatioFromCenter = fabs(offsetFromCenter.horizontal) / (CGRectGetWidth(self.view.frame) / 2.0f);
			CGFloat yRatioFromCetner = fabs(offsetFromCenter.vertical) / (CGRectGetHeight(self.view.frame) / 2.0f);
            
			// apply device scale to angular velocity
			angularVelocity *= deviceAngularScale;
			// adjust angular velocity based on distance from center, force applied farther towards the edges gets more spin
			angularVelocity *= ((xRatioFromCenter + yRatioFromCetner) / 2.0f);
			
			[self.itemBehavior addAngularVelocity:angularVelocity * 1.0 * direction forItem:self.view];
			[self.animator addBehavior:self.pushBehavior];
			self.pushBehavior.pushDirection = CGVectorMake((velocity.x / velocityAdjust) * 1.0, (velocity.y / velocityAdjust) * 1.0);
			self.pushBehavior.active = YES;
			
			// delay for dismissing is based on push velocity also
			CGFloat delay = 0.42 - (pushVelocity / 10000.0f);
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if ([self.delegate respondsToSelector:@selector(dismissBackground)]) {
                    [self.delegate dismissBackground];
                }
            });
		} else {
			[self returnToCenter];
		}
	}
}

- (void)returnToCenter
{
	if (self.animator) {
		[self.animator removeAllBehaviors];
	}
	[UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
		self.view.transform = CGAffineTransformIdentity;
		self.view.frame = self.originalRect;
	} completion:nil];
}


#pragma mark - Actions

- (IBAction)shareSetReminder
{
    ReminderTableViewController *reminderController = [self.storyboard instantiateViewControllerWithIdentifier:@"REMINDER"];
    reminderController.delegate = self;
    reminderController.titleString = [NSString stringWithFormat:@"%@: %@.Std, %@: %@", self.supply.klasse, self.supply.stunde, self.dateString, self.supply.art];
    reminderController.notesString = [NSString stringWithFormat:@"%@ in der %@.Stunde am %@\nKlasse: %@\nGeplant: %@, %@\nIst: %@, %@\nBemerkung: %@", self.supply.art, self.supply.stunde, self.dateString, self.supply.klasse, self.supply.altesFach, self.supply.alterRaum, self.supply.neuesFach, self.supply.neuerRaum, self.supply.info];
    reminderController.date = self.supply.datum;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:reminderController];
    
    if ([FEVersionChecker version] >= 8.0) {
        navigationController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    } else {
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    
    navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    }
    
    [self.parentViewController presentViewController:navigationController animated:YES completion:nil];
}

- (IBAction)shareSendMail
{
    if ([MFMailComposeViewController canSendMail]) {
        NSString *shareString = [NSString stringWithFormat:@"%@ in der %@.Stunde am %@\nKlasse: %@\nGeplant: %@, %@\nIst: %@, %@\nBemerkung: %@", self.supply.art, self.supply.stunde, self.dateString, self.supply.klasse, self.supply.altesFach, self.supply.alterRaum, self.supply.neuesFach, self.supply.neuerRaum, self.supply.info];
        
        self.mailComposer = [[MFMailComposeViewController alloc] init];
        [self.mailComposer setSubject:[NSString stringWithFormat:@"%@ am %@", self.supply.art, self.dateString]];
        [self.mailComposer setMessageBody:shareString isHTML:NO];
        self.mailComposer.mailComposeDelegate = self;
        
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
        }
        
        [self.view.window.rootViewController presentViewController:self.mailComposer animated:YES completion:nil];
    } else {
        [SVProgressHUD showErrorWithStatus:FELocalized(@"mailKannNichtVersendetWerden")];
    }
}

- (IBAction)shareSendMessage
{
    if ([MFMessageComposeViewController canSendText]) {
        NSString *shareString = [NSString stringWithFormat:@"%@ in der %@.Stunde am %@\n%@\nGeplant: %@, %@\nIst: %@, %@\nBemerkung: %@", self.supply.art, self.supply.stunde, self.dateString, self.supply.klasse, self.supply.altesFach, self.supply.alterRaum, self.supply.neuesFach, self.supply.neuerRaum, self.supply.info];
        
        MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
        controller.body = shareString;
        controller.messageComposeDelegate = self;
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
        }
        
        [self.view.window.rootViewController presentViewController:controller animated:YES completion:nil];
    } else {
        [SVProgressHUD showErrorWithStatus:FELocalized(@"nachrichtKannNichtVersendetWerden")];
    }
}


#pragma mark - Private

- (NSAttributedString *)attributedStringWithFirstString:(NSString *)str0 secondString:(NSString *)str1
{
    UIFont *mediumFont = [UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0];
    if ([FEVersionChecker version] >= 9.0) {
        mediumFont = [UIFont systemFontOfSize:17.0 weight:UIFontWeightMedium];
    }

    UIFont *lightFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:17.0];
    if ([FEVersionChecker version] >= 9.0) {
        lightFont = [UIFont systemFontOfSize:17.0 weight:UIFontWeightLight];
    }

    NSMutableAttributedString *aStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@", str0, str1]];
    [aStr addAttribute:NSFontAttributeName value:mediumFont range:NSMakeRange(0, str0.length)];
    [aStr addAttribute:NSFontAttributeName value:lightFont range:NSMakeRange(str0.length + 1, str1.length)];

    return aStr;
}


#pragma mark - InfoLabel

- (void)toggleInfoSchoolClassLabel
{
    if (self.infoLabelShowsClass) {
        // Show Info
        [UIView animateWithDuration:0.37 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.infoLabel.alpha = 0.0;
        } completion:^(BOOL finished) {
            if (self.supply.info == nil) {
                self.infoLabel.text = @"Keine Anmerkungen";
            } else {
                self.infoLabel.text = self.supply.info;
            }
        }];
        
        [UIView animateWithDuration:0.28 delay:0.1 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.infoLabel.alpha = 1.0;
        } completion:^(BOOL finished) {
            self.infoLabelShowsClass = NO;
        }];
    } else {
        // Show Class
        [UIView animateWithDuration:0.37 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.infoLabel.alpha = 0.0;
        } completion:^(BOOL finished) {
            if ([self.supply.klasse rangeOfString:@"K10"].location == NSNotFound && [self.supply.klasse rangeOfString:@"K11"].location == NSNotFound && [self.supply.klasse rangeOfString:@"K12"].location == NSNotFound) {
                self.infoLabel.text = [NSString stringWithFormat:@"Klasse %@", self.supply.klasse];
            } else {
                self.infoLabel.text = [NSString stringWithFormat:@"Stufe %@", self.supply.klasse];
            }
        }];
        
        [UIView animateWithDuration:0.28 delay:0.1 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.infoLabel.alpha = 1.0;
        } completion:^(BOOL finished) {
            self.infoLabelShowsClass = YES;
        }];
    }
}


#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    [controller dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - ReminderDelegate

- (void)reminderDidCancel
{
}

- (void)reminderDidCreate
{
    [SVProgressHUD showSuccessWithStatus:FELocalized(@"CREATED_REMINDER")];
}

- (void)reminderDidFail
{
    if ([FEVersionChecker version] >= 8.0) {
        UIAlertController *deactivatedRemindersAlert = [UIAlertController alertControllerWithTitle:FELocalized(@"ERROR_KEY")
                                                                                           message:FELocalized(@"REMINDER_PRIVACY_HINT")
                                                                                    preferredStyle:UIAlertControllerStyleAlert];
        [deactivatedRemindersAlert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                                      style:UIAlertActionStyleCancel
                                                                    handler:^(UIAlertAction *action) {
                                                                        [deactivatedRemindersAlert dismissViewControllerAnimated:YES completion:nil];
                                                                    }]];
        [self presentViewController:deactivatedRemindersAlert animated:YES completion:nil];
    } else {
        UIAlertView *deactivatedRemindersAlert = [[UIAlertView alloc] initWithTitle:FELocalized(@"ERROR_KEY")
                                                                            message:FELocalized(@"REMINDER_PRIVACY_HINT")
                                                                           delegate:self
                                                                  cancelButtonTitle:@"OK"
                                                                  otherButtonTitles:nil];
        [deactivatedRemindersAlert show];
    }
}


#pragma mark - Orientation

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if ([self.delegate respondsToSelector:@selector(orientationChanged)]) {
        [self.delegate orientationChanged];
    }
}

@end
