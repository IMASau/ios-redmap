//
//  IOCategoriesController.h
//  Redmap
//
//  Created by Evo Stamatov on 30/07/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IOBaseModelController.h"

@class Region;

@interface IOCategoriesController : IOBaseModelController <IOBaseModelControllerProtocol>

- (id)initWithContext:(NSManagedObjectContext *)context region:(Region *)regionOrNil searchString:(NSString *)searchStringOrNil;

@end
