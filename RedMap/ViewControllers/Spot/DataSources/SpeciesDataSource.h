//
//  SpeciesDataSource.h
//  RedMap
//
//  Created by Evo Stamatov on 26/03/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IOBaseDataSource.h"

@class IOCategory, Region;

@interface SpeciesDataSource : IOBaseDataSource

@property (strong, nonatomic, readonly) IOCategory *speciesCategory;
- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context category:(IOCategory *)category region:(Region *)regionOrNil;

@end
