//
//  IOUpdateCategoriesOperation.h
//  Redmap
//
//  Created by Evo Stamatov on 5/09/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOConcurrentOperation.h"

@interface IOUpdateCategoriesOperation : IOConcurrentOperation

@property (nonatomic, weak) NSManagedObjectContext *context;

@end
