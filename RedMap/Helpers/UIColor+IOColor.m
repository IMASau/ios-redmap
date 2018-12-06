//
//  UIColor+IOColor.m
//  RedMap
//
//  Created by Evo Stamatov on 16/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//
//  Used the following online tool to convert the HEX colours to UIColor
//  http://scratch.johnnypez.com/hex-to-uicolor/
//
//

#import "UIColor+IOColor.h"

@implementation UIColor (IOColor)

+ (UIColor *)IORedColor
{
    // #e41e26 - red
    return [UIColor colorWithRed:0.894 green:0.118 blue:0.149 alpha:1.0];
}

+ (UIColor *)IOLightRedColor
{
    // #ee3123 - lighter red
    return [UIColor colorWithRed:0.933 green:0.192 blue:0.137 alpha:1.0];
}

//#0f5394
+ (UIColor *)IOBlueColor
{
    // #082c5d - dark blue
    return [UIColor colorWithRed:0.031 green:0.173 blue:0.365 alpha:1.0];
}

+ (UIColor *)IOLighterBlueColor
{
    // #1265b3 - lighter blue
    return [UIColor colorWithRed:0.071 green:0.396 blue:0.702 alpha:1.0];
}

+ (UIColor *)IOLightBlueColor
{
    // #c3dbf1 - light blue
    return [UIColor colorWithRed:0.765 green:0.859 blue:0.945 alpha:1.0];
}

+ (UIColor *)IODarkGreyishColor
{
    // #556570 - dark greyish
    return [UIColor colorWithRed:0.333 green:0.396 blue:0.439 alpha:1.0];
}

+ (UIColor *)IODarkGreyColor
{
    // #989898 - dark grey
    return [UIColor colorWithRed:0.596 green:0.596 blue:0.596 alpha:1.0];
}

@end
