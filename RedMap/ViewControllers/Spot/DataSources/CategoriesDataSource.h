//
//  CategoriesDataSource.h
//  RedMap
//
//  Created by Evo Stamatov on 26/03/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IOBaseDataSource.h"
#import "IOCategoriesController.h"

@class Region;

@interface CategoriesDataSource: IOBaseDataSource

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context region:(Region *)regionOrNil;
@property (nonatomic, strong, readonly) Region *region;

@end
