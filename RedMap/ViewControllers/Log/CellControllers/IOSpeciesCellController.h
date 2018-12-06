//
//  IOSpeciesCellController.h
//  Redmap
//
//  Created by Evo Stamatov on 16/08/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOBaseCellController.h"

@protocol IOSpeciesCellControllerDelegate;


@interface IOSpeciesCellController : IOBaseCellController

- (id)initWithSettings:(NSDictionary *)settings delegate:(id<IOBaseCellControllerDelegate>)delegate managedObjectContext:(NSManagedObjectContext *)context;
@property (nonatomic, weak) id <IOBaseCellControllerDelegate, IOSpeciesCellControllerDelegate> delegate;

@end


@protocol IOSpeciesCellControllerDelegate <NSObject>
- (BOOL)enableSpeciesMode;
@end