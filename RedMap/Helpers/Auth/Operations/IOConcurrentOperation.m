//
//  IOConcurrentOperation.m
//  Redmap
//
//  Created by Evo Stamatov on 25/09/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOConcurrentOperation.h"

#define VERBOSE_DEBUG 1

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

////////////////////////////////////////////////////////////////////////////////
/// Interface
////////////////////////////////////////////////////////////////////////////////

@interface IOConcurrentOperation () {
    BOOL _isExecuting;
    BOOL _isFinished;
    BOOL _shouldLock;
    NSConditionLock *_conditionLock;
    NSCondition *_condition;
    NSInteger _conditionPredicate;
}

@property (nonatomic, weak, readwrite) NSOperationQueue *queue;
@property (nonatomic, assign, readwrite) BOOL forced;

@end

////////////////////////////////////////////////////////////////////////////////
/// Implementation
////////////////////////////////////////////////////////////////////////////////

@implementation IOConcurrentOperation

////////////////////////////////////////////////////////////////////////////////
- (instancetype)init
{
    self = [super init];
    if (self)
    {
#if VERBOSE_DEBUG
        DDLogInfo(@"%@: Initializing", self.class);
#endif
        _isExecuting = NO;
        _isFinished = NO;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
- (instancetype)initWithGlobalQueue:(NSOperationQueue *)queue forced:(BOOL)forced
{
    self = [super init];
    if (self)
    {
#if VERBOSE_DEBUG
        DDLogInfo(@"%@: Initializing with global queue", self.class);
#endif
        _isExecuting = NO;
        _isFinished = NO;
        
        _queue = queue;
        _forced = forced;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
- (void)dealloc
{
#if VERBOSE_DEBUG
    DDLogInfo(@"IOConcurrentOperation: Deallocating");
#endif
    
    if (_conditionLock)
        [self unlock];
}

////////////////////////////////////////////////////////////////////////////////
- (BOOL)isConcurrent
{
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
- (BOOL)isExecuting
{
#if VERBOSE_DEBUG
    DDLogVerbose(@"%@: Execution check? %@", self.class, _isExecuting ? @"YES" : @"NO");
#endif
    return _isExecuting;
}

////////////////////////////////////////////////////////////////////////////////
- (BOOL)isFinished
{
#if VERBOSE_DEBUG
    DDLogVerbose(@"%@: Finish check? %@", self.class, _isFinished ? @"YES" : @"NO");
#endif
    return _isFinished;
}

////////////////////////////////////////////////////////////////////////////////
- (void)start
{
    if (![NSThread isMainThread]) { // Dave Dribin is a legend!
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
        return;
    }
    
    // Always check for cancellation before launching the task.
    if (self.isCancelled)
    {
#if VERBOSE_DEBUG
        DDLogWarn(@"%@: Operation has been cancelled, before it could start.", self.class);
#endif
        [self finish];
        return;
    }
    
#if VERBOSE_DEBUG
    DDLogInfo(@"%@: Operation started.", self.class);
#endif
    
    // If the operation is not canceled, begin executing the task.
    [self willChangeValueForKey:@"isExecuting"];
    _isExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
    // Call the mainWrapper on background thread
    //[self performSelectorInBackground:@selector(mainWrapper) withObject:self];
    [NSThread detachNewThreadSelector:@selector(mainWrapper) toTarget:self withObject:nil];
}

////////////////////////////////////////////////////////////////////////////////
- (void)finish
{
#if VERBOSE_DEBUG
    DDLogInfo(@"%@: Operation finished.", self.class);
#endif
    
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    
    _isExecuting = NO;
    _isFinished = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

////////////////////////////////////////////////////////////////////////////////
- (void)mainWrapper
{
#if VERBOSE_DEBUG
    DDLogVerbose(@"%@: Will execute mainWrapper.", self.class);
#endif
    
    @try {
#if VERBOSE_DEBUG
    DDLogVerbose(@"%@: Will call [main].", self.class);
#endif
        [self main];
#if VERBOSE_DEBUG
    DDLogVerbose(@"%@: Did finish [main].", self.class);
#endif
    }
    @catch (NSException *exception) {
        DDLogError(@"%@: EXCEPTION while calling [main]: %@, %@", self.class, exception.name, exception.reason);
        [self finish];
        return;
    }
    @finally {
#if VERBOSE_DEBUG
    DDLogVerbose(@"%@: Did call [main].", self.class);
#endif
    }
    
    DDLogVerbose(@"%@: Did execute MainWrapper.", self.class);
}

////////////////////////////////////////////////////////////////////////////////
- (void)cancel
{
#if VERBOSE_DEBUG
    DDLogWarn(@"%@: Operation was cancelled.", self.class);
#endif
    
    [super cancel];
    
    if (self.isExecuting)
        [self finish];
}

////////////////////////////////////////////////////////////////////////////////
- (void)cancelAllDependencies
{
    if (self.dependencies.count > 0)
    {
        DDLogWarn(@"%@: Cancelling all dependencies.", self.class);
        
        for (NSOperation *dep in self.dependencies)
        {
            if ([dep respondsToSelector:@selector(cancel)])
                [dep cancel];
        }
    }
}

////////////////////////////////////////////////////////////////////////////////
/// Locking Helpers
////////////////////////////////////////////////////////////////////////////////

#define kIOConcurrentOperationRemoteLock 1
#define kIOConcurrentOperationRemoteDone 0

/*!
 * Prepares for locking.
 *
 * This is supposed to be before the lock, and any calls to unlock, because a
 * call to unlock, before preparation will miss the locked state.
 * Eg.:
 *  - No call to prepareForLock
 *  - Call to unlock (does nothing)
 *  - Call to lock (actually locks)
 *  -- stays locked... forever
 * Whereas:
 *  - Call to PrepareForLock
 *  - Call to unlock (unlocks)
 *  - Call to lock (does nothing)
 */
- (void)prepareForLock
{
    DDLogVerbose(@"%@: Preparing for locking", self.class);
    
    _condition = [NSCondition new];
    _conditionPredicate = kIOConcurrentOperationRemoteLock;
    _shouldLock = YES;
}

////////////////////////////////////////////////////////////////////////////////
/*!
 * Locks the current thread and waits foc Done condition.
 */
- (void)lock
{
    if (_shouldLock == NO)
    {
        DDLogVerbose(@"%@: No need to lock. Called unlock before lock.", self.class);
        _condition = nil;
        return;
    }
    
#if VERBOSE_DEBUG
    DDLogVerbose(@"LOCK START");
#endif
    
    if (_condition)
    {
        [_condition lock];
        
        DDLogVerbose(@"%@: Synchronous lock", self.class);
        
        while (_conditionPredicate == kIOConcurrentOperationRemoteLock)
        {
#if VERBOSE_DEBUG
            DDLogVerbose(@"WAIT START");
#endif
            [_condition wait];
#if VERBOSE_DEBUG
            DDLogVerbose(@"WAIT END");
#endif
        }
        
#if VERBOSE_DEBUG
        DDLogVerbose(@"UNLOCKING");
#endif
        [_condition unlock];
#if VERBOSE_DEBUG
        DDLogVerbose(@"UNLOCKED");
#endif
        
        // Release the condition object
        _condition = nil;
    }
    
#if VERBOSE_DEBUG
    DDLogVerbose(@"LOCK END");
#endif
    
    /*
    if (_conditionLock != nil)
    {
        DDLogVerbose(@"%@: Synchronous lock", self.class);
        [_conditionLock lockWhenCondition:kIOConcurrentOperationRemoteDone];
        [_conditionLock unlock];
    }
     */
}

////////////////////////////////////////////////////////////////////////////////
/*!
 * Sends the unlock signal to the waiting lock.
 */
- (void)unlock
{
#if VERBOSE_DEBUG
    DDLogVerbose(@"UNLOCK SIGNAL START");
#endif
    
    if (_condition && _conditionPredicate == kIOConcurrentOperationRemoteLock)
    {
        if (_shouldLock)
        {
            DDLogVerbose(@"%@: Unlocking before locking. Because we are blazing fast.", self.class);
            _shouldLock = NO;
        }
        
        DDLogVerbose(@"%@: Synchronous UNlock", self.class);
        _conditionPredicate = kIOConcurrentOperationRemoteDone;
        
#if VERBOSE_DEBUG
        DDLogVerbose(@"SIGNALING");
#endif
        [_condition signal];
#if VERBOSE_DEBUG
        DDLogVerbose(@"SIGNALED");
#endif
        
    }
    
#if VERBOSE_DEBUG
    DDLogVerbose(@"UNLOCKED SIGNAL END");
#endif
}

@end
