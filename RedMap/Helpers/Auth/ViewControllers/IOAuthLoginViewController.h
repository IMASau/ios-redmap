//
//  IOAuthLoginViewController.h
//  RedMap
//
//  Created by Evo Stamatov on 23/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, IOAuthValidation) {
    IOAuthValidationFailed = 0,
    IOAuthValidationUsernameFail = (0x1 << 1),
    IOAuthValidationUsernameOK = (0x1 << 2),
    IOAuthValidationPasswordFail = (0x1 << 3),
    IOAuthValidationPasswordOK = (0x1 << 4),
    IOAuthValidationUsernameAndPasswordFail = (0x1 << 1 | 0x1 << 3),
    IOAuthValidationUsernameAndPasswordOK = (0x1 << 2 | 0x1 << 4)
};

@class IOAuthLoginViewController;

@protocol IOAuthLoginViewControllerDelegate <NSObject>

- (void)authLoginViewControllerDidSucceed:(IOAuthLoginViewController *)authLoginViewController;
- (void)authLoginViewControllerDidFail:(IOAuthLoginViewController *)authLoginViewController error:(NSError *)error;
- (void)authLoginViewControllerDidCancel:(IOAuthLoginViewController *)authLoginViewController;

@end

@interface IOAuthLoginViewController : UITableViewController

@property (nonatomic, weak) id <IOAuthLoginViewControllerDelegate> responseDelegate;

@end
