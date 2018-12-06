//
//  IOTests.m
//  Redmap
//
//  Created by Evo Stamatov on 14/03/2014.
//  Copyright (c) 2014 Ionata. All rights reserved.
//

#import "IOTests.h"

#if DEBUG

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

#import "IOOperations.h"
#import "IOSightingsController.h"
#import "IOAuth.h"
#import "User.h"
#import "Sighting.h"
#import "IORegionsController.h"
#import "IOSpeciesController.h"

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;



@interface IOTestAction : NSObject
@property (weak, nonatomic) id target;
@property (assign, nonatomic) SEL action;
@property (strong, nonatomic) void (^delayedBlock)();
@end

@implementation IOTestAction
@end


@implementation IOTests
{
    IOOperations *_ops;
    double _delayFor;
    
    NSMutableArray *_allTests;
    
    NSCondition *_condition;
    NSInteger _conditionPredicate;
    BOOL _shouldLock;
    
    IOTestAction *_currentlyExecutingAction;
}

static IOTests *_sharedInstance;

+ (void)initialize
{
    static BOOL initialized = NO;
    if (!initialized)
    {
        initialized = YES;
        _sharedInstance = [IOTests new];
    }
}

+ (void)doAllTests
{
    IOTests *tests = _sharedInstance;
    [tests setUp];
    [tests doAllTests];
}

- (IOTestAction *)createTestActionForSelector:(SEL)selector
{
    IOTestAction *ta = [IOTestAction new];
    ta.target = self;
    ta.action = selector;
    return ta;
}

- (void)doAllTests
{
    _allTests = [NSMutableArray array];
    
    [_allTests addObject:[self createTestActionForSelector:@selector(test0)]];
    /*
    [_allTests addObject:[self createTestActionForSelector:@selector(test1)]];
    [_allTests addObject:[self createTestActionForSelector:@selector(test2)]];
    [_allTests addObject:[self createTestActionForSelector:@selector(test3)]];
    [_allTests addObject:[self createTestActionForSelector:@selector(test4)]];
    [_allTests addObject:[self createTestActionForSelector:@selector(test5)]];
    [_allTests addObject:[self createTestActionForSelector:@selector(test6)]];
    [_allTests addObject:[self createTestActionForSelector:@selector(test7)]];
    [_allTests addObject:[self createTestActionForSelector:@selector(test8)]];
    [_allTests addObject:[self createTestActionForSelector:@selector(test9)]];
     */
    
    for (IOTestAction *test in _allTests) {
        //if (targetAction.eventMask & myEventMask) {
        
        //[test.target performSelector:test.action];
        IMP imp = [test.target methodForSelector:test.action];
        void (*func)(id, SEL) = (void *)imp;
        
        _currentlyExecutingAction = test;
        
        func(test.target, test.action);
        if (test.delayedBlock)
        {
            test.delayedBlock();
            test.delayedBlock = nil;
        }
        
        _currentlyExecutingAction = nil;
    }
}

- (void)waitToFinish
{
    _condition = [NSCondition new];
    _conditionPredicate = 1000;
    _shouldLock = YES;
    
    if (_shouldLock == NO)
    {
        _condition = nil;
        return;
    }
    
    if (_condition)
    {
        [_condition lock];
        
        while (_conditionPredicate == 1000)
            [_condition wait];
        
        [_condition unlock];
        _condition = nil;
    }
}

- (void)unlock
{
    if (_conditionPredicate == 1000)
    {
        if (_shouldLock)
            _shouldLock = NO;
        
        _conditionPredicate = 0;
        [_condition signal];
    }
}

- (void)setUp
{
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
    
    NSString *serverBase = API_BASE;
    int serverPort = API_PORT;
    RedMapAPIEngine *api = [[RedMapAPIEngine alloc] initWithServerBase:serverBase apiPath:nil andPort:(serverPort == 0 ? nil : @(serverPort))];
#pragma unused(api)
    
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    
    appDelegate.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = [UIColor redColor];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.text = NSLocalizedString(@"Debugging", @"");
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    [label sizeToFit];
    label.center = vc.view.center;
    CGRect frame = label.frame;
    frame.origin.x = (int)frame.origin.x;
    frame.origin.y = (int)frame.origin.y;
    label.frame = frame; // unblur, ha!
    [vc.view addSubview:label];
    
    appDelegate.window.rootViewController = vc;
    [appDelegate.window makeKeyAndVisible];
    
    _delayFor = 3.0f;
    _ops = [IOOperations new];
}

- (void)executeDelayedBlock:(void(^)())block
{
    if (_currentlyExecutingAction)
    {
        double delayInSeconds = _delayFor;
        DDLogVerbose(@"Creating a delayed block, starting in %g second(s)", delayInSeconds);
        _currentlyExecutingAction.delayedBlock = ^{
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                DDLogInfo(@"Executing the delayed block...");
                block();
                DDLogInfo(@"DONE executing the delayed block.");
            });
        };
    }
}

- (void)afterTestSightingAttributesUpdate
{
    __weak __typeof(_ops)weakOps = _ops;
    [self executeDelayedBlock:^{
        DDLogVerbose(@"OPS: %@", weakOps);
        DDLogVerbose(@"Nil check? %@", weakOps.updateSightingAttributesOperation);
    }];
}

- (void)testSightingAttributesUpdate
{
    [_ops updateSightingAttributesForced:NO];
}

- (void)testSightingAttributesUpdateForced
{
    [_ops updateSightingAttributesForced:YES];
}

