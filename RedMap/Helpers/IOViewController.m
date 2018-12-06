//
//  IOViewController.m
//  RedMap
//
//  Created by Evo Stamatov on 4/07/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOViewController.h"

@implementation IOViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navBarHidden = NO;
    self.hideNavBarWhenDisappearing = NO;
}



- (void)viewWillDisappear:(BOOL)animated
{
    if (self.hideNavBarWhenDisappearing)
    {
        //IOLog(@"=============== Hiding the navbar");
        self.navBarHidden = YES;
        self.hideNavBarWhenDisappearing = NO;
        [self.navigationController setNavigationBarHidden:YES animated:animated];
    }
    
    [super viewWillDisappear:animated];
}



- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.navBarHidden)
    {
        //IOLog(@"=============== Showing the navbar");
        [self.navigationController setNavigationBarHidden:NO animated:animated];
        self.navBarHidden = NO;
    }
}

@end
