//
//  AppDelegate.m
//
// Copyright (c) 2016, OHSU. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//


#import "AppDelegate.h"
#import <CoreData/CoreData.h>
#import "Zone.h"
#import "Zone+MakeAndMod.h"
#import "Measurement.h"
#import "Measurement+MakeAndMod.h"
#import "Mole.h"
#import "Mole+MakeAndMod.h"
#import "IntroAndEligibleRKModule.h"
#import "OnboardingViewController.h"
#import "BodyMapViewController.h"
#import "DashboardViewController.h"
#import <BridgeSDK/BridgeSDK.h>
#import "WelcomeCarouselViewController.h"
#import "ReconsentViewController.h"


@implementation AppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

-(NSString *)certificateFileName
{
    
    /*This is the default for a production release, and make sure to add in the production .pem before testing and before releasing to app store, but TAKE IT OUT before committing to a public repo*/
    return @"ohsu-molemapper-production";
    
    /*This is the default for QA,*/
    //return @"ohsu-molemapper-staging";
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    /*This is the setup for a production release*/
    [BridgeSDK setupWithStudy:@"ohsu-molemapper" environment:SBBEnvironmentProd];
    
    /*This is the setup for normal QA purposes*/
    //[BridgeSDK setupWithStudy:@"ohsu-molemapper" environment:SBBEnvironmentStaging];
    
    /*For testing against a filtered app version; Anything over build version 0 will return with 'validation failed' in json response. ohsu-molemapper-staging .pem can be used here*/
    //[BridgeSDK setupWithStudy:@"killswitch" environment:SBBEnvironmentProd];
    
    self.bridgeManager = [[BridgeManager alloc] init];
    self.bridgeManager.context = self.managedObjectContext;
    self.dataUploader = [[APCDataUploader alloc] init];
    self.user = [[MMUser alloc] init];
    
    [self clearCoreDataStoreOfInvalidMeasurements];
    
    [self loadAllZonesWithContext:self.managedObjectContext];
    
    [self setupStdUserDefaults];

    [self overridePageControlColors];
    
    [self renameLegacyStoredFilenamesInFileSystem];
    
    [self renameLegacyStoredFilenamesInCoreData];
    
    //[self setOnboardingBooleansBackToInitialValues];

//Do we want to try to send any unsent measurements here upon launch? Same for surveys?
//[self.bridgeManager signInAndSendMeasurements];
    
    [self showCorrectOnboardingScreenOrBodyMap];
    
    return YES;
}

-(void)showCorrectOnboardingScreenOrBodyMap
{
    if ([self shouldShowReconsentScreen])
    {
        [self showReconsentScreen];
    }
         
    else
    {
        if ([self shouldShowWelcomeScreenWithCarousel])
        {
            [self showWelcomeScreenWithCarousel];
        }
        else if ([self shouldShowOnboarding])
        {
            /*This is a series of tracked booleans in NSUserDefaults that will switch on
            as each step is completed, and then the previous step will be turned off,
            thus allowing the state to be 'saved' if the user opts out at any point
             See below for details on the various steps, which are all ResearchKit modules
             that are spun up from the 'base class' onboardingViewController
             [ud setBool:NO forKey:@"shouldShowEligibilityTest"];
             [ud setBool:NO forKey:@"shouldShowInfoScreens"];
             [ud setBool:NO forKey:@"shouldShowQuiz"];
             [ud setBool:NO forKey:@"shouldShowConsent"];
             [ud setBool:NO forKey:@"shouldShowBridgeSignup"];
             [ud setBool:NO forKey:@"shouldShowInitialSurvey"];*/
            [self showOnboarding];
        }
        else
        {
            [self showBodyMap];
        }
    }
}

//Primarily used for reset or debugging
-(void)setOnboardingBooleansBackToInitialValues
{
    //[self clearMeasurementsAlreadySentForDebugging];
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    
    //These 2 below should be set to Yes at the beginning to allow onboarding to proceed
    [ud setBool:YES forKey:@"shouldShowWelcomeScreenWithCarousel"];
    [ud setBool:YES forKey:@"shouldShowOnboarding"];
    //All of these below will be set to YES throughout the onboarding as each step is completed
    [ud setBool:NO forKey:@"shouldShowEligibilityTest"];
    [ud setBool:NO forKey:@"shouldShowInfoScreens"];
    [ud setBool:NO forKey:@"shouldShowQuiz"];
    [ud setBool:NO forKey:@"shouldShowConsent"];
    [ud setBool:NO forKey:@"shouldShowBridgeSignup"];
    [ud setBool:NO forKey:@"shouldShowInitialSurvey"];
    
    //[ud setBool:NO forKey:@"shouldShowIntroAndEligible"];
}

