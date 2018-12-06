//
//  AppDelegate.m
//  RedMap
//
//  Created by Evo Stamatov on 25/03/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#define DEBUG_OPERATIONS 0

#import "AppDelegate.h"
#import "IORedMapThemeManager.h"
#import "IOAuthLoginViewController.h"
#import "IOGeoLocation.h"
#import "IOSightingAttributesController.h"
#import "IOPhotoCollection.h"
#import "IOLoggingViewController-defines.h"
#import <DDTTYLogger.h>
#import "IOLogger.h"
#import "IOCoreDataHelper.h"

#if DEBUG_OPERATIONS
#import "IOOperations.h"
#import "IOSightingsController.h"
#import "IOAuth.h"
#import "User.h"
#import "Sighting.h"
#import "IORegionsController.h"
#import "IOSpeciesController.h"
#import "RedMapAPIEngine.h"
#endif

#if DEBUG
#import "Sighting.h"
#include <sys/types.h>
#include <sys/sysctl.h>
#include <mach/machine.h>
#include <mach-o/ldsyms.h>

NSString *getCPUType(void)
{
    NSMutableString *cpu = [[NSMutableString alloc] init];
    size_t size;
    cpu_type_t type;
    cpu_subtype_t subtype;
    size = sizeof(type);
    sysctlbyname("hw.cputype", &type, &size, NULL, 0);

    size = sizeof(subtype);
    sysctlbyname("hw.cpusubtype", &subtype, &size, NULL, 0);

    // values for cputype and cpusubtype defined in mach/machine.h
    if (type == CPU_TYPE_X86)
    {
        [cpu appendString:@"x86 "];
        // check for subtype ...

    } else if (type == CPU_TYPE_ARM)
    {
        [cpu appendString:@"ARM"];
        switch(subtype)
        {
            case CPU_SUBTYPE_ARM_V6:
                [cpu appendString:@"V6"];
                break;
            case CPU_SUBTYPE_ARM_V7:
                [cpu appendString:@"V7"];
                break;
            case CPU_SUBTYPE_ARM_V7F:
                [cpu appendString:@"V7F"];
                break;
            case CPU_SUBTYPE_ARM_V7S:
                [cpu appendString:@"V7S"];
                break;
            case CPU_SUBTYPE_ARM_V8:
                [cpu appendString:@"V8"];
                break;
        }
    }
    return [cpu copy];
}
#endif

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

/*
#if DEBUG
#define EVOS_AUTHTOKEN @"9f60f3513c535e6186d6492f1766dd185cc6e70a"
#endif
 */

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation AppDelegate
{
    BOOL _initialized;
    NSString *_defaultServerBase;
    NSInteger _defaultServerPort;
    BOOL _changingUserDefaults;
#if DEBUG_OPERATIONS
    IOOperations *_ops;
#endif
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Application stack

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#if DEBUG
    int processorType = _mh_execute_header.cputype;
    int processorSubtype = _mh_execute_header.cpusubtype;
    NSLog(@"CPU Type: %d; CPU SubType: %d -- %@", processorType, processorSubtype, getCPUType());
    NSLog(@"Look up CPU Type and SubType in mach/machine.h)");

#if DEBUG_OPERATIONS
    {
        [self debugSetup];
        [self debugOperations];
        return YES;
    }
#endif
#endif
    
    _initialized = NO;
    _changingUserDefaults = NO;

    [self setupUserDefaults];
    
    // Setup the standard logger
#if DEBUG
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
    
    UIColor *infoGreen = [UIColor colorWithRed:0.233 green:0.603 blue:0.395 alpha:1.000];
    [[DDTTYLogger sharedInstance] setForegroundColor:infoGreen backgroundColor:nil forFlag:LOG_FLAG_INFO];
#endif
    
    BOOL loggingEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:kIOUserDefaultsLoggingEnabledKey];
    if (loggingEnabled)
        [[IOLogger sharedInstance] startLogging];
    
    logmethod();
    
    // Setup the API Server settings and logging
    [self onDefaultsChanged:nil];
    
#if DEBUG
    {
        NSManagedObjectContext *ct = [[IOCoreDataHelper sharedInstance] context];
        NSFetchRequest *fr = [[NSFetchRequest alloc] initWithEntityName:@"Sighting"];
        [ct performBlockAndWait:^{
            NSError *fe = nil;
            NSArray *results = [ct executeFetchRequest:fr error:&fe];
            if (!fe && results.count > 0)
            {
                for (Sighting *sigh in results)
                {
                    DDLogVerbose(@"Found sightings %@: %@", sigh.uuid, sigh);
                }
            }
        }];
    }
