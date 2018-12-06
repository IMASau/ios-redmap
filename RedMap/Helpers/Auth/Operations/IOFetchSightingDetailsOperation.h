//
//  IOFetchSightingDetailsOperation.h
//  Redmap
//
//  Created by Evo Stamatov on 17/03/2014.
//  Copyright (c) 2014 Ionata. All rights reserved.
//

#import "IOConcurrentOperation.h"

@class IOSightingsController;

@interface IOFetchSightingDetailsOperation : IOConcurrentOperation

- (instancetype)initWithSightingID:(NSInteger)sightingID authToken:(NSString *)authToken sightingsController:(IOSightingsController *)sightingsController context:(NSManagedObjectContext *)context;

@end
