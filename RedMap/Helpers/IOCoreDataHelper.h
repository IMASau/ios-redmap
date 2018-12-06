//
//  IOCoreDataHelper.h
//  Redmap
//
//  Created by Evo Stamatov on 5/03/2014.
//  Copyright (c) 2014 Ionata. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IOCoreDataHelper : NSObject

+ (IOCoreDataHelper *)sharedInstance;

@property (readonly, strong, nonatomic) NSManagedObjectContext *context;
@property (readonly, strong, nonatomic) NSManagedObjectContext *importContext;
@property (readonly, strong, nonatomic) NSManagedObjectContext *logContext;

@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;

- (void)saveContext;
- (void)backgroundSaveContext;

// this removes all data from the persistent store and managed object contexts
- (BOOL)reloadStore;

+ (void)faultObjectWithID:(NSManagedObjectID *)objectID inContext:(NSManagedObjectContext *)context;
+ (void)saveContextHierarchy:(NSManagedObjectContext *)managedObjectContext;

+ (void)showValidationError:(NSError *)anError;

@end
