//
//  AppDelegate.m
//  AKG
//
//  Created by Fabian Ehlert on 23.01.14.
//  Copyright (c) 2014 Fabian Ehlert. All rights reserved.
//

#import "AppDelegate.h"
#import "SupplyItem.h"
#import "FESupplyFetcher.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [application setStatusBarStyle:UIStatusBarStyleDefault];
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];

    self.window.tintColor = [UIColor colorWithRed:(0.0/255.0) green:(122.0/255.0) blue:(255.0/255.0) alpha:1.0];
    
    [self registerForRemoteNotification];
    
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"vtypearray"]) {
        NSArray *typeArray = @[@{@"name": @"Vertretung", @"color": @"0"}, @{@"name": @"Fällt aus", @"color": @"1"}, @{@"name": @"Raumvertretung", @"color": @"2"}, @{@"name": @"Veranstaltung", @"color": @"3"}, @{@"name": @"Sondereinstellung", @"color": @"4"}, @{@"name": @"Unterricht geändert", @"color": @"5"}, @{@"name": @"Freisetzung", @"color": @"6"}, @{@"name": @"Betreuung", @"color": @"7"}, @{@"name": @"Tausch", @"color": @"8"}, @{@"name": @"Andere", @"color": @"9"}];
        
        [[NSUserDefaults standardUserDefaults] setObject:typeArray forKey:@"vtypearray"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

    return YES;
}

- (void)registerForRemoteNotification {
    if ([FEVersionChecker version] >= 8.0) {
        UIUserNotificationType types = UIUserNotificationTypeSound | UIUserNotificationTypeBadge | UIUserNotificationTypeAlert;
        UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
    } else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    }
}

#ifdef __IPHONE_8_2
- (void)application:(UIApplication *)application handleWatchKitExtensionRequest:(NSDictionary *)userInfo reply:(void (^)(NSDictionary *))reply {
    NSLog(@"WatchKit request: %@", userInfo);
    
    if ([[userInfo objectForKey:@"type"] isEqualToString:@"updateSupply"]) {
        [[FESupplyFetcher sharedFetcher] fetchNewData];
        reply(@{@"status": @"Parsed new Supply data! Ready to fetch."});
    } else {
        reply(nil);
    }
}
#endif

#ifdef __IPHONE_8_0
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    [application registerForRemoteNotifications];
}
#endif

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    NSLog(@"Starting Background Fetch...");
    // 1. Fetch the latest supply data
    NSArray *notificationSupplyArray = [FESupplyFetcher latestSupplyArray];
    
    // 2. Parse UUIDs for each Supply item
    NSMutableArray *currentNotificationUUIDs = [[NSMutableArray alloc] init];
    for (SupplyItem *supply in notificationSupplyArray) {
        if (![supply.stunde isEqualToString:@""] || supply.stunde == nil) {
            [currentNotificationUUIDs addObject:supply.uuid];
        }
    }
    
    // 3. Get the previously saved UUIDs from the last Notification
    NSArray *lastNotificationUUIDs = [[NSUserDefaults standardUserDefaults] objectForKey:@"LAST_NOT_UUID_OBJECTS"];
    // 4. Boolen to decide whether to send a notification or not
    BOOL shouldSendNotification = NO;
    
    // 5. Decide whether to send a notification or not
    // 5.1 If the count of available UUIDs changes, we have to send a notification
    if ([lastNotificationUUIDs count] != [currentNotificationUUIDs count]) {
        shouldSendNotification = YES;
    } else if (lastNotificationUUIDs) {
        // 5.2 If the count doesn´t change, we check if there are any new UUIDs available
        // --- If YES, we have to send a notification
        for (NSString *uuid in currentNotificationUUIDs) {
            if (![lastNotificationUUIDs containsObject:uuid]) {
                shouldSendNotification = YES;
                break;
            }
        }
    }
    
    // 6. Send the notification
    if (shouldSendNotification) {
        // 6.1 First, store the updated UUID list
        [[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithArray:currentNotificationUUIDs] forKey:@"LAST_NOT_UUID_OBJECTS"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // 6.2 Get the count of UUIDs
        NSUInteger uuidCount = [currentNotificationUUIDs count];
        if (uuidCount > 0) {
            // 6.2.1 Check whether we have to use Plural or Singular
            NSString *supplyNameString = @"Vertretungen";
            if (uuidCount == 1) {
                supplyNameString = @"Vertretung";
            }
            
            // 6.2.2 Create the notification (set attributes etc.)
            UILocalNotification *notification = [[UILocalNotification alloc] init];
            notification.hasAction = YES;
            notification.alertAction = @"Ansehen";
            notification.alertBody = [NSString stringWithFormat:@"Du hast %lu anstehende %@", (unsigned long)uuidCount, supplyNameString];
            notification.soundName = UILocalNotificationDefaultSoundName;
            notification.fireDate = [NSDate dateWithTimeIntervalSinceNow:2];

            // 6.2.3 Schedule the notification
            [[UIApplication sharedApplication] scheduleLocalNotification:notification];
            // 6.2.4 Tell the completionHandler, that we have successfully completed the BackgroundFetch
            completionHandler(UIBackgroundFetchResultNewData);
        } else {
            completionHandler(UIBackgroundFetchResultNewData);
        }
    } else {
        // 6.3 Tell the completionHandler, that we have successfully completed the BackgroundFetch
        completionHandler(UIBackgroundFetchResultNewData);
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}


#pragma mark -
- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"AKG" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"AKG_HA.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
