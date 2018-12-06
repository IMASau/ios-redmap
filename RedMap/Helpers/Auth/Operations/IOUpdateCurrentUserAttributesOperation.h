//
//  IOUpdateCurrentUserAttributesOperation.h
//  Redmap
//
//  Created by Evo Stamatov on 5/09/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOConcurrentOperation.h"

@interface IOUpdateCurrentUserAttributesOperation : IOConcurrentOperation

@property (nonatomic, weak) NSManagedObjectContext *context;
@property (nonatomic, weak) NSManagedObjectContext *sightingsContext;

@end