- (void)testSightingAttributesUpdateCancel
{
    [_ops updateSightingAttributesForced:NO];
    [_ops.updateSightingAttributesOperation cancel];
}

- (void)testSightingAttributesUpdateConcurrency
{
    [_ops updateSightingAttributesForced:YES];
    [_ops updateSightingAttributesForced:YES];
}

- (void)test1
{
    //[_ops updateCategoriesForced:YES];
    //[_ops updateCategoriesForced:YES];
    [_ops updateCategoriesForced:NO];
    [_ops.updateCategoriesOperation cancel];
    
    __weak __typeof(_ops)weakOps = _ops;
    [self executeDelayedBlock:^{
        DDLogVerbose(@"OPS: %@", weakOps);
        DDLogVerbose(@"Nil check? %@", weakOps.updateCategoriesOperation);
        //[weakOps.updateCategoriesOperation cancel];
        //[weakOps updateCategoriesForced:YES];
        [weakOps updateCategoriesForced:NO];
    }];
}

- (void)test2
{
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
    
    __weak __typeof(_ops)weakOps = _ops;
    [self executeDelayedBlock:^{
        DDLogVerbose(@"OPS: %@", weakOps);
        DDLogVerbose(@"Nil check? %@", weakOps.updateSightingAttributesOperation);
        DDLogVerbose(@"Nil check? %@", weakOps.updateCategoriesOperation);
        //[weakOps updateSightingAttributesForced:YES];
        //[weakOps updateCategoriesForced:YES];
        [weakOps updateSightingAttributesForced:NO];
        [weakOps updateCategoriesForced:NO];
    }];
}

- (void)test3
{
    [_ops updateRegionsForced:YES];
    //[_ops updateRegionsForced:YES];
    //[_ops updateRegionsForced:NO];
    [_ops.updateRegionsOperation cancel];
    
    __weak __typeof(_ops)weakOps = _ops;
    [self executeDelayedBlock:^{
        DDLogVerbose(@"OPS: %@", weakOps);
        DDLogVerbose(@"Nil check? %@", weakOps.updateRegionsOperation);
        //[weakOps.updateRegionsOperation cancel];
        //[weakOps updateRegionsForced:YES];
        [weakOps updateRegionsForced:NO];
    }];
}

- (void)test4
{
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
    
    //op = [_ops updateRegionsForced:YES];
    op = [_ops updateRegionsForced:NO];
    [doneOp addDependency:op];
    
    [_ops.queue addOperation:doneOp];
    
    __weak __typeof(_ops)weakOps = _ops;
    [self executeDelayedBlock:^{
        DDLogVerbose(@"OPS: %@", weakOps);
        DDLogVerbose(@"Nil check? %@", weakOps.updateSightingAttributesOperation);
        DDLogVerbose(@"Nil check? %@", weakOps.updateCategoriesOperation);
        DDLogVerbose(@"Nil check? %@", weakOps.updateRegionsOperation);
        [weakOps updateSightingAttributesForced:NO];
        [weakOps updateCategoriesForced:NO];
        [weakOps updateRegionsForced:NO];
    }];
}

- (void)test5
{
    //[_ops updateSpeciesForced:YES];
    //[_ops updateSpeciesForced:YES];
    [_ops updateSpeciesForced:NO];
    [_ops.updateSpeciesOperation cancel];
    
    __weak __typeof(_ops)weakOps = _ops;
    [self executeDelayedBlock:^{
        DDLogVerbose(@"OPS: %@", weakOps);
        DDLogVerbose(@"Nil check? %@", weakOps.updateSpeciesOperation);
        //[weakOps.updateSpeciesOperation cancel];
        //[weakOps updateSpeciesForced:YES];
        [weakOps updateSpeciesForced:NO];
    }];
}

- (void)test6
{
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
    
    //__weak __typeof(_ops)weakOps = _ops;
    //[self executeDelayedBlock:^{}];
}

- (void)test7
{
    [_ops updateCurrentUserAttributesForced:YES];
    //[_ops updateCurrentUserAttributesForced:YES];
    //[_ops updateCurrentUserAttributesForced:NO];
    //[_ops.updateCurrentUserAttributesOperation cancel];
    
    //__weak __typeof(_ops)weakOps = _ops;
    //[self executeDelayedBlock:^{}];
}

- (void)test8
{
    //[[IOAuth sharedInstance] removeCurrentUser];
    User *cu = [[IOAuth sharedInstance] currentUser];
    if (cu)
    {
        NSManagedObjectContext *ct = [[IOCoreDataHelper sharedInstance] context];
        IOSightingsController *sc = [[IOSightingsController alloc] initWithContext:ct userID:cu.userID];
        NSError *fe = nil;
        if ([sc.fetchedResultsController performFetch:&fe])
        {
            //DDLogVerbose(@"Fetched objects: %@", sc.objects);
            Sighting *sigh = [sc.objects objectAtIndex:0];
            
            //DDLogVerbose(@"Sighting %@: %@", sigh.sightingID, sigh);
            
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
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Not logged in. Set a password" userInfo:nil];
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
    
    //__weak __typeof(_ops)weakOps = _ops;
    //[self executeDelayedBlock:^{}];
}

- (void)test9
{
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
    
    BOOL oneOffTest = YES;
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
    
    //__weak __typeof(_ops)weakOps = _ops;
    //[self executeDelayedBlock:^{}];
}

#endif

@end
