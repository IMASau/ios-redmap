//
//  IOUpdateUserDetailsWithAuthTokenOperation.h
//  Redmap
//
//  Created by Evo Stamatov on 9/09/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOConcurrentOperation.h"

@interface IOUpdateUserDetailsWithAuthTokenOperation : IOConcurrentOperation

/*!
 * Designated initializer
 */
- (instancetype)initWithUserObjectID:(NSManagedObjectID *)userObjectID
                           authToken:(NSString *)authToken
                             context:(NSManagedObjectContext *)context
                    sightingsContext:(NSManagedObjectContext *)sightingsContext
                               queue:(NSOperationQueue *)queueOrNil
                              forced:(BOOL)forced;

@end
