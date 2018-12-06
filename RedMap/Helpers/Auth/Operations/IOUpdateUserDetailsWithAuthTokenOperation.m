//
//  IOUpdateUserDetailsWithAuthTokenOperation.m
//  Redmap
//
//  Created by Evo Stamatov on 9/09/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOUpdateUserDetailsWithAuthTokenOperation.h"
#import "AppDelegate.h"
#import "User.h"
#import "IOAuth.h"
#import "IOSightingsController.h"
#import "IOPhotoCollection.h"
#import "Sighting.h"
#import "User-typedefs.h"
#import "Sighting-typedefs.h"
#import "IOCoreDataHelper.h"
#import "IOFetchSightingDetailsOperation.h"

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface IOUpdateUserDetailsWithAuthTokenOperation ()

@property (nonatomic, copy) NSManagedObjectID *userObjectID;
@property (nonatomic, copy) NSString *authToken;
@property (nonatomic, strong) NSOperationQueue *localQueue;
@property (nonatomic, weak, readwrite) NSManagedObjectContext *context;
@property (nonatomic, weak, readwrite) NSManagedObjectContext *sightingsContext;
@property (nonatomic, strong) NSOperation *remoteOperation;

@end

////////////////////////////////////////////////////////////////////////////////
@implementation IOUpdateUserDetailsWithAuthTokenOperation