-(void)clearMeasurementsAlreadySentForDebugging
{
    NSMutableArray *mutable = [self.user.measurementsAlreadySentToBridge mutableCopy];
    [mutable removeAllObjects];
    NSArray *empty = mutable;
    self.user.measurementsAlreadySentToBridge = empty;
}

//user.hasEnrolled and user.hasConsented track *almost* identically
//Build version 4 is a new study with OHSU as sole study sponsor
-(BOOL)shouldShowReconsentScreen
{
    BOOL shouldShowReconsentScreen = NO;
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSBundle *mainBundle = [NSBundle mainBundle];
    int appVersion = [[mainBundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey] intValue];
    
//ONLY USED FOR DEBUGGING, CHANGE THIS BACK OR
    //[ud setBool:NO forKey:@"reconsentHasBeenSeen"];
//ONLY USED FOR DEBUGGING, CHANGE THIS BACK
    
    if (appVersion == 4 &&
        self.user.hasEnrolled == YES &&
        [ud boolForKey:@"reconsentHasBeenSeen"] == NO)
    {
        shouldShowReconsentScreen = YES;
    }
    
    return shouldShowReconsentScreen;
}

-(void)showReconsentScreen
{
    ReconsentViewController *reconsent = [[UIStoryboard storyboardWithName:@"onboarding" bundle:nil] instantiateViewControllerWithIdentifier:@"reconsent"];
    [self setUpRootViewController:reconsent];
}

-(BOOL)shouldShowOnboarding
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:@"shouldShowOnboarding"];
}

-(void)showOnboarding
{
    //OnboardingVC will check environment variables (NSUserDefaults) to see which part of onboarding to spin up
    
    OnboardingViewController *onboarding = [[UIStoryboard storyboardWithName:@"onboarding" bundle:nil] instantiateViewControllerWithIdentifier:@"onboardingBase"];
    [self setUpRootViewController:onboarding];
}

-(BOOL)shouldShowWelcomeScreenWithCarousel
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    return [ud boolForKey:@"shouldShowWelcomeScreenWithCarousel"];
}

-(void)showWelcomeScreenWithCarousel
{
    WelcomeCarouselViewController* welcome = [[UIStoryboard storyboardWithName:@"onboarding" bundle:nil] instantiateViewControllerWithIdentifier:@"WelcomeCarouselViewController"];
    [self setUpRootViewController:welcome];
}

- (void)showBodyMap
{
    UITabBarController *tabBar = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"tabBar"];
    
    [UIView transitionWithView:self.window
                      duration:0.0
                       options:UIViewAnimationOptionTransitionNone
                    animations:^{
                        self.window.rootViewController = tabBar;
                        [self.window makeKeyAndVisible];
                    }
                    completion:nil];

}

- (void) setUpRootViewController: (UIViewController*) viewController
{
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    navController.navigationBar.translucent = NO;
        
    [UIView transitionWithView:self.window
                      duration:0.6
                       options:UIViewAnimationOptionTransitionNone
                    animations:^{
                        self.window.rootViewController = navController;
                        [self.window makeKeyAndVisible];
                    }
                    completion:nil];
}

/*
 In older versions of the app, filenames are stored with full explicit filepath, and these are overriden upon new version numebrs, 
 losing data.  This will go through the filesystem and rename legacy files to have just a filename, not having the full filepath (stupid)
 */
