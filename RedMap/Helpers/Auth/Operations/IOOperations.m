//
//  IOPendingOperations.m
//  Redmap
//
//  Created by Evo Stamatov on 5/09/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOOperations.h"
#import "IOUpdateSightingAttributesOperation.h"
#import "IOUpdateCategoriesOperation.h"
#import "IOUpdateRegionsOperation.h"
#import "IOUpdateSpeciesOperation.h"
#import "IOUpdateCurrentUserAttributesOperation.h"

#import "IOUploadAPendingSighting.h"

#import "IOCoreDataHelper.h"

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;


@interface IOOperations ()

@property (nonatomic, strong, readwrite) NSOperationQueue *queue;

@property (nonatomic, strong, readwrite) IOConcurrentOperation *updateSightingAttributesOperation;
@property (nonatomic, strong, readwrite) IOConcurrentOperation *updateCategoriesOperation;
@property (nonatomic, strong, readwrite) IOConcurrentOperation *updateRegionsOperation;
@property (nonatomic, strong, readwrite) IOConcurrentOperation *updateSpeciesOperation;
@property (nonatomic, strong, readwrite) IOConcurrentOperation *updateCurrentUserAttributesOperation;

@property (nonatomic, strong, readwrite) IOConcurrentOperation *uploadAPendingSightingOperation;

@end


////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation IOOperations

////////////////////////////////////////////////////////////////////////////////
- (NSOperationQueue *)queue
{
    logmethod();
    if (!_queue)
    {
        _queue = [[NSOperationQueue alloc] init];
        _queue.name = @"Operations Queue";
        _queue.maxConcurrentOperationCount = 5;
    }
    return _queue;
}

////////////////////////////////////////////////////////////////////////////////
// TODO: this doesn't work with the current locking we are using within the update* operations
/*!
 * Blocks the thread until all operations have finished
 */
/*
- (void)waitUntilAllOperationsAreFinished
{
    [_queue waitUntilAllOperationsAreFinished];
}
 */

////////////////////////////////////////////////////////////////////////////////
- (void)dealloc
{
    logmethod();
    DDLogWarn(@"%@: Deallocating", self.class);
    
    _updateSightingAttributesOperation = nil;
    _updateCategoriesOperation = nil;
    _updateRegionsOperation = nil;
    _updateSpeciesOperation = nil;
    _updateCurrentUserAttributesOperation = nil;
    
    if (_queue.operationCount > 0)
        DDLogError(@"%@: There are %d pending/running operations in the queue which will be cancelled now. Retain the IOOperations object, until these finish.", self.class, _queue.operationCount);
    [_queue cancelAllOperations];
    _queue = nil;
}

////////////////////////////////////////////////////////////////////////////////
- (NSOperation *)updateSightingAttributesForced:(BOOL)forced
{
    logmethod();
    if (self.updateSightingAttributesOperation != nil)
        return self.updateSightingAttributesOperation;
    
#if DEBUG
    DDLogVerbose(@"-----------------------------");
#endif
    
    DDLogVerbose(@"%@: Enqueuing a sighting attributes update operation", self.class);
    IOUpdateSightingAttributesOperation *operation;
    operation = [[IOUpdateSightingAttributesOperation alloc] initWithGlobalQueue:nil forced:forced];
    
    __weak __typeof(self)weakSelf = self;
    __weak __typeof(_queue)weakQueue = _queue;
    operation.completionBlock = ^{
#if DEBUG
        DDLogError(@"%@: Calling the Sighting Attributes Operation completionBlock.", weakSelf.class);
#endif
        DDLogVerbose(@"%@: Releasing Sighting Attributes update operation", weakSelf.class);
        DDLogVerbose(@"%@: Queue operations count: %d", weakSelf.class, weakQueue.operationCount);
        weakSelf.updateSightingAttributesOperation = nil;
#if DEBUG
        DDLogVerbose(@"=============================");
#endif
    };
    
    self.updateSightingAttributesOperation = operation;
    [self.queue addOperation:operation];
    
    return operation;
}

////////////////////////////////////////////////////////////////////////////////
- (NSOperation *)updateCategoriesForced:(BOOL)forced
{
    logmethod();
    if (self.updateCategoriesOperation != nil)
        return self.updateCategoriesOperation;
    
#if DEBUG
    DDLogVerbose(@"-----------------------------");
#endif
    
    DDLogVerbose(@"%@: Enqueuing a categories update operation", self.class);
    IOUpdateCategoriesOperation *operation;
    operation = [[IOUpdateCategoriesOperation alloc] initWithGlobalQueue:self.queue forced:forced];
    operation.context = [[IOCoreDataHelper sharedInstance] importContext];
    
    __weak __typeof(self)weakSelf = self;
    __weak __typeof(_queue)weakQueue = _queue;
    operation.completionBlock = ^{
#if DEBUG
        DDLogError(@"%@: Calling the Categories Operation completionBlock.", weakSelf.class);
#endif
        DDLogVerbose(@"%@: Releasing Categories update operation", weakSelf.class);
        DDLogVerbose(@"%@: Queue operations count: %d", weakSelf.class, weakQueue.operationCount);
        weakSelf.updateCategoriesOperation = nil;
#if DEBUG
        DDLogVerbose(@"=============================");
#endif
    };
    
    self.updateCategoriesOperation = operation;
    [self.queue addOperation:operation];
    
    return operation;
}

