//
//  UIImageView+IOImage.m
//  RedMap
//
//  Created by Evo Stamatov on 17/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//
//  Thanks to Cyrille @ http://stackoverflow.com/questions/6856879/iphone-getting-the-size-of-an-image-after-aspectft
//

#import "UIImageView+IOImage.h"

@implementation UIImageView (IOImage)

- (CGSize)imageScale {
    CGFloat sx = self.frame.size.width / self.image.size.width;
    CGFloat sy = self.frame.size.height / self.image.size.height;
    CGFloat s = 1.0;
    switch (self.contentMode) {
        case UIViewContentModeScaleAspectFit:
            s = fminf(sx, sy);
            return CGSizeMake(s, s);
            break;
            
        case UIViewContentModeScaleAspectFill:
            s = fmaxf(sx, sy);
            return CGSizeMake(s, s);
            break;
            
        case UIViewContentModeScaleToFill:
            return CGSizeMake(sx, sy);
            
        default:
            return CGSizeMake(s, s);
    }
}

@end