-(void)renameLegacyStoredFilenamesInFileSystem
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0]; //Get the docs directory
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *photoFilenames = [fm contentsOfDirectoryAtPath:documentsPath error:nil];
    if (photoFilenames == nil || [photoFilenames count] == 0) {return;}
    
    //Match 4 digits at beginning of filename and then .png This is a legacy format for zonePhoto names
    NSRegularExpression *zoneRegex = [NSRegularExpression regularExpressionWithPattern:@"^\\d{4}\\.png$"
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:nil];
    for (NSString *fileName in photoFilenames)
    {
        NSRange fullLength = NSMakeRange(0, [fileName length]);
        NSUInteger zoneMatches = [zoneRegex numberOfMatchesInString:fileName options:0 range:fullLength];
        
        if (zoneMatches == 1)
        {
            NSString *currentName = [NSString stringWithFormat:@"%@/%@",documentsPath,fileName];
            NSString *correctZoneName = [NSString stringWithFormat:@"zone%@",fileName];
            NSString *updatedName = [NSString stringWithFormat:@"%@/%@",documentsPath,correctZoneName];
            [fm moveItemAtPath:currentName toPath:updatedName error:nil];
        }
    }
}

-(void)renameLegacyStoredFilenamesInCoreData
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Zone" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"zoneID" ascending:YES]];
    NSArray *zones = [context executeFetchRequest:fetchRequest error:nil];
    
    if (!zones || [zones count] == 0) {return;}
    else
    {
        for (Zone *zone in zones)
        {
            NSString *zonePhotoFileName = [Zone imageFilenameForZoneID:zone.zoneID];
            zone.zonePhoto = zonePhotoFileName;
        }
    }
    
    [self saveContext];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Measurement"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"whichMole" ascending:YES]];
    NSArray *measurementMatches = [context executeFetchRequest:request error:nil];
    
    if (!measurementMatches || [measurementMatches count] == 0) {return;}
    
    for (Measurement *measurement in measurementMatches)
    {
        //2delimitDec_29,_2014_17colon45colon56.png
        if (measurement.measurementID == nil) {continue;} //protect against nullified measurements?
        NSString *measurementID = measurement.measurementID;
        NSRange fullLength = NSMakeRange(0, [measurementID length]);
        
        //Match the filepath up to the documents directory that is in your filename
        NSRegularExpression *measureRegex = [NSRegularExpression regularExpressionWithPattern:@"^/\\S*Documents/" options:NSRegularExpressionCaseInsensitive error:nil];
        NSUInteger measureMatches = [measureRegex numberOfMatchesInString:measurementID options:0 range:fullLength];
        if (measureMatches == 1)
        {
            //swap out the directory structure before your filename with an empty string
            NSString *updatedMeasurementID = [measureRegex stringByReplacingMatchesInString:measurementID
                                                                                    options:0
                                                                                      range:fullLength
                                                                               withTemplate:@""];
            measurement.measurementID = updatedMeasurementID;
            measurement.measurementPhoto = updatedMeasurementID;
        }
        
    }
    
    [self saveContext];
}

-(void)overridePageControlColors
{
    UIPageControl *pageControl = [UIPageControl appearance];
    pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
    pageControl.currentPageIndicatorTintColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
    pageControl.backgroundColor = [UIColor clearColor];
}

