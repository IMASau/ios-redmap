//
//  IOPersonalPhotosViewController.h
//  RedMap
//
//  Created by Evo Stamatov on 17/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IOPersonalViewControllerProtocol.h"
#import "IOPersonalFetchDelegate.h"

@interface IOPersonalPhotosViewController : UICollectionViewController <IOPersonalViewControllerProtocol, IOPersonalFetchDelegate>

@property (nonatomic, strong) NSManagedObjectContext *context;

// Required by IOPersonalFetchDelegate
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@end
