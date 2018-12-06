//
//  IOPersonalFetchDelegate.h
//  RedMap
//
//  Created by Evo Stamatov on 17/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol IOPersonalFetchDelegate <NSObject>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@optional
- (void)fetchedResultsWillChange;
- (void)fetchedResultsDidChange;

- (void)fetchedResultsInsertedObject:(id)anObject newIndexPath:(NSIndexPath *)newIndexPath;
- (void)fetchedResultsDeletedObject:(id)anObject atIndexPath:(NSIndexPath *)atIndexPath;
- (void)fetchedResultsUpdateObject:(id)anObject atIndexPath:(NSIndexPath *)atIndexPath;
- (void)fetchedResultsMovedObject:(id)anObject fromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;
@end
