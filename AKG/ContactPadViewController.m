//
//  ContactPadViewController.m
//  AKG
//
//  Created by Fabian Ehlert on 02.04.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "ContactPadViewController.h"
#import <MapKit/MapKit.h>

@interface ContactPadViewController () <UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end

@implementation ContactPadViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = FELocalized(@"MAP_KEY");
    
    [self setupMenu];
    [self setupMap];
}

- (void)dealloc {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    self.mapView = nil;
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
    self.navigationItem.title = FELocalized(@"CONTACT_KEY");
}

- (void)showMenu
{
    [self.sideMenuViewController presentLeftMenuViewController];
}


#pragma mark - Map

- (void)requestShowDirections
{
    if ([FEVersionChecker version] >= 8.0) {
        UIAlertController *mapAlert = [UIAlertController alertControllerWithTitle:FELocalized(@"MAP_ALERT_TITLE_KEY")
                                                                          message:FELocalized(@"MAP_ALERT_MESSAGE_KEY")
                                                                   preferredStyle:UIAlertControllerStyleAlert];
        [mapAlert addAction:[UIAlertAction actionWithTitle:FELocalized(@"CANCEL_TITLE_KEY")
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction *action) {
                                                       [mapAlert dismissViewControllerAnimated:YES completion:nil];
        }]];
        
        [mapAlert addAction:[UIAlertAction actionWithTitle:FELocalized(@"EXTERN_WEB_ALERT_OPEN_KEY")
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
                                                       [self showDirections];
        }]];
        
        [self presentViewController:mapAlert animated:YES completion:nil];
    } else {
        UIAlertView *mapAlert = [[UIAlertView alloc] initWithTitle:FELocalized(@"MAP_ALERT_TITLE_KEY")
                                                           message:FELocalized(@"MAP_ALERT_MESSAGE_KEY")
                                                          delegate:self
                                                 cancelButtonTitle:FELocalized(@"CANCEL_TITLE_KEY")
                                                 otherButtonTitles:FELocalized(@"EXTERN_WEB_ALERT_OPEN_KEY"), nil];
        mapAlert.tag = 101;
        [mapAlert show];
    }
}

- (void)showDirections
{
    Class mapItemClass = [MKMapItem class];
    if (mapItemClass && [mapItemClass respondsToSelector:@selector(openMapsWithItems:launchOptions:)]) {
        // Create an MKMapItem to pass to the Maps app
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(49.689337, 8.61798);
        MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:coordinate addressDictionary:nil];
        MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
        [mapItem setName:@"AKG Bensheim"];
        
        // MKLaunchOptionsDirectionsModeDriving
        NSDictionary *launchOptions = @{MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving};
        // Get the "Current User Location" MKMapItem
        MKMapItem *currentLocationMapItem = [MKMapItem mapItemForCurrentLocation];
        // Pass the current location and destination map items to the Maps app
        // Set the direction mode in the launchOptions dictionary
        [MKMapItem openMapsWithItems:@[currentLocationMapItem, mapItem] launchOptions:launchOptions];
    }
}

- (void)setupMap
{
    MKCoordinateRegion region;
    region.center.latitude = 49.689337;
    region.center.longitude = 8.61798;
    region.span.latitudeDelta = 0.020411;
    region.span.longitudeDelta = 0.040576;
    
    CLLocationCoordinate2D coordinate;
    coordinate.latitude = 49.689337;
    coordinate.longitude = 8.61798;
    
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    [annotation setCoordinate:coordinate];
    [annotation setTitle:@"AKG Bensheim"];
    [annotation setSubtitle:@"Wilhelmstraße 62"];
    
    self.mapView.mapType = MKMapTypeStandard;
    self.mapView.region = region;
    
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView addAnnotation:annotation];
    
    double delayInSeconds = 0.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.mapView selectAnnotation:annotation animated:YES];
    });
}



#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 101 && buttonIndex == 1) {
        [self showDirections];
    }
}

@end
