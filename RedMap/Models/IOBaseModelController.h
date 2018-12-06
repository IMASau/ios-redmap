//
//  IOBaseModelController.h
//  Redmap
//
//  Created by Evo Stamatov on 13/08/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////
@protocol IOBaseModelControllerProtocol <NSObject>

- (BOOL)similarObject:(id)NSDictionaryObject withObject:(id)CoreDataObject;
- (id)updateObject:(id)CoreDataObject withObject:(id)NSDictionaryObject;

@end

////////////////////////////////////////////////////////////////////////////////
@protocol IOFetchedResultsProtocol <NSObject>

@property (nonatomic, strong, readonly) NSArray *objects;
- (id)objectAtIndexPath:(NSIndexPath *)indexPath;
- (NSInteger)numberOfSections;
- (NSInteger)numberOfRowsInSection:(NSInteger)section;
- (id)sectionObjectAtIndex:(NSUInteger)index;

- (void)insertNewObject:(id)object;

@property (nonatomic, copy, readonly) NSString *sectionNameKeyPath;
@property (nonatomic, strong, readonly) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, weak) id <NSFetchedResultsControllerDelegate> fetchedResultsControllerDelegate;

- (void)syncCoreDataWithDataFromArray:(NSArray *)entries moreComing:(BOOL)moreComing callback:(void (^)(NSSet *insertedObjects, NSSet *updatedObjects, NSError *error))callback;

@end

////////////////////////////////////////////////////////////////////////////////
@interface IOBaseModelController : NSObject <IOFetchedResultsProtocol>

@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, copy, readonly) NSString *searchString;

@property (nonatomic, copy, readonly) NSString *entityName;
@property (nonatomic, copy, readonly) NSString *cacheName;
@property (nonatomic, copy, readonly) NSString *sortBy;
@property (nonatomic, assign, readonly) BOOL ascending;
@property (nonatomic, strong, readonly) NSArray *searchKeys;
@property (nonatomic, strong, readonly) NSPredicate *fetchPredicate;
@property (nonatomic, copy, readonly) NSString *idKey;

#pragma mark - IOFetchedResultsProtocol Protocol

@property (nonatomic, strong, readonly) NSArray *objects;
- (id)objectAtIndexPath:(NSIndexPath *)indexPath;
- (NSInteger)numberOfSections;
- (NSInteger)numberOfRowsInSection:(NSInteger)section;
- (id)sectionObjectAtIndex:(NSUInteger)index;

- (id)insertNewObject:(id)object;

@property (nonatomic, copy, readonly) NSString *sectionNameKeyPath;
@property (nonatomic, strong, readonly) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, weak) id <NSFetchedResultsControllerDelegate> fetchedResultsControllerDelegate;

- (void)syncCoreDataWithDataFromArray:(NSArray *)entries moreComing:(BOOL)moreComing callback:(void (^)(NSSet *insertedObjectIDs, NSSet *updatedObjectIDs, NSError *error))callback;

#pragma mark - private

- (void)prepareForDealloc;
- (NSDate *)dateFromISO8601String:(id)dateInput withTime:(BOOL)withTime;
- (NSString *)getString:(NSDictionary *)dict key:(id)key default:(NSString *)fallback;
- (NSString *)getString:(NSDictionary *)dict key:(id)key;

@end



