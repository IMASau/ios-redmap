//
//  IOPendingOperations.h
//  Redmap
//
//  Created by Evo Stamatov on 5/09/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IOConcurrentOperation.h"

/*!
 * All IOOperations are concurrent.
 * The queue can run up to five operations in parallel if they are not dependent
 * on each other.
 *
 * The methods to initiate them are automatically enqueueing them into the
 * queue. A method will always check if an operation is running and won't 
 * enqueue a new one, but return the running one.
 */
@interface IOOperations : NSObject

@property (nonatomic, strong, readonly) NSOperationQueue *queue;

@property (nonatomic, strong, readonly) IOConcurrentOperation *updateSightingAttributesOperation;
@property (nonatomic, strong, readonly) IOConcurrentOperation *updateCategoriesOperation;
@property (nonatomic, strong, readonly) IOConcurrentOperation *updateRegionsOperation;
@property (nonatomic, strong, readonly) IOConcurrentOperation *updateSpeciesOperation;
@property (nonatomic, strong, readonly) IOConcurrentOperation *updateCurrentUserAttributesOperation;

@property (nonatomic, strong, readonly) IOConcurrentOperation *uploadAPendingSightingOperation;

/*!
 * Updates the sighting attributes by initially copying the local plist, then
 * checking modification date and if older, fetching from API and saving to
 * file.
 *
 * No dependencies.
 */
- (IOConcurrentOperation *)updateSightingAttributesForced:(BOOL)forced;

/*!
 * Updates the categories from the API.
 *
 * No dependencies.
 */
- (IOConcurrentOperation *)updateCategoriesForced:(BOOL)forced;

/*!
 * Updates the regions from the API.
 *
 * Depends on Categories.
 * Will add the dependencies itself.
 */
- (IOConcurrentOperation *)updateRegionsForced:(BOOL)forced;

/*!
 * Updates the species from the API.
 *
 * Depends on Categories and Regions.
 * Will add the dependencies itself.
 */
- (IOConcurrentOperation *)updateSpeciesForced:(BOOL)forced;

/*!
 * Updates the current user attributes and sightings.
 *
 * Depends on Categories, Species, and Sighting Attributes.
 * Will add the dependencies itself.
 */
- (IOConcurrentOperation *)updateCurrentUserAttributesForced:(BOOL)forced;

/*!
 * Checks and uploads saved sightings.
 */
- (IOConcurrentOperation *)checkAndUploadAPendingSightingWihtID:(NSManagedObjectID *)sightingID showingUploadProgress:(BOOL)showUploadProgress;

@end
