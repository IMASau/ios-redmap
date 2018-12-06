//
//  IOLoggingViewController.h
//  RedMap
//
//  Created by Evo Stamatov on 30/04/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IOHomeTableViewControllerProtocol.h"

#define TESTING_SAVE_AND_MAPPING 0
#define TESTING_SAVE_AND_SYNCING 0

#define ALLOW_ADVANCED_MODE 0

#if DEBUG
#define SHOW_RESET_BUTTON 1
#endif

@class IOCollectionHandler;
@class IOCategory;
@class Species;

@protocol IOLoggingViewControllerDelegate;

////////////////////////////////////////////////////////////////////////////////
@interface IOLoggingViewController : UITableViewController

@property (nonatomic, weak) id<IOLoggingViewControllerDelegate> delegate;
@property (nonatomic, weak) id<IOHomeTableViewControllerProtocol> homeViewController;

- (void)setCategory:(IOCategory *)category andSpecies:(Species *)species;

@end

////////////////////////////////////////////////////////////////////////////////
@class Sighting;

@protocol IOLoggingViewControllerDelegate <NSObject>

- (void)loggingViewController:(UIViewController *)viewController publishedSightingWithID:(NSManagedObjectID *)sightingID;

@end