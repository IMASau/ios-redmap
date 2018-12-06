//
//  IOBaseCell.h
//  RedMap
//
//  Created by Evo Stamatov on 1/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, IOMarkedAnimationFade) {
    IOMarkedAnimationFadeIn = 0,
    IOMarkedAnimationFadeOut
};

@interface IOBaseCell : UITableViewCell

@property (nonatomic, assign) BOOL marked;
- (void)setMarked:(BOOL)marked animated:(BOOL)animated;

- (void)willDisplay;
- (void)didEndDisplay;

// Private
- (void)animateView:(UIView *)view withIOMarkedAnimationFade:(IOMarkedAnimationFade)fadeInOrOut;

@end