////////////////////////////////////////////////////////////////////////////////
- (NSOperation *)updateRegionsForced:(BOOL)forced
{
    logmethod();
    if (self.updateRegionsOperation != nil)
        return self.updateRegionsOperation;
    
#if DEBUG
    DDLogVerbose(@"-----------------------------");
#endif
    
    DDLogVerbose(@"%@: Enqueuing a regions update operation", self.class);
    IOUpdateRegionsOperation *operation;
    operation = [[IOUpdateRegionsOperation alloc] initWithGlobalQueue:self.queue forced:forced];
    operation.context = [[IOCoreDataHelper sharedInstance] importContext];
    
    __weak __typeof(self)weakSelf = self;
    __weak __typeof(_queue)weakQueue = _queue;
    operation.completionBlock = ^{
#if DEBUG
        DDLogError(@"%@: Calling the Regions Operation completionBlock.", weakSelf.class);
#endif
        DDLogVerbose(@"%@: Releasing Regions update operation", weakSelf.class);
        DDLogVerbose(@"%@: Queue operations count: %d", weakSelf.class, weakQueue.operationCount);
        weakSelf.updateRegionsOperation = nil;
#if DEBUG
        DDLogVerbose(@"=============================");
#endif
    };
    
    [operation addDependency:[self updateCategoriesForced:NO]];
    
    self.updateRegionsOperation = operation;
    [self.queue addOperation:operation];
    
    return operation;
}

////////////////////////////////////////////////////////////////////////////////
- (NSOperation *)updateSpeciesForced:(BOOL)forced
{
    logmethod();
    if (self.updateSpeciesOperation != nil)
        return self.updateSpeciesOperation;
    
#if DEBUG
    DDLogVerbose(@"-----------------------------");
#endif
    
    DDLogVerbose(@"%@: Enqueuing a species update operation", self.class);
    IOUpdateSpeciesOperation *operation;
    operation = [[IOUpdateSpeciesOperation alloc] initWithGlobalQueue:self.queue forced:forced];
    operation.context = [[IOCoreDataHelper sharedInstance] importContext];
    
    __weak __typeof(self)weakSelf = self;
    __weak __typeof(_queue)weakQueue = _queue;
    operation.completionBlock = ^{
#if DEBUG
        DDLogError(@"%@: Calling the Species Operation completionBlock.", weakSelf.class);
#endif
        DDLogVerbose(@"%@: Releasing Species update operation", weakSelf.class);
        DDLogVerbose(@"%@: Queue operations count: %d", weakSelf.class, weakQueue.operationCount);
        weakSelf.updateSpeciesOperation = nil;
#if DEBUG
        DDLogVerbose(@"=============================");
#endif
    };
    
    [operation addDependency:[self updateCategoriesForced:NO]];
    [operation addDependency:[self updateRegionsForced:NO]];
    
    self.updateSpeciesOperation = operation;
    [self.queue addOperation:operation];
    
    return operation;
}

////////////////////////////////////////////////////////////////////////////////
- (NSOperation *)updateCurrentUserAttributesForced:(BOOL)forced
{
    logmethod();
    if (self.updateCurrentUserAttributesOperation != nil)
        return self.updateCurrentUserAttributesOperation;
    
#if DEBUG
    DDLogVerbose(@"-----------------------------");
#endif
    
    DDLogVerbose(@"%@: Enqueuing a current user attributes update operation", self.class);
    IOUpdateCurrentUserAttributesOperation *operation;
    operation = [[IOUpdateCurrentUserAttributesOperation alloc] initWithGlobalQueue:self.queue forced:forced];
    operation.context = [[IOCoreDataHelper sharedInstance] context];
    operation.sightingsContext = [[IOCoreDataHelper sharedInstance] importContext];
    
    __weak __typeof(self)weakSelf = self;
    __weak __typeof(_queue)weakQueue = _queue;
    operation.completionBlock = ^{
#if DEBUG
        DDLogError(@"%@: Calling the Current User Attributes Operation completionBlock.", weakSelf.class);
#endif
        DDLogVerbose(@"%@: Releasing Current User Attributes update operation", weakSelf.class);
        DDLogVerbose(@"%@: Queue operations count: %d", weakSelf.class, weakQueue.operationCount);
        weakSelf.updateCurrentUserAttributesOperation = nil;
#if DEBUG
        DDLogVerbose(@"=============================");
#endif
    };
    
    [operation addDependency:[self updateSightingAttributesForced:NO]];
    [operation addDependency:[self updateCategoriesForced:NO]];
    [operation addDependency:[self updateSpeciesForced:NO]];
    
    self.updateCurrentUserAttributesOperation = operation;
    [self.queue addOperation:operation];
    
    return operation;
}

