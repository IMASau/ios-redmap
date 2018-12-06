//
//  IOPhotoViewController.m
//  RedMap
//
//  Created by Evo Stamatov on 28/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOPhotoViewController.h"


@interface IOPhotoViewController ()

@end


@implementation IOPhotoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /*
    CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
    UIColor *color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
    self.view.backgroundColor = color;
     */
    self.view.backgroundColor = [UIColor clearColor];
    
    if (self.image)
    {
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.image = self.image;
    }
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


@end
