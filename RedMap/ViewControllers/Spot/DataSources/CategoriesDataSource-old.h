//
//  CategoriesDataSource.h
//  RedMap
//
//  Created by Evo Stamatov on 26/03/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IOBaseDataSource.h"

@interface CategoriesDataSource : IOBaseDataSource

// Inherits from IOBaseDataSource:
//   id <IOSpotDataSourceDelegate> delegate;
//   NSManagedObjectContext *managedObjectContext;

- (id)initWithContext:(NSManagedObjectContext *)context;

@end
