//
//  IONPersonalViewController.h
//  RedMap
//
//  Created by Evo Stamatov on 2/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IOHomeTableViewControllerProtocol.h"

@class Sighting;

@interface IOPersonalViewController : UIViewController

@property (nonatomic, weak) id<IOHomeTableViewControllerProtocol> homeViewController;
@property (nonatomic, copy) NSManagedObjectID *justPublishedSightingID;

@end
