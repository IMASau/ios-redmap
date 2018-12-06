//
//  IOAuthController.h
//  RedMap
//
//  Created by Evo Stamatov on 28/06/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <UIKit/UIKit.h>

@class IOAuthController;

extern NSString *const IOAuthControllerDomain;
extern NSInteger const IOAuthControllerErrorCodeNoInternet;

@protocol IOAuthControllerDelegate <NSObject>

- (void)authControllerDidSucceed:(IOAuthController *)authController;
- (void)authControllerDidFail:(IOAuthController *)authController error:(NSError *)error;

@optional
- (void)authControllerDidCancel:(IOAuthController *)authController;

@end

@interface IOAuthController : UINavigationController

+ (IOAuthController *)authController;

// since .delegate is used by UINavigationController. bummer.
@property (nonatomic, weak) id <IOAuthControllerDelegate> responseDelegate;

// you can store anything in here, but don't store anything that is from IOAuthController
@property (nonatomic, strong) id userData;

@end
