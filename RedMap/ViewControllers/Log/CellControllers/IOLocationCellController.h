//
//  IOLocationCellController.h
//  Redmap
//
//  Created by Evo Stamatov on 19/08/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOBaseCellController.h"

@interface IOLocationCellController : IOBaseCellController

- (id)initWithSettings:(NSDictionary *)settings delegate:(id<IOBaseCellControllerDelegate>)delegate managedObjectContext:(NSManagedObjectContext *)context;
- (void)markTableViewCell:(IOBaseCell *)cell asUnChecked:(BOOL)markAsUnChecked animated:(BOOL)animated;
@property (nonatomic, assign, readonly) BOOL markedAsUnChecked;

@property (nonatomic, readonly) BOOL acquiredLocationChecked;

@end
