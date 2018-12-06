//
//  IOPersonalMapViewController.h
//  RedMap
//
//  Created by Evo Stamatov on 13/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "IOPersonalViewControllerProtocol.h"
#import "IOPersonalFetchDelegate.h"

@class IOViewCurlButton;

@interface IOPersonalMapViewController : UIViewController <IOPersonalViewControllerProtocol, IOPersonalFetchDelegate>

@property (nonatomic, copy) NSManagedObjectID *justPublishedSightingID;
@property (nonatomic, strong) NSManagedObjectContext *context;

// Required by IOPersonalFetchDelegate
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@end
