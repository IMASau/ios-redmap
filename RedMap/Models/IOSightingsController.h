//
//  IOSightingsController.h
//  Redmap
//
//  Created by Evo Stamatov on 6/09/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOBaseModelController.h"

#define IOAuthRemovedAllSightingsNotificationName @"removedAllSightigns"        // when the sightings table is flushed (maybe for specific userID only)

@interface IOSightingsController : IOBaseModelController <IOBaseModelControllerProtocol>

- (id)initWithContext:(NSManagedObjectContext *)context;
- (id)initWithContext:(NSManagedObjectContext *)context userID:(NSNumber *)userID;

@end
