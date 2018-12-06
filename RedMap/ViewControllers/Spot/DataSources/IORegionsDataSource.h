//
//  IORegionsDataSource.h
//  RedMap
//
//  Created by Evo Stamatov on 18/06/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IOBaseDataSource.h"
#import "IOCommonListingDataSource.h"

@class Region;

@interface IORegionsDataSource : IOBaseDataSource <IOCommonListingDataSource>

- (id)initWithContext:(NSManagedObjectContext *)context;
- (Region *)regionByNameOrSlugLookup:(NSString *)regionName;

@end
