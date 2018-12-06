//
//  IOAuthCreateAccountViewController.h
//  RedMap
//
//  Created by Evo Stamatov on 23/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <UIKit/UIKit.h>

@class IOAuthCreateAccountViewController;


@protocol IOAuthCreateAccountViewControllerDelegate <NSObject>

- (void)authCreateAccountViewControllerDidSucceed:(IOAuthCreateAccountViewController *)authCreateAccountViewController;
- (void)authCreateAccountViewControllerDidFail:(IOAuthCreateAccountViewController *)authCreateAccountViewController error:(NSError *)error;

@end


@interface IOAuthCreateAccountViewController : UITableViewController

@property (nonatomic, weak) id <IOAuthCreateAccountViewControllerDelegate> responseDelegate;

@property (nonatomic, copy) NSString *presetLoginUsername;
@property (nonatomic, copy) NSString *presetLoginPassword;

@end