- (instancetype)initWithUserObjectID:(NSManagedObjectID *)userObjectID
                           authToken:(NSString *)authToken
                             context:(NSManagedObjectContext *)context
                    sightingsContext:(NSManagedObjectContext *)sightingsContext
                               queue:(NSOperationQueue *)queueOrNil
                              forced:(BOOL)forced
{
    self = [super initWithGlobalQueue:queueOrNil forced:forced];
    if (self)
    {
    logmethod();
        _userObjectID = userObjectID;
        _authToken = authToken;
        _context = context;
        _sightingsContext = sightingsContext;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
- (void)dealloc
{
    logmethod();
#if DEBUG
    DDLogWarn(@"%@: Deallocating", self.class);
#endif
    
    _queue = nil;
    _localQueue = nil;
    _userObjectID = nil;
    
    _sightingsContext = nil;
    _context = nil;
    
    _remoteOperation = nil;
}

////////////////////////////////////////////////////////////////////////////////
- (NSOperationQueue *)localQueue
{
    logmethod();
    if (_localQueue == nil)
    {
        _localQueue = [[NSOperationQueue alloc] init];
        _localQueue.name = @"Update User Details and Sightings Queue";
        _localQueue.maxConcurrentOperationCount = 5;
    }
    return _localQueue;
}

////////////////////////////////////////////////////////////////////////////////
- (void)main
{
    logmethod();
    @autoreleasepool {
        DDLogVerbose(@"%@: Initiating user details update", self.class);
        
        if (self.isCancelled)
            return;
        
        User *user = (User *)[self.context objectWithID:self.userObjectID];
        [self updateDataForUser:user authToken:self.authToken];
    }
}

////////////////////////////////////////////////////////////////////////////////
- (void)cancel
{
    logmethod();
    DDLogError(@"%@: Operation cancelled", self.class);
    
    [self.remoteOperation cancel];
    self.remoteOperation = nil;
    
    [self.localQueue cancelAllOperations];
    
    [super cancel];
}

////////////////////////////////////////////////////////////////////////////////
- (void)updateDataForUser:(User *)user authToken:(NSString *)authToken
{
    logmethod();
    if (self.isCancelled)
        return;
    
    DDLogVerbose(@"%@: Syncing the user's details...", self.class);
    
    __weak __typeof(self)weakSelf = self;
    self.remoteOperation = [RMAPI getUserDetailsUsingAuthToken:authToken completionBlock:^(NSDictionary *details, NSError *error) {
        DDLogVerbose(@"%@: Got the user's details", weakSelf.class);
        
        if (error)
        {
            DDLogError(@"%@: ERROR getting the user's details[%d]: %@", weakSelf.class, error.code, error.localizedDescription);
            [weakSelf finish];
        }
        else
        {
            if (weakSelf.isCancelled)
                return;
    
            // Exception handling in an operation has to be in @try{}@catch{} blocks
            @try {
                // TODO: Move assertion to RMAPI
                NSInteger userID = [[details valueForKey:@"id"] integerValue];
                if (userID == 0)
                    @throw [NSException exceptionWithName:IOAuthExceptionMissingValue reason:@"User ID is missing" userInfo:nil];
                
                NSString *username = [details objectForKey:@"username"];
                if (username == nil)
                    @throw [NSException exceptionWithName:IOAuthExceptionMissingValue reason:@"Username is missing" userInfo:nil];
                if (username.length < 3)
                    @throw [NSException exceptionWithName:IOAuthExceptionValueLengthTooShort reason:@"Username is too short" userInfo:nil];
                if (username.length > 30)
                    @throw [NSException exceptionWithName:IOAuthExceptionValueLengthTooLong reason:@"Username is too long" userInfo:nil];
                
                NSString *email = [details objectForKey:@"email"];
                if (email == nil)
                    @throw [NSException exceptionWithName:IOAuthExceptionMissingValue reason:@"Email is missing" userInfo:nil];
                if (email.length < 5)
                    @throw [NSException exceptionWithName:IOAuthExceptionValueLengthTooShort reason:@"Email is too short" userInfo:nil];
                
                NSString *firstName = [details objectForKey:@"first_name"];
                NSString *lastName = [details objectForKey:@"last_name"];
                
                if (!user)
                {
                    [weakSelf finish];
                    return;
                }
                
                if (weakSelf.isCancelled)
                    return;
                
                // NOTE: NO cancelling beyond this point!
                
                // TODO: Region preference?
                
                user.password = nil;
                user.authToken = authToken;
                user.userID = @(userID);
                user.username = username;
                user.email = email;
                user.firstName = firstName;
                user.lastName = lastName;
                
                //if ([user.status intValue] != IOAuthUserStatusInSyncWithServer)
                user.status = @(IOAuthUserStatusServerAuthenticated);
                
                user.dateModified = [NSDate date]; // now
                
                DDLogVerbose(@"%@: Validating user's details", weakSelf.class);
                NSError *validateError = nil;
                if (![user validateForUpdate:&validateError])
                {
                    NSString *logMessage;
                    switch ([validateError code]) {
                        case NSValidationStringPatternMatchingError:
                            {
                                logMessage = [NSString stringWithFormat:@"Regex matching error for authToken, email (%@), or username (%@)", email, username];
                            }
                            break;
                        default:
                            {
                                logMessage = [NSString stringWithFormat:@"Got an error: %d (look at Core Data Constants Reference/Validation Error Codes)", [validateError code]];
                            }
                            break;
                    }
                    
                    DDLogError(@"%@: ERROR validatiing. [%d]: %@. MyMessage: %@", weakSelf.class, [validateError code], [validateError localizedDescription], logMessage);
                    DDLogWarn(@"%@: WARNING. Should ROLLBACK.", weakSelf.class);
#if TRACK
                    [GoogleAnalytics sendEventWithCategory:@"admin-notification" withAction:@"update-user-validate" withLabel:[validateError localizedDescription] withValue:@1];
#endif
                }
                else
                {
                    DDLogVerbose(@"%@: All good. Saving to store.", weakSelf.class);
                    
                    NSArray *userSightings = [details objectForKey:@"sightings"];
                    if (userSightings.count == 0)
                    {
                        user.status = @(IOAuthUserStatusInSyncWithServer);
                        user.dateModified = [NSDate date]; // now
                    }
                    
                    // save the user
                    [IOCoreDataHelper faultObjectWithID:user.objectID inContext:weakSelf.context];
                    
                    DDLogVerbose(@"%@: Saved to store.", weakSelf.class);
                    
                    //NSArray *userSightings = [details objectForKey:@"sightings"];
                    if (!weakSelf.isCancelled && userSightings.count > 0)
                    {
                        // NOTE: [fetchUserSightings:] will finish the operation when done fetching
                        [weakSelf fetchUserSightings:userSightings];
                    }
                    else
                    {
                        DDLogVerbose(@"%@: User's details are in sync.", weakSelf.class);
                        [weakSelf finish];
                    }
                }
            }
            @catch (NSException *exception) {
                DDLogError(@"%@: EXCEPTION: %@", weakSelf.class, [exception reason]);
                
                [weakSelf finish];
            }
        }
    }];
    
#if DEBUG
    double delayInSeconds = 5.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        DDLogWarn(@"Nil check? %@ (1000) [%@]", weakSelf == nil ? @"YES" : @"NO", @"IOUpdateUserDetailsWithAuthTokenOperation");
    });
#endif
}