#endif
    
    [self setupTracking];
    
    [IORedMapThemeManager styleNavigationBarAppearance];
    [IORedMapThemeManager styleSegmentedControlAppearance];
    
    // IOLog(@"Available fonts: %@", [UIFont familyNames]);
    /*
    for (NSString *familyName in [UIFont familyNames]) {
        for (NSString *fontName in [UIFont fontNamesForFamilyName:familyName]) {
            IOLog(@"%@ - %@", familyName, fontName);
        }
    }
     // */
    
    [application setStatusBarHidden:NO];
    
    // Sort out which storyboard to use
//    NSString *storyboardName = (iOS_7_OR_LATER() ? @"MainStoryboard" : @"MainStoryboard-ios6");
//    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:nil];
    
//    DDLogVerbose(@"AppDelegate: Using storyboard: %@", storyboardName);
    
//    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
//    self.window.rootViewController = [storyboard instantiateInitialViewController];
//    [self.window makeKeyAndVisible];
    
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
- (void)applicationWillResignActive:(UIApplication *)application
{
    logmethod();
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

////////////////////////////////////////////////////////////////////////////////
- (void)applicationDidEnterBackground:(UIApplication *)application
{
    logmethod();
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[IOGeoLocation sharedInstance] deactivate];
    
    [[IOCoreDataHelper sharedInstance] saveContext];
}

////////////////////////////////////////////////////////////////////////////////
- (void)applicationWillEnterForeground:(UIApplication *)application
{
    logmethod();
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    BOOL loggingEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:kIOUserDefaultsLoggingEnabledKey];
    if (loggingEnabled)
    {
        if ([[IOLogger sharedInstance] startLogging])
        {
            NSString *message = NSLocalizedString(@"Now you can take the necessary actions to reproduce the issue you want to report and when done, turn Service logging off.\n\nKeep in mind that the app might be slower than usual.", @"");
            UIAlertView *loggingEnabledAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"You have enabled logging", @"")
                                                                              message:message
                                                                             delegate:nil
                                                                    cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                                                    otherButtonTitles:nil];
            [loggingEnabledAlertView show];
        }
    }
    else
    {
        if ([[IOLogger sharedInstance] stopLogging] && [[IOLogger sharedInstance] hasLogs])
        {
            NSString *message = NSLocalizedString(@"Now you can go to the home screen of this very app and at the bottom of the screen you'll find a Send service logs button.", @"");
            UIAlertView *loggingDisabledAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"You have disabled logging", @"")
                                                                               message:message
                                                                              delegate:nil
                                                                     cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                                                     otherButtonTitles:nil];
            [loggingDisabledAlertView show];
        }
    }
}

////////////////////////////////////////////////////////////////////////////////
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    logmethod();
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

////////////////////////////////////////////////////////////////////////////////
- (void)applicationWillTerminate:(UIApplication *)application
{
    logmethod();
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.

    [[IOGeoLocation sharedInstance] deactivate];
    
    //IOLog(@"Terminating the app");
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[IOCoreDataHelper sharedInstance] saveContext];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - API Server settings

