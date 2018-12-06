//
//  IOPersonalAnnotation.m
//  RedMap
//
//  Created by Evo Stamatov on 15/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOPersonalAnnotation.h"

@implementation IOPersonalAnnotation

- (id)initWithCoordinate:(CLLocationCoordinate2D)aCoordinate title:(NSString *)aTitle subtitle:(NSString *)aSubtitle;
{
    self = [super init];
    if (self)
    {
        _coordinate = aCoordinate;
        _title = aTitle;
        _subtitle = aSubtitle;
        _animatesDrop = NO;
    }
    
    return self;
}



- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate
{
    _coordinate = newCoordinate;
}

@end
