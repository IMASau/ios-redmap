//
//  IOHowYouCanHelpViewController.h
//  RedMap
//
//  Created by Evo Stamatov on 4/07/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HTMLHelper.h"

typedef NS_ENUM(NSInteger, IOHowYouCanHelpCells) {
    IOHowYouCanHelpCellsFacebook = 1,
    IOHowYouCanHelpCellsSpot,
    IOHowYouCanHelpCellsLog,
    IOHowYouCanHelpCellsResources,
    IOHowYouCanHelpCellsNewsletter,
    IOHowYouCanHelpCellsContactUs
};

@interface IOHowYouCanHelpViewController : HTMLHelper //IOTableViewController

@end
