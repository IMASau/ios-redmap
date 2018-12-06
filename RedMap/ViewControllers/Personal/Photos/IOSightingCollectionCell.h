//
//  IOSightingCollectionCell.h
//  RedMap
//
//  Created by Evo Stamatov on 17/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IOSightingCollectionCell : UICollectionViewCell

- (void)setSightingID:(NSManagedObjectID *)sightingID inContext:(NSManagedObjectContext *)context;

@property (nonatomic, assign, readonly) NSString *sightingUUID;

@end