//Establishes default values for a number of booleans and counters used throughout the app
-(void)setupStdUserDefaults
{
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    
    //Setup the global repository for available moleIDs
    if (![standardUserDefaults objectForKey:@"nextMoleID"]) //check to see if already established stdUsrDefaults
    {
        int firstValidMoleID = 1;
        [standardUserDefaults setInteger:firstValidMoleID forKey:@"nextMoleID"];
    }
    //Setup default reference object
    if (![standardUserDefaults objectForKey:@"referenceObject"])
    {
        NSString *referenceObject = @"Dime";
        [standardUserDefaults setValue:referenceObject forKey:@"referenceObject"];
    }
    if (![standardUserDefaults objectForKey:@"moleNameGender"])
    {
        NSString *defaultMoleNameGender = @"Random";
        [standardUserDefaults setValue:defaultMoleNameGender forKey:@"moleNameGender"];
    }
    if (![standardUserDefaults objectForKey:@"exportReminderCounter"])
    {
        [standardUserDefaults setValue:@0 forKey:@"exportReminderCounter"];
    }
    if (![standardUserDefaults objectForKey:@"showDemoInfo"])
    {
        [standardUserDefaults setValue:[NSNumber numberWithBool:YES] forKey:@"showDemoInfo"];
    }
    if (![standardUserDefaults objectForKey:@"shouldShowOnboarding"])
    {
        [standardUserDefaults setValue:[NSNumber numberWithBool:YES] forKey:@"shouldShowOnboarding"];
    }
    if (![standardUserDefaults objectForKey:@"shouldShowEligibilityTest"])
    {
        [standardUserDefaults setValue:[NSNumber numberWithBool:NO] forKey:@"shouldShowEligibilityTest"];
    }
    if (![standardUserDefaults objectForKey:@"shouldShowConsent"])
    {
        [standardUserDefaults setValue:[NSNumber numberWithBool:NO] forKey:@"shouldShowConsent"];
    }
    if (![standardUserDefaults objectForKey:@"measurementsAlreadySentToBridge"])
    {
        [standardUserDefaults setObject:[NSArray array] forKey:@"measurementsAlreadySentToBridge"];
    }
    if (![standardUserDefaults objectForKey:@"shouldShowRememberCoinPopup"])
    {
        [standardUserDefaults setValue:[NSNumber numberWithBool:YES] forKey:@"shouldShowRememberCoinPopup"];
    }
    if (![standardUserDefaults objectForKey:@"shouldShowWelcomeScreenWithCarousel"])
    {
        [standardUserDefaults setValue:[NSNumber numberWithBool:YES] forKey:@"shouldShowWelcomeScreenWithCarousel"];
    }
    if (![standardUserDefaults objectForKey:@"reconsentHasBeenSeen"])
    {
        [standardUserDefaults setValue:[NSNumber numberWithBool:NO] forKey:@"reconsentHasBeenSeen"];
    }
    if (![standardUserDefaults objectForKey:@"removedMolesToDiagnoses"])
    {
        [standardUserDefaults setObject:[NSArray array] forKey:@"removedMolesToDiagnoses"];
    }
    
    //Legacy values
    /*
     if (![standardUserDefaults objectForKey:@"firstViewPinButton"])
     {
     [standardUserDefaults setValue:[NSNumber numberWithBool:YES] forKey:@"firstViewPinButton"];
     }
     if (![standardUserDefaults objectForKey:@"firstViewMovePin"])
     {
     [standardUserDefaults setValue:[NSNumber numberWithBool:YES] forKey:@"firstViewMovePin"];
     }
     if (![standardUserDefaults objectForKey:@"firstViewMeasurement"])
     {
     [standardUserDefaults setValue:[NSNumber numberWithBool:YES] forKey:@"firstViewMeasurement"];
     }
     if (![standardUserDefaults objectForKey:@"firstViewCallout"])
     {
     [standardUserDefaults setValue:[NSNumber numberWithBool:YES] forKey:@"firstViewCallout"];
     }
     if (![standardUserDefaults objectForKey:@"shouldShowIntroAndEligible"])
     {
     [standardUserDefaults setValue:[NSNumber numberWithBool:YES] forKey:@"shouldShowIntroAndEligible"];
     }
     */
    
}

//Loads all zones into persistent storage if they don't yet exist there, and sets bool for has image for each zone
//in NSUSERdefaults such that they will appear translucent without photo data.
- (void)loadAllZonesWithContext:(NSManagedObjectContext *)context
{
    NSArray *allZoneIDs = [Zone allZoneIDs];
    for (NSString *zoneID in allZoneIDs)
    {
        [Zone zoneForZoneID:zoneID withZonePhotoFileName:nil inManagedObjectContext:context];
    }    
}

-(void)clearCoreDataStoreOfInvalidMeasurements
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Measurement"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"whichMole" ascending:YES]];
    NSArray *measurementMatches = [self.managedObjectContext executeFetchRequest:request error:nil];
    
    if (!measurementMatches || [measurementMatches count] == 0) {return;}
    
    for (Measurement *measurement in measurementMatches)
    {
        if (measurement.measurementID == nil)
        {
            NSLog(@"Measurement with invalid ID: %@",measurement.whichMole.moleName);
            [self.managedObjectContext deleteObject:measurement];
        }
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
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

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
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
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
    
    //NOTE: THIS MUST HAVE THE SAME NAME AS THE XCDATAMODEL!!!
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"InterfaceTesting" withExtension:@"momd"];
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
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"interfaceTesting.sqlite"];
    
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
