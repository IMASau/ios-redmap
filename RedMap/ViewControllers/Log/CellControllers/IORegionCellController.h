//
//  IORegionCellController.h
//  Redmap
//
//  Created by Lidiya Stamatova on 16/08/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOCommonListingCellController.h"

@interface IORegionCellController : IOCommonListingCellController

- (id)initWithSettings:(NSDictionary *)settings delegate:(id<IOBaseCellControllerDelegate>)delegate managedObjectContext:(NSManagedObjectContext *)context;

@end