////////////////////////////////////////////////////////////////////////////////
- (void)fetchUserSightings:(NSArray *)userSightings
{
    logmethod();
    DDLogVerbose(@"%@: Fetching the user's sightings (%d)", self.class, userSightings.count);
    
    __weak __typeof(self)weakSelf = self;
    
    // create the done operation that will fire the task
    NSBlockOperation *doneOperation = [NSBlockOperation blockOperationWithBlock:^{
        DDLogVerbose(@"%@: Did fetch all user's sightings.", weakSelf.class);
        
        User *user = (User *)[weakSelf.context objectWithID:weakSelf.userObjectID];
        user.status = @(IOAuthUserStatusInSyncWithServer);
        user.dateModified = [NSDate date]; // now
        
        DDLogVerbose(@"%@: Updating user's status in store.", weakSelf.class);
        NSError *validateError = nil;
        if (![user validateForUpdate:&validateError])
        {
            DDLogError(@"%@: ERROR validating. [%d]: %@", weakSelf.class, [validateError code], [validateError localizedDescription]);
            DDLogWarn(@"%@: WARNING. Should ROLLBACK.", weakSelf.class);
        }
        else
        {
            [IOCoreDataHelper faultObjectWithID:user.objectID inContext:weakSelf.context];
            DDLogVerbose(@"%@: Updated in store.", weakSelf.class);
        }
        
        DDLogVerbose(@"%@: User's details are in sync.", weakSelf.class);
        [weakSelf finish];
    }];
    
    @try {
        DDLogVerbose(@"%@: Will fetch all user's sightings", self.class);
        IOSightingsController *sightingsController = [[IOSightingsController alloc] initWithContext:self.sightingsContext];
        
        NSMutableArray *operations = [NSMutableArray arrayWithCapacity:userSightings.count];
        
        for (NSNumber *sighting in userSightings)
        {
            if (self.isCancelled)
                return;
            
            NSOperation *remoteOperation;
            remoteOperation = [[IOFetchSightingDetailsOperation alloc] initWithSightingID:[sighting integerValue]
                                                                                authToken:self.authToken
                                                                      sightingsController:sightingsController
                                                                                  context:self.sightingsContext];
            
            [doneOperation addDependency:remoteOperation];
            [operations addObject:remoteOperation];
        }
        
        if (self.isCancelled)
            return;
        
        [self.localQueue addOperations:operations waitUntilFinished:NO];
        
        // add the done operation to the queue
        [self.localQueue addOperation:doneOperation];
        
        DDLogVerbose(@"%@: Fetching all user's sightings", self.class);
    }
    @catch (NSException *exception) {
        DDLogError(@"%@: EXCEPTION. [%@]: %@", self.class, [exception name], [exception reason]);
        [self.localQueue cancelAllOperations];
        [self finish];
    }
}

@end
