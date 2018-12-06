//
//  IOOfflineViewController.h
//  RedMap
//
//  Created by Evo Stamatov on 24/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IOOfflineViewController : UIViewController

+ (IOOfflineViewController *)sharedController;

- (void)attachToTableView:(UITableView *)tableView animated:(BOOL)animate;
- (void)detachAnimated:(BOOL)animate;

@end
