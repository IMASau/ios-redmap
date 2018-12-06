//
//  IORegionsController.h
//  Redmap
//
//  Created by Evo Stamatov on 12/08/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IOBaseModelController.h"

@class Region;

@interface IORegionsController : IOBaseModelController <IOBaseModelControllerProtocol>

- (id)initWithContext:(NSManagedObjectContext *)context searchString:(NSString *)searchStringOrNil;

- (Region *)lookupByName:(NSString *)name;                                      // a convenience for key @"desc"
- (Region *)lookupBySlug:(NSString *)slug;
- (Region *)lookupBy:(NSString *)key value:(id)value;

- (BOOL)similarObject:(id)NSDictionaryObject withObject:(id)CoreDataObject;

@end
