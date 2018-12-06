//
//  IOPersonalAnnotation.h
//  RedMap
//
//  Created by Evo Stamatov on 15/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface IOPersonalAnnotation : NSObject <MKAnnotation>

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, assign) BOOL animatesDrop;

@property (nonatomic, copy) NSString *sightingUUID;

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

@property (nonatomic, weak) MKCircle *overlay;

- (id)initWithCoordinate:(CLLocationCoordinate2D)aCoordinate title:(NSString *)aTitle subtitle:(NSString *)aSubtitle;

@end
