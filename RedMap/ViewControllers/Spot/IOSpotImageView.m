//
//  IOSpotImageView.m
//  RedMap
//
//  Created by Evo Stamatov on 4/07/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOSpotImageView.h"

@implementation IOSpotImageView

- (void)setPersistentBackgroundColor:(UIColor *)backgroundColor
{
    super.backgroundColor = backgroundColor;
}



- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    // do nothing - background color, never changes
}



- (UIColor *)backgroundColor
{
    return super.backgroundColor;
}

@end