- (void)onDefaultsChanged:(NSNotification *)aNotification
{
    logmethod();
    
    if (_changingUserDefaults)
        return;
    
    NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString *currentServerBase = [standardDefaults stringForKey:kIOUserDefaultsServerBaseKey];
    NSInteger currentServerPort = [standardDefaults integerForKey:kIOUserDefaultsServerPortKey];
    
    BOOL veryFirstAppRun = NO;
    if ([currentServerBase isEqualToString:kIOUserDefaultsServerBaseDefault] && currentServerPort == kIOUserDefaultsServerPortDefault)
        veryFirstAppRun = YES;
    
    NSString *serverBase = _defaultServerBase;
    NSInteger serverPort = _defaultServerPort;
    
    BOOL savedServerValuesDoDiffer = ![currentServerBase isEqualToString:serverBase] || currentServerPort != serverPort;
    
    if (!_initialized || savedServerValuesDoDiffer)
    {
        _initialized = YES;
        
        // Initialise the Network Engine -- access it with [RMAPI ...] and don't forget to include either AppDelegate.h or RedMapAPIEngine.h
        self.api = [[RedMapAPIEngine alloc] initWithServerBase:serverBase apiPath:nil andPort:(serverPort == 0 ? nil : @(serverPort))];
        
        // Initialise the Image Engine -- access it through -[ApplicationDelegate.imageEngine ...]
        self.imageEngine = [[ImageEngine alloc] initWithDefaultSettings];
        [self.imageEngine useCache];
    
        // Only remove old DB and update userDefaults if there are differences
        if (savedServerValuesDoDiffer || veryFirstAppRun)
        {
#if TRACK
            [GoogleAnalytics sendEventWithCategory:@"settings" withAction:@"change server" withLabel:serverBase withValue:@(serverPort)];
#endif
            
            if ([[IOCoreDataHelper sharedInstance] reloadStore])
            {
                _changingUserDefaults = YES;
                [[NSUserDefaults standardUserDefaults] setObject:serverBase forKey:kIOUserDefaultsServerBaseKey];
                [[NSUserDefaults standardUserDefaults] setInteger:serverPort forKey:kIOUserDefaultsServerPortKey];
                [[NSUserDefaults standardUserDefaults] synchronize];
                _changingUserDefaults = NO;
                
                if (!veryFirstAppRun)
                {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Attention"
                                                                    message:[NSString stringWithFormat:@"The local database was deleted and the server changed to: %@. You should QUIT the app and start it again.", serverBase]
                                                                   delegate:nil
                                                          cancelButtonTitle:nil
                                                          otherButtonTitles:nil];
                    [alert show];
                }
            }
        }
    }
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Custom methods

- (void)setupTracking
{
#if TRACK
#if DEBUG
    logmethod();
#endif
    // Configure tracker from GoogleService-Info.plist.
//    NSError *configureError;
//    [[GGLContext sharedInstance] configureWithError:&configureError];
//    NSAssert(!configureError, @"Error configuring Google services: %@", configureError);

    [GAI sharedInstance].trackUncaughtExceptions = YES;                         // Optional: automatically send uncaught exceptions to Google Analytics.
    [GAI sharedInstance].dispatchInterval = 20;                                 // Optional: set Google Analytics dispatch interval to e.g. 20 seconds.
    //#if DEBUG
    //[GAI sharedInstance].debug = YES;                                           // Optional: set debug to YES for extra debugging information.
    //#endif
    
    id<GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:GA_TRACKING_ID]; // Create tracker instance.
    if (tracker == nil) {
        DDLogVerbose(@"%@: !!! TRACKING ERROR !!!", self.class);
    }

    [GoogleAnalytics sendEventWithCategory:@"checkpoint" withAction:@"appLoad" withLabel:@"start" withValue:@(YES)];
#else
    DDLogVerbose(@"%@: !!! TRACKING IS OFF !!!", self.class);
#endif
}

////////////////////////////////////////////////////////////////////////////////
- (void)setupUserDefaults
{
    logmethod();
    
    DDLogVerbose(@"%@: setup user defaults", self.class);
    
    _defaultServerBase = API_BASE;
#ifdef API_PORT
    _defaultServerPort = API_PORT;
#else
    _defaultServerPort = kIOUserDefaultsServerPortDefault;
#endif
    
    // Register the user defaults
    NSDictionary *appDefaults = @{
                                  kIOUserDefaultsRegionKey: kIOUserDefaultsRegionAutodetect,
                                  kIOUserDefaultsModeKey: @(DEFAULT_MODE),
                                  kIOUserDefaultsServerBaseKey: kIOUserDefaultsServerBaseDefault,
                                  kIOUserDefaultsServerPortKey: @(kIOUserDefaultsServerPortDefault),
                                  kIOUserDefaultsLoggingEnabledKey: @NO,
                                  };
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Monitor user defaults for changes
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDefaultsChanged:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
}

#if DEBUG
- (void)debugSetup
{
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
    UIColor *infoGreen = [UIColor colorWithRed:0.233 green:0.603 blue:0.395 alpha:1.000];
    [[DDTTYLogger sharedInstance] setForegroundColor:infoGreen backgroundColor:nil forFlag:LOG_FLAG_INFO];
    
    NSString *serverBase = API_BASE;
    int serverPort = API_PORT;
    RedMapAPIEngine *api = [[RedMapAPIEngine alloc] initWithServerBase:serverBase apiPath:nil andPort:(serverPort == 0 ? nil : @(serverPort))];
#pragma unused(api)
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = [UIColor redColor];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.text = NSLocalizedString(@"Debugging", @"");
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    [label sizeToFit];
    label.center = vc.view.center;
    [vc.view addSubview:label];
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
}

