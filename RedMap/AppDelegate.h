//
//  AppDelegate.h
//  RedMap
//
//  Created by Evo Stamatov on 25/03/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RedMapAPIEngine.h"
#import "ImageEngine.h"

#define ApplicationDelegate ((AppDelegate *)[UIApplication sharedApplication].delegate)

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

#pragma mark - Network Engines
@property (strong, nonatomic) RedMapAPIEngine *api;
@property (strong, nonatomic) ImageEngine *imageEngine;

@end
