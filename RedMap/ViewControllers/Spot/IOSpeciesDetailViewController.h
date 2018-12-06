//
//  SpeciesDetailViewController.h
//  RedMap
//
//  Created by Evo Stamatov on 27/03/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class Species;
@class IOCategory;

@protocol IOSpeciesDetailDelegate;


@interface SpeciesDetailViewController : UIViewController <UIWebViewDelegate>//, MKMapViewDelegate>

@property (strong, nonatomic) Species *speciesDetails;
@property (strong, nonatomic) IOCategory *categoryDetails;

@property (nonatomic) BOOL awokenFromLogging;
@property (nonatomic, weak) id<IOSpeciesDetailDelegate> delegate;

@end


@protocol IOSpeciesDetailDelegate <NSObject>
- (void)speciesDetailViewController:(SpeciesDetailViewController *)viewController category:(IOCategory *)category species:(Species *)species;
@end