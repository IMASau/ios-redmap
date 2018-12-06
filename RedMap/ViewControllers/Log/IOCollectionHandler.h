
//
//  IOCollectionHandler.h
//  RedMap
//
//  Created by Evo Stamatov on 6/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol IOCollectionHandlerDelegate <NSObject>

- (UITabBar *)theTabBar;
- (id)getManagedObjectDataForKey:(NSString *)key;
- (void)setManagedObjectDataForKey:(NSString *)key withObject:(id)object;

@end


@interface IOCollectionHandler : UICollectionView

@property (nonatomic, weak) id <IOCollectionHandlerDelegate> controllerDelegate;
@property (nonatomic, copy) NSString *UUID;
@property (nonatomic, assign) BOOL retainPhotos;

- (void)mark;
- (void)unmark;

- (BOOL)isDirty;

@end
