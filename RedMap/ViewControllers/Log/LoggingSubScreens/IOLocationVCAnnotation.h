//
//  IOLocationVCAnnotation.h
//  RedMap
//
//  Created by Evo Stamatov on 16/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface IOLocationVCAnnotation : NSObject <MKAnnotation>

@property (nonatomic) BOOL animatesDrop;

@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *subtitle;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate;

@end
