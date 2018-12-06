//
//  IOSpeciesController.h
//  Redmap
//
//  Created by Evo Stamatov on 12/08/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOBaseModelController.h"

@class Region, IOCategory;

@interface IOSpeciesController : IOBaseModelController <IOBaseModelControllerProtocol>

- (id)initWithContext:(NSManagedObjectContext *)context region:(Region *)regionOrNil category:(IOCategory *)categoryOrNil searchString:(NSString *)searchStringOrNil;

- (id)initWithContext:(NSManagedObjectContext *)context speciesURL:(NSString *)speciesURL; // provides a quick way to fetch just a specific species object by its url

@end
