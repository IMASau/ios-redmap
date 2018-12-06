//
//  IOLocationVC.h
//  RedMap
//
//  Created by Evo Stamatov on 22/04/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "IOCellConnection.h"

@class IOMapRegionObject;

#define ALLOW_SHOWING_OF_REGION_BORDERS 0

@interface IOLocationVC : UIViewController <MKMapViewDelegate>

@property (nonatomic, weak) id <IOCellConnection> delegate;                     // The delegate will receive some callbacks from the controller
@property (nonatomic, assign) CLLocationCoordinate2D locationCoordinate;        // Pre-set a location
@property (nonatomic, assign) CGFloat locationAccuracyInMetres;                 // Pre-set the location accuracy level in metres - 10, 100, 1000 or 10000
@property (nonatomic, copy) NSString *regionName;                               // A region name to constrain the allowed locations within
@property (nonatomic, strong) NSArray *accuracySegments;                        // An array of NSDictionaries holding the available segments -> @{ ID:XX, code:YY, title:ZZ }
@property (nonatomic, strong) IOMapRegionObject *visibleMapRegion;              // A map region to set the mapView to upon map view load
@property (nonatomic, assign) BOOL unconfirmed;                                 // Displays Confirm or Done text for done button

@end
