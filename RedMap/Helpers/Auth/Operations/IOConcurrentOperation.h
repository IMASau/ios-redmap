//
//  IOConcurrentOperation.h
//  Redmap
//
//  Created by Evo Stamatov on 25/09/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IOConcurrentOperation : NSOperation
{
    @public
    __weak NSOperationQueue *_queue;
    BOOL _forced;
}

/*!
 * Designated initializer
 *
 * A Global Queue allows any operation to append additional operations to that 
 * queue, instead of creating its own. You can't add dependencies within your
 *
 *
 * The global queue is usually the one that this very operation is enqueued to,
 * so take great care not to hold strong references to it.
 *
 * DON'T FORGET TO CALL [self finish] in your [main] method or after you finish
 * with your asynchronous tasks for the queue to dequeue the operation.
 */
- (instancetype)initWithGlobalQueue:(NSOperationQueue *)queue forced:(BOOL)forced;

/*!
 * You don't call this method explicitly if the operation is embedded in a
 * queue, since the queue will call it.
 *
 * If you overwrite the method, make sure to call [super start] first!
 *
 * Compared to regular NSOperation, this method will call [mainWrapper], instead
 * of [main].
 */
- (void)start;

/*!
 * This method calls [main], but does so in a safe manner - in @try{} block.
 *
 * If you override it, you don't have to call [super mainWrapper], just call
 * [main] or execute whatever you want in it.
 *
 * And keep in mind to catch exceptions!
 */
- (void)mainWrapper;

/*!
 * ALWAYS call finish at the end of your [main] (or [mainWrapper]) if you are
 * not executing asynchronous tasks.
 *
 * If you override [finish] then call [super finish] last, since it will hint
 * the queue to dequeue the operation!
 */
- (void)finish;

/*!
 * Always call [super cancel] if you override this method in your subclass.
 * It will finish the operation properly.
 */
- (void)cancel;

/*!
 * A helper to cancel all dependencies.
 */
- (void)cancelAllDependencies;

/*!
 * Holds a weak reference to the global queue.
 */
@property (nonatomic, weak, readonly) NSOperationQueue *queue;

/*!
 * A helper flag, which hints the operation to force update stale data.
 */
@property (nonatomic, assign, readonly) BOOL forced;

////////////////////////////////////////////////////////////////////////////////
/// Synchronous Locking Helpers
////////////////////////////////////////////////////////////////////////////////

/*!
 * Creates the lock object and locks it.
 */
- (void)prepareForLock;

/*!
 * Locks the thread and waits for unlock signal
 */
- (void)lock;

/*!
 * Signals the lock object to wake and unlock
 */
- (void)unlock;

@end