////////////////////////////////////////////////////////////////////////////////
- (NSOperation *)checkAndUploadAPendingSightingWihtID:(NSManagedObjectID *)sightingID showingUploadProgress:(BOOL)showUploadProgress
{
    logmethod();
    return [self checkAndUploadAPendingSightingWihtID:sightingID showingUploadProgress:showUploadProgress counter:0];
}

////////////////////////////////////////////////////////////////////////////////
- (NSOperation *)checkAndUploadAPendingSightingWihtID:(NSManagedObjectID *)sightingID showingUploadProgress:(BOOL)showUploadProgress counter:(int)counter
{
    logmethod();
#if DEBUG
    DDLogVerbose(@"-----------------------------");
#endif
    
    DDLogVerbose(@"%@: Enqueuing a check and upload sighting operation", self.class);
    
    if (self.uploadAPendingSightingOperation)
    {
        if (showUploadProgress && sightingID)
        {
            DDLogInfo(@"%@: Another upload is in progress. CANCELLING IT.", self.class);
            [self.uploadAPendingSightingOperation cancel];
        }
        else
        {
            DDLogInfo(@"%@: Another upload is in progress. ENQUEUEING the new one.", self.class);
            return self.uploadAPendingSightingOperation;
        }
        
        /*
        NSString *message = NSLocalizedString(@"Another upload is in progress. This one is now queued to start afterwards.", @"");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"Dismiss", @"")
                                              otherButtonTitles:nil];
        [alert show];
         */
    }
    
    IOUploadAPendingSighting *operation;
    operation = [[IOUploadAPendingSighting alloc] initWithGlobalQueue:self.queue forced:NO];
    operation.context = [[IOCoreDataHelper sharedInstance] context];
    operation.sightingID = sightingID;
    operation.showsUploadingProgress = showUploadProgress;
    
    __weak __typeof(self)weakSelf = self;
    
    NSInteger maxRecursions = 10;
    __block NSManagedObjectID *localNextSightingObjectID;
    __block BOOL localShouldScheduleANewCheck = NO;
    operation.successBlock = ^(BOOL shouldScheduleANewCheck, NSManagedObjectID *nextSightingObjectID)
    {
#if DEBUG
        DDLogError(@"%@: Calling the Sightings Operation successBlock.", weakSelf.class);
#endif
        if (nextSightingObjectID)
        {
            if (![nextSightingObjectID isEqual:sightingID] && counter <= maxRecursions)
            {
                localNextSightingObjectID = [nextSightingObjectID copy];
                localShouldScheduleANewCheck = YES;
            }
            else
                DDLogError(@"%@: ERROR. Cannot check/upload same sighting or too many recursions", weakSelf.class);
        }
        else {
            if (counter <= maxRecursions)
                localShouldScheduleANewCheck = YES;
            else
                DDLogError(@"%@: ERROR. Too many sightings' submissions in recursion. Stopping.", weakSelf.class);
        }
    };
    
    __weak __typeof(_queue)weakQueue = _queue;
    operation.completionBlock = ^{
#if DEBUG
        DDLogError(@"%@: Calling the Sightings Operation completionBlock.", weakSelf.class);
#endif
        DDLogVerbose(@"%@: Releasing Sightings check and upload operation", weakSelf.class);
        DDLogVerbose(@"%@: Queue operations count: %d", weakSelf.class, weakQueue.operationCount);
        
        weakSelf.uploadAPendingSightingOperation = nil;
        
        if (localShouldScheduleANewCheck)
        {
            int newCount = counter + 1;
#if DEBUG
            DDLogVerbose(@"%@: Scheduling a new check/upload... (#%d)", weakSelf.class, newCount);
#endif
            dispatch_async(dispatch_get_main_queue(), ^{
                if (localNextSightingObjectID)
                    DDLogVerbose(@"%@: Scheduling a new check/upload for a specific pending sighting (#%d)", weakSelf.class, newCount);
                else
                    DDLogVerbose(@"%@: Scheduling a new check/upload for any pending sightings (#%d)", weakSelf.class, newCount);
                [weakSelf checkAndUploadAPendingSightingWihtID:localNextSightingObjectID showingUploadProgress:NO counter:newCount];
            });
        }
#if DEBUG
        DDLogVerbose(@"=============================");
#endif
    };
    self.uploadAPendingSightingOperation = operation;
    [self.queue addOperation:operation];
    
    return operation;
}

@end
