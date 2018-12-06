//
//  IOPhotoViewController.h
//  RedMap
//
//  Created by Evo Stamatov on 28/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IOPhotoViewController : UIViewController

@property (nonatomic, assign) NSUInteger index;
@property (nonatomic, strong) UIImage *image;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end
