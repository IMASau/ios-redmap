//
//  IOMapSettingsViewController.h
//  RedMap
//
//  Created by Evo Stamatov on 17/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>


@protocol IOMapSettingsDelegate <NSObject>

- (void)mapTypeChangedTo:(MKMapType)mapType;

@optional
- (void)showRegionBorders:(BOOL)showOrHide;

@end


@interface IOMapSettingsViewController : UIViewController

// Public
// ======

@property (weak) id <IOMapSettingsDelegate> delegate;
@property (nonatomic, assign) MKMapType mapType;
@property (nonatomic, assign) BOOL showRegionBorderSwitch;
@property (nonatomic, assign) BOOL regionBorderSwithchIsOn;



// Private
// =======

@property (weak, nonatomic) IBOutlet UISegmentedControl *mapTypeSegment;
@property (weak, nonatomic) IBOutlet UISwitch *regionBorderSwitch;
@property (weak, nonatomic) IBOutlet UILabel *showRegionBorderLabel;

- (IBAction)mapTypeChanged:(UISegmentedControl *)sender;

@end
