//
//  IOSpotDataSource.h
//  RedMap
//
//  Created by Evo Stamatov on 30/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <Foundation/Foundation.h>

// This protocol is a promise that the object conforming it implements these properties and methods

@protocol IOSpotDataSource <NSObject>

@property (strong, nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
- (id)objectAtIndexPath:(NSIndexPath *)indexPath;

@optional
- (void)didRecieveMemoryWarning;
- (NSUInteger)heightForRowAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)isSearchAvailable;

// UIScrollViewDelegate
- (void)scrollViewWillBeginDragging;
- (void)scrollViewDidEndDraggingAndWillDecelerate:(BOOL)decelerate;
- (void)scrollViewDidEndDecelerating;

@end
