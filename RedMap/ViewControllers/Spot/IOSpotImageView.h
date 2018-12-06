//
//  IOSpotImageView.h
//  RedMap
//
//  Created by Evo Stamatov on 4/07/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IOSpotImageView : UIImageView

@property (nonatomic, copy) UIColor *backgroundColor;                           // the setter doesn't do anything... simply ignores the setting
- (void)setPersistentBackgroundColor:(UIColor *)backgroundColor;

@end
