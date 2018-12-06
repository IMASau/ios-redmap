//
//  IOMapSettingsViewController.m
//  RedMap
//
//  Created by Evo Stamatov on 17/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOMapSettingsViewController.h"


@interface IOMapSettingsViewController ()

@end


@implementation IOMapSettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.mapTypeSegment.selectedSegmentIndex = self.mapType;
    if (self.showRegionBorderSwitch)
    {
        self.regionBorderSwitch.hidden = NO;
        self.showRegionBorderLabel.hidden = NO;
        [self.regionBorderSwitch setOn:self.regionBorderSwithchIsOn animated:NO];
    }
    else
    {
        self.regionBorderSwitch.hidden = YES;
        self.showRegionBorderLabel.hidden = YES;
    }
}



- (IBAction)doneAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}



- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.delegate mapTypeChangedTo:self.mapType];
    if (self.delegate && [self.delegate respondsToSelector:@selector(showRegionBorders:)])
        [self.delegate showRegionBorders:[self.regionBorderSwitch isOn]];
}



#pragma mark - IBActions

- (IBAction)mapTypeChanged:(UISegmentedControl *)sender
{
    self.mapType = sender.selectedSegmentIndex;
}

@end
