//
//  IOLocationVCAnnotation.m
//  RedMap
//
//  Created by Evo Stamatov on 16/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOLocationVCAnnotation.h"

@implementation IOLocationVCAnnotation

- (NSString *)title
{
    return NSLocalizedString(@"Tap once to select", @"MKAnnotation title when user sets custom sighting location");
}



- (NSString *)subtitle
{
    return NSLocalizedString(@"and then tap and move around", @"MKAnnotation subtitle when user sets custom sighting location");
}

 

- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate
{
    _coordinate = newCoordinate;
}



- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate
{
    self = [super init];
    
    if (self)
        _coordinate = coordinate;
    
    return self;
}

@end
