//
//  IOMainTabBarViewController.h
//  RedMap
//
//  Created by Evo Stamatov on 25/03/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IOHomeTableViewControllerProtocol.h"

#define SPOT_TAB_INDEX 0
#define LOG_TAB_INDEX 1
#define PERSONAL_TAB_INDEX 2

@class Sighting;
@class IOCategory;
@class Species;

////////////////////////////////////////////////////////////////////////////////
@protocol IOTabBarProtocol <NSObject>

- (void)popTheTopmostController;

@end

////////////////////////////////////////////////////////////////////////////////
@interface IOMainTabBarViewController : UITabBarController <IOTabBarProtocol>

@property (nonatomic, weak) id<IOHomeTableViewControllerProtocol> homeViewController;

- (void)selectLogTabAndSetCategory:(IOCategory *)category andSpecies:(Species *)species;
- (void)selectPersonalTabAndPlotASightingID:(NSManagedObjectID *)sightingID;

@end