#if DEBUG_OPERATIONS
- (void)debugOperations
{
    _ops = [IOOperations new];
    double _delayFor = 1.0f;
    __block void (^_delayedBlock)();
    
#if DEBUG_OPERATIONS == 1
    [_ops updateSightingAttributesForced:YES];
    //[_ops updateSightingAttributesForced:YES];
    //[_ops updateSightingAttributesForced:NO];
    //[_ops.updateSightingAttributesOperation cancel];
    _delayedBlock = ^{
        DDLogVerbose(@"OPS: %@", _ops);
        DDLogVerbose(@"Nil check? %@", _ops.updateSightingAttributesOperation);
        //[_ops.updateSightingAttributesOperation cancel];
        [_ops updateSightingAttributesForced:YES];
        //[_ops updateSightingAttributesForced:NO];
    };
#elif DEBUG_OPERATIONS == 2
    [_ops updateCategoriesForced:YES];
    //[_ops updateCategoriesForced:YES];
    //[_ops updateCategoriesForced:NO];
    //[_ops.updateCategoriesOperation cancel];
    _delayedBlock = ^{
        DDLogVerbose(@"OPS: %@", _ops);
        DDLogVerbose(@"Nil check? %@", _ops.updateCategoriesOperation);
        //[_ops.updateCategoriesOperation cancel];
        //[_ops updateCategoriesForced:YES];
        [_ops updateCategoriesForced:NO];
    };
#elif DEBUG_OPERATIONS == 3
    NSOperation *doneOp = [NSBlockOperation blockOperationWithBlock:^{
        DDLogWarn(@"===============================");
        DDLogWarn(@"Done with all queued operations");
        DDLogWarn(@"===============================");
        DDLogVerbose(@"Queue operations cound: %d (has to be 1)", _ops.queue.operationCount);
    }];
    
    NSOperation *op;
    //op = [_ops updateSightingAttributesForced:YES];
    op = [_ops updateSightingAttributesForced:NO];
    [doneOp addDependency:op];
    
    //op = [_ops updateCategoriesForced:YES];
    op = [_ops updateCategoriesForced:NO];
    [doneOp addDependency:op];
    
    [_ops.queue addOperation:doneOp];
    
    _delayedBlock = ^{
        DDLogVerbose(@"OPS: %@", _ops);
        DDLogVerbose(@"Nil check? %@", _ops.updateSightingAttributesOperation);
        DDLogVerbose(@"Nil check? %@", _ops.updateCategoriesOperation);
#if 0
        [_ops updateSightingAttributesForced:YES];
        [_ops updateCategoriesForced:YES];
#else
        [_ops updateSightingAttributesForced:NO];
        [_ops updateCategoriesForced:NO];
#endif
    };
#elif DEBUG_OPERATIONS == 4
    [_ops updateRegionsForced:YES];
    //[_ops updateRegionsForced:YES];
    //[_ops updateRegionsForced:NO];
    //[_ops.updateRegionsOperation cancelAllDependencies];
    //[_ops.updateRegionsOperation cancel];
    
    _delayedBlock = ^{
        DDLogVerbose(@"OPS: %@", _ops);
        DDLogVerbose(@"Nil check? %@", _ops.updateRegionsOperation);
        //[_ops.updateRegionsOperation cancel];
        //[_ops updateRegionsForced:YES];
        [_ops updateRegionsForced:NO];
    };
#elif DEBUG_OPERATIONS == 5
    NSOperation *doneOp = [NSBlockOperation blockOperationWithBlock:^{
        DDLogWarn(@"===============================");
        DDLogWarn(@"Done with all queued operations");
        DDLogWarn(@"===============================");
        DDLogVerbose(@"Queue operations cound: %d (has to be 1)", _ops.queue.operationCount);
    }];
    
    NSOperation *op;
    op = [_ops updateSightingAttributesForced:YES];
    op = [_ops updateSightingAttributesForced:NO];
    [doneOp addDependency:op];
    
    op = [_ops updateCategoriesForced:YES];
    op = [_ops updateCategoriesForced:NO];
    [doneOp addDependency:op];
    
    op = [_ops updateRegionsForced:YES];
    op = [_ops updateRegionsForced:NO];
    [doneOp addDependency:op];
    
    [_ops.queue addOperation:doneOp];
    
    _delayFor = 5.0;
    _delayedBlock = ^{
        DDLogVerbose(@"OPS: %@", _ops);
        DDLogVerbose(@"Nil check? %@", _ops.updateSightingAttributesOperation);
        DDLogVerbose(@"Nil check? %@", _ops.updateCategoriesOperation);
        DDLogVerbose(@"Nil check? %@", _ops.updateRegionsOperation);
        [_ops updateSightingAttributesForced:NO];
        [_ops updateCategoriesForced:NO];
        [_ops updateRegionsForced:NO];
    };
#elif DEBUG_OPERATIONS == 6
    //[_ops updateSpeciesForced:YES];
    //[_ops updateSpeciesForced:YES];
    [_ops updateSpeciesForced:NO];
    [_ops.updateSpeciesOperation cancelAllDependencies];
    [_ops.updateSpeciesOperation cancel];
    
    _delayedBlock = ^{
        DDLogVerbose(@"OPS: %@", _ops);
        DDLogVerbose(@"Nil check? %@", _ops.updateSpeciesOperation);
        //[_ops.updateSpeciesOperation cancel];
        //[_ops updateSpeciesForced:YES];
        [_ops updateSpeciesForced:NO];
    };
#elif DEBUG_OPERATIONS == 7
    NSOperation *doneOp = [NSBlockOperation blockOperationWithBlock:^{
        DDLogWarn(@"===============================");
        DDLogWarn(@"Done with all queued operations");
        DDLogWarn(@"===============================");
        DDLogVerbose(@"Queue operations cound: %d (has to be 1)", _ops.queue.operationCount);
    }];
    
    NSOperation *op;
    op = [_ops updateSightingAttributesForced:YES];
    op = [_ops updateSightingAttributesForced:NO];
    [doneOp addDependency:op];
    
    op = [_ops updateCategoriesForced:YES];
    op = [_ops updateCategoriesForced:NO];
    [doneOp addDependency:op];
    
    op = [_ops updateRegionsForced:YES];
    op = [_ops updateRegionsForced:NO];
    [doneOp addDependency:op];
    
    op = [_ops updateSpeciesForced:YES];
    op = [_ops updateSpeciesForced:NO];
    [doneOp addDependency:op];
    
    [_ops.queue addOperation:doneOp];
    
    //_delayedBlock = ^{ };
#elif DEBUG_OPERATIONS == 8
    NSOperation *doneOp = [NSBlockOperation blockOperationWithBlock:^{
        DDLogWarn(@"===============================");
        DDLogWarn(@"Done with all queued operations");
        DDLogWarn(@"===============================");
        DDLogVerbose(@"Queue operations cound: %d (has to be 1)", _ops.queue.operationCount);
    }];
    NSOperation *op;
    op = [_ops updateCurrentUserAttributesForced:YES];
    //op = [_ops updateCurrentUserAttributesForced:YES];
    //op = [_ops updateCurrentUserAttributesForced:NO];
    //[_ops.updateCurrentUserAttributesOperation cancel];
    [doneOp addDependency:op];
    [_ops.queue addOperation:doneOp];
    //_delayedBlock = ^{ };
#elif DEBUG_OPERATIONS == 9
    //[[IOAuth sharedInstance] removeCurrentUser];
    User *cu = [[IOAuth sharedInstance] currentUser];
    if (cu)
    {
        NSManagedObjectContext *ct = [[IOCoreDataHelper sharedInstance] context];
        IOSightingsController *sc = [[IOSightingsController alloc] initWithContext:ct userID:cu.userID];
        NSError *fe = nil;
        if ([sc.fetchedResultsController performFetch:&fe])
        {
            DDLogVerbose(@"Fetched objects: %@", sc.objects);
            Sighting *sigh = [sc.objects objectAtIndex:0];
            
            DDLogVerbose(@"Sighting %@: %@", sigh.sightingID, sigh);
            
            NSOperation *doneOp = [NSBlockOperation blockOperationWithBlock:^{
                DDLogWarn(@"===============================");
                DDLogWarn(@"Done with all queued operations");
                DDLogWarn(@"===============================");
                DDLogVerbose(@"Queue operations cound: %d (has to be 1)", _ops.queue.operationCount);
            }];
            NSOperation *op;
            op = [_ops checkAndUploadAPendingSightingWihtID:sigh.objectID showingUploadProgress:YES];
            //op = [_ops checkAndUploadAPendingSightingWihtID:nil showingUploadProgress:YES];
            [doneOp addDependency:op];
            [_ops.queue addOperation:doneOp];
        }
    }
    else
    {
        NSString *pass;
        if (!pass)
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Set a password" userInfo:nil];
        [[IOAuth sharedInstance] loginUserWithUsername:@"avioli" password:pass completionBlock:^(BOOL success, NSError *error) {
            if (success)
                DDLogWarn(@"Logged in. Re-start the app");
            else
            {
                [[IOAuth sharedInstance] removeCurrentUser];
                DDLogError(@"ERROR logging in: %@", error);
            }
        }];
    }
    //[_ops checkAndUploadAPendingSightingWihtID: showingUploadProgress:YES];
#elif DEBUG_OPERATIONS == 10
    void (^createASighting)(BOOL, BOOL) = ^(BOOL automaticallySend, BOOL alwaysCreate){
        
        NSManagedObjectContext *ct = [[IOCoreDataHelper sharedInstance] context];
        NSFetchRequest *fr = [[NSFetchRequest alloc] initWithEntityName:@"Sighting"];
        NSPredicate *pr = [NSPredicate predicateWithFormat:@"(status = %@)", @(IOSightingStatusDraft)];
        fr.predicate = pr;
        __block Sighting *sigh;
        DDLogVerbose(@"Looking for draft sightings...");
        [ct performBlockAndWait:^{
            NSError *fe = nil;
            NSArray *results = [ct executeFetchRequest:fr error:&fe];
            if (!fe && results.count > 0)
            {
                sigh = [results lastObject];
                DDLogVerbose(@"Found draft sighting %@: %@", sigh.uuid, sigh);
            }
        }];
        if (!alwaysCreate && !sigh)
        {
            DDLogVerbose(@"No draft sightings found.");
            DDLogVerbose(@"Looking for saved sightings...");
            NSFetchRequest *fr = [[NSFetchRequest alloc] initWithEntityName:@"Sighting"];
            NSPredicate *pr = [NSPredicate predicateWithFormat:@"(status = %@)", @(IOSightingStatusSaved)];
            fr.predicate = pr;
            [ct performBlockAndWait:^{
                NSError *fe = nil;
                NSArray *results = [ct executeFetchRequest:fr error:&fe];
                if (!fe && results.count > 0)
                {
                    sigh = [results lastObject];
                    if (results.count > 1)
                        DDLogVerbose(@"Found %d unsubmitted sightings.", results.count);
                    DDLogVerbose(@"Found saved sighting %@: %@", sigh.uuid, sigh);
                }
            }];

        }
        if (!sigh)
        {
            if (!alwaysCreate)
                DDLogVerbose(@"No saved sightings found.");
            DDLogVerbose(@"Creating a new sighting...");
            sigh = [NSEntityDescription insertNewObjectForEntityForName:@"Sighting" inManagedObjectContext:ct];
            sigh.uuid = [[NSUUID UUID] UUIDString];
            sigh.status = @(IOSightingStatusDraft);
            User *cu = [[IOAuth sharedInstance] currentUser];
            if (cu)
                sigh.user = cu;
            NSError *ve = nil;
            if (![sigh validateForInsert:&ve])
            {
                DDLogError(@"ERROR validating: [%d]: %@", ve.code, ve.localizedDescription);
                [IOCoreDataHelper showValidationError:ve];
                DDLogVerbose(@"Deleting the invalid sighting.");
                [ct performBlockAndWait:^{
                    [ct deleteObject:sigh];
                    sigh = nil;
                }];
            }
            else
            {
                DDLogVerbose(@"Created a new BLANK sighting %@: %@", sigh.uuid, sigh);
            }
        }
        if (sigh)
        {
            //sigh.speciesWeight = @(maxSpeciesWeight + 1);
            //sigh.speciesLength = @(maxSpeciesLength + 1);
            //sigh.depth = @(maxDepth + 1);
            //sigh.waterTemperature = @(maxWaterTemperature + 1);

            NSError *validationError = nil;
            if (![IOAuth validateSightingObjectForSubmission:sigh.objectID context:ct error:&validationError])
            {
                DDLogVerbose(@"Validation error: %@", validationError);
                if (!sigh.region)
                {
                    IORegionsController *rc = [[IORegionsController alloc] initWithContext:ct searchString:@"tas"];
                    NSError *fe = nil;
                    if ([rc.fetchedResultsController performFetch:&fe])
                    {
                        if (rc.objects.count > 0)
                        {
                            DDLogVerbose(@"Using region: %@", [rc.objects lastObject]);
                            sigh.region = [rc.objects lastObject];
                            [IOCoreDataHelper faultObjectWithID:sigh.objectID inContext:ct];
                        }
                        else
                            DDLogError(@"No regions found");
                    }
                    else
                    {
                        DDLogError(@"Error fetching: %@", fe);
                    }
                }
                
                if (!sigh.species)
                {
                    IOSpeciesController *sc = [[IOSpeciesController alloc] initWithContext:ct region:sigh.region category:nil searchString:nil];
                    NSError *fe = nil;
                    if ([sc.fetchedResultsController performFetch:&fe])
                    {
                        if (sc.objects.count > 0)
                        {
                            DDLogVerbose(@"Using species: %@", [sc.objects lastObject]);
                            sigh.species = [sc.objects lastObject];
                            [IOCoreDataHelper faultObjectWithID:sigh.objectID inContext:ct];
                        }
                        else
                            DDLogError(@"No species found");
                    }
                    else
                        DDLogError(@"Error fetching: %@", fe);

                }
                
                // TODO: test with other species
                
                if (!sigh.dateSpotted)
                {
                    DDLogVerbose(@"Setting date spotted to NOW");
                    sigh.dateSpotted = [NSDate date];
                    [IOCoreDataHelper faultObjectWithID:sigh.objectID inContext:ct];
                    
                    // TODO: test with past submissions
                    // TODO: test with future submissions
                }
                
                if (!sigh.time)
                {
                    id defaultTime = [[IOSightingAttributesController sharedInstance] defaultTime];
                    DDLogVerbose(@"Setting time spotted to default value: %@", defaultTime);
                    sigh.time = defaultTime;
                    [IOCoreDataHelper faultObjectWithID:sigh.objectID inContext:ct];
                }
                
                //DDLogVerbose(@"Location Status: %@", sigh.locationStatus);
                //DDLogVerbose(@"Location Latitide: %@", sigh.locationLat);
                //DDLogVerbose(@"Location Longitude: %@", sigh.locationLng);
                //DDLogVerbose(@"Location Accuracy: %@", sigh.locationAccuracy);
                
                if ([sigh.locationStatus integerValue] == IOSightingLocationStatusNotSet)
                {
                    id defaultAccuracy = [[IOSightingAttributesController sharedInstance] defaultAccuracy];
                    DDLogVerbose(@"Setting location with accuracy: %@", defaultAccuracy);
                    sigh.locationAccuracy = defaultAccuracy;
                    sigh.locationLat = @(-43.117651);
                    sigh.locationLng = @(147.546387);
                    sigh.locationStatus = @(IOSightingLocationStatusManuallySet);
                    [IOCoreDataHelper faultObjectWithID:sigh.objectID inContext:ct];
                    
                    // TODO: test with location outside of sigh.region boundaries
                }
                
                //DDLogVerbose(@"Activity: %@", sigh.activity);
                if (!sigh.activity)
                {
                    id defaultActivity = [[IOSightingAttributesController sharedInstance] defaultActivity];
                    DDLogVerbose(@"Setting activity to default value: %@", defaultActivity);
                    sigh.activity = defaultActivity;
                    [IOCoreDataHelper faultObjectWithID:sigh.objectID inContext:ct];
                }
                
                if (!sigh.speciesCount)
                {
                    id defaultSpeciesCount = [[IOSightingAttributesController sharedInstance] defaultCount];
                    DDLogVerbose(@"Setting species count to default value: %@", defaultSpeciesCount);
                    sigh.speciesCount = defaultSpeciesCount;
                    [IOCoreDataHelper faultObjectWithID:sigh.objectID inContext:ct];
                }
                
                if (!sigh.speciesSex)
                {
                    id defaultSpeciesGender = [[IOSightingAttributesController sharedInstance] defaultGender];
                    DDLogVerbose(@"Setting species gender to default value: %@", defaultSpeciesGender);
                    sigh.speciesSex = defaultSpeciesGender;
                    [IOCoreDataHelper faultObjectWithID:sigh.objectID inContext:ct];
                }
                
                if ([sigh.photosCount integerValue] <= 0)
                {
                    DDLogVerbose(@"Creating a dummy photo for the sighting");
                    UIImage *image = [UIImage imageNamed:@"helping-background@2x.jpg"];
                    if (!image)
                    {
                        DDLogError(@"Unable to find a suitable dummy photo to use for the sighting");
                    }
                    else
                    {
                        NSError *se = nil;
                        NSURL *imagePath = [IOPhoto saveImage:image forUUID:sigh.uuid withIndex:1 error:&se];
                        if (se)
                        {
                            DDLogError(@"Error saving the photo: %@", se);
                        }
                        else
                        {
                            if ([imagePath isFileURL])
                            {
                                DDLogVerbose(@"Saved a local dummy photo for the sighting at: %@", [imagePath path]);
                                sigh.photosCount = @(1);
                                [IOCoreDataHelper faultObjectWithID:sigh.objectID inContext:ct];
                            }
                            else
                            {
                                DDLogError(@"Saved photo file with wrong scheme: %@", [imagePath scheme]);
                            }
                        }
                    }
                }
                
                DDLogVerbose(@"DONE creating a new sighting.");
                
                NSError *validationError = nil;
                if (![IOAuth validateSightingObjectForSubmission:sigh.objectID context:ct error:&validationError])
                {
                    DDLogVerbose(@"Validation error: %@", validationError);
                }
                else
                {
                    sigh.status = @(IOSightingStatusSaved);
                    [IOCoreDataHelper faultObjectWithID:sigh.objectID inContext:ct];
                    
                    if (automaticallySend)
                    {
                        DDLogVerbose(@"Sending sighting");
                        [IOCoreDataHelper faultObjectWithID:sigh.objectID inContext:ct];
                        [_ops checkAndUploadAPendingSightingWihtID:sigh.objectID showingUploadProgress:YES];
                        //[_ops checkAndUploadAPendingSightingWihtID:sigh.objectID showingUploadProgress:NO];
                    }
                    else
                    {
                        DDLogVerbose(@"QUIT the app and start it again to submit the sighting.");
                    }
                }
            }
            else
            {
                if (automaticallySend) {
                    if ([sigh.status integerValue] != IOSightingStatusSaved)
                    {
                        DDLogVerbose(@"Setting sighting status to saved");
                        sigh.status = @(IOSightingStatusSaved);
                    }
                    [IOCoreDataHelper faultObjectWithID:sigh.objectID inContext:ct];
                    [_ops checkAndUploadAPendingSightingWihtID:sigh.objectID showingUploadProgress:YES];
                    //[_ops checkAndUploadAPendingSightingWihtID:sigh.objectID showingUploadProgress:NO];
                }
                else
                    DDLogVerbose(@"Skipping submission. Automatically sending is turned off.");
            }
        }
    };
    
    BOOL oneOffTest = NO;
    if (oneOffTest)
    {
        DDLogVerbose(@"One off test - a single sighting creation and submission.");
        createASighting(YES, NO); // auto send
    }
    else
    {
        DDLogVerbose(@"Multiple sightings' creation and submitting test.");
        createASighting(NO, YES); // just create
        createASighting(NO, YES); // just create
        createASighting(NO, YES); // just create
        createASighting(YES, NO); // send
    }
    
    //_delayedBlock = ^{ };
#elif DEBUG_OPERATIONS == 11
    [[IOAuth sharedInstance] registerUserFromFacebookWithCompletionBlock:^(BOOL success, NSError *error) {
        
    }];
#else
    [[[UIAlertView alloc] initWithTitle:@"There are no debug operations with this value" message:nil delegate:nil cancelButtonTitle:@"Duh!" otherButtonTitles:nil] show];
#endif
    
    if (_delayedBlock)
    {
        double delayInSeconds = _delayFor;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            DDLogInfo(@"Executing the delayed block...");
            _delayedBlock();
            DDLogInfo(@"DONE executing the delayed block.");
            _delayedBlock = nil;
        });
    }
}
#endif
#endif

@end
