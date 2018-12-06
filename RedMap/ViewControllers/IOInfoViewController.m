//
//  IOInfoViewController.m
//  RedMap
//
//  Created by Evo Stamatov on 2/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOInfoViewController.h"

@interface IOInfoViewController () <UINavigationBarDelegate>

@end


@implementation IOInfoViewController

- (void)viewDidLoad
{
    self.htmlFile = @"info.html"; // set before calling super's viewDidLoad
    [super viewDidLoad];
    
#if TRACK
    [GoogleAnalytics sendEventWithCategory:@"checkpoint" withAction:@"viewDidLoad" withLabel:@"IOInfoViewController" withValue:@1];
#endif
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}



#if TRACK
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [GoogleAnalytics sendView:@"Info"];
}
#endif



#pragma mark - IBActions

- (IBAction)goBack:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
    if (iOS_7_OR_LATER())
        return UIBarPositionTopAttached;
    else
        return UIBarPositionTop;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if (iOS_7_OR_LATER())
        return UIStatusBarStyleLightContent;
    else
        return UIStatusBarStyleDefault;
}

@end
