//
//  IOUpdateCurrentUserAttributesOperation.m
//  Redmap
//
//  Created by Evo Stamatov on 5/09/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOUpdateCurrentUserAttributesOperation.h"
#import "IOAuth.h"
#import "User.h"
#import "User-typedefs.h"
#import "AppDelegate.h"
#import "Sighting.h"
#import "IOSpeciesController.h"
#import "IOSightingsController.h"
#import "IOUpdateUserDetailsWithAuthTokenOperation.h"

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface IOUpdateCurrentUserAttributesOperation ()
@property (nonatomic, strong) NSOperationQueue *localQueue;
@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation IOUpdateCurrentUserAttributesOperation

- (void)dealloc
{
    logmethod();
    DDLogWarn(@"%@: Deallocating", self.class);
    
    _localQueue = nil;
}

////////////////////////////////////////////////////////////////////////////////
- (void)main
{
    logmethod();
    @autoreleasepool {
        DDLogVerbose(@"%@: Initiating user's attributes update", self.class);
        
        if (self.isCancelled)
            return;
        
        NSString *userDefaultsKey = @"currentUserAttributesUpdateDate";
        User *user = [[IOAuth sharedInstance] currentUser];
        
        if (self.isCancelled)
            return;
        
        if (user == nil)
        {
            DDLogInfo(@"%@: SKIPPING operation - no logged in user", self.class);
            [self finish];
            return;
        }
        else if (user.authToken == nil || user.authToken.length == 0)
        {
            DDLogError(@"%@: ERROR. Current user has no auth token", self.class);
            [self finish];
            return;
        }
        //DDLogVerbose(@"%@: Current user auth token: %@", self.class, user.authToken);
        
        if (self.isCancelled)
            return;
        
        NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
        NSDate *lastSync = [standardDefaults objectForKey:userDefaultsKey];
        
        if (self.isCancelled)
            return;
        
        //IOLog(@"Forced? %@", self.forced ? @"YES" : @"NO");
        
        BOOL outOfSync = NO;
        if (!lastSync)
        {
            DDLogVerbose(@"%@: User's attributes were never synced", self.class);
            outOfSync = YES;
        }
        else if (!self.forced)
        {
            //DDLogVerbose(@"%@: User attributes last sync: %@", self.class, lastSync);
            NSDate *expiryDate = [lastSync dateByAddingTimeInterval:kIOExpiryIntervalForCurrentUsersAttributes];
            if ([expiryDate compare:[NSDate date]] == NSOrderedAscending)
            {
                DDLogVerbose(@"%@: User's attributes last sync is out of date", self.class);
                outOfSync = YES;
            }
        }
        
        //DDLogVerbose(@"%@: Forced after expiry check? %@", self.class, self.forced ? @"YES" : @"NO");
        
        if (self.isCancelled)
            return;
        
        if (self.forced || outOfSync || [user.status intValue] != IOAuthUserStatusInSyncWithServer)
        {
            if (self.isCancelled)
                return;
            
            DDLogVerbose(@"%@: Syncing the user's attributes...", self.class);
            
            IOConcurrentOperation *operation;
            operation = [[IOUpdateUserDetailsWithAuthTokenOperation alloc] initWithUserObjectID:user.objectID
                                                                                      authToken:user.authToken
                                                                                        context:self.context
                                                                               sightingsContext:self.sightingsContext
                                                                                          queue:self.localQueue
                                                                                         forced:self.forced];
            
            __weak __typeof(self)weakSelf = self;
            NSBlockOperation *completionOperation = [NSBlockOperation blockOperationWithBlock:^{
                DDLogVerbose(@"%@: User's attributes are in sync.", weakSelf.class);
                
                [standardDefaults setObject:[NSDate date] forKey:userDefaultsKey];
                [standardDefaults synchronize];
                
                [weakSelf finish];
            }];
            
            [completionOperation addDependency:operation];
            [self.localQueue addOperation:operation];
            [self.localQueue addOperation:completionOperation];
        }
        else
        {
            DDLogVerbose(@"%@: SKIPPING operation - in sync and not out of date", self.class);
            [self finish];
        }
    }
}

////////////////////////////////////////////////////////////////////////////////
- (void)cancel
{
    logmethod();
    DDLogVerbose(@"%@: Operation cancelled", self.class);
    
    [self.localQueue cancelAllOperations];
    self.localQueue = nil;
    
    [super cancel];
}

////////////////////////////////////////////////////////////////////////////////
- (NSOperationQueue *)localQueue
{
    logmethod();
    if (_localQueue == nil)
    {
        _localQueue = [[NSOperationQueue alloc] init];
        _localQueue.name = @"Update Current User Details Queue";
        _localQueue.maxConcurrentOperationCount = 5;
    }
    return _localQueue;
}

@end
