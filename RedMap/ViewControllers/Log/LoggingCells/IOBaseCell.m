//
//  IOBaseCell.m
//  RedMap
//
//  Created by Evo Stamatov on 1/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOBaseCell.h"

#define kIOMarkedAnimationDuration 0.35f

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface IOBaseCell ()

@property (nonatomic, strong) UIImageView *markerView;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation IOBaseCell

- (UIImageView *)markerView
{
    if (_markerView == nil)
    {
        UIImage *markerImage = [UIImage imageNamed:@"red-marker"];
        UIImageView *view = [[UIImageView alloc] initWithImage:markerImage];
        // fix marker position on iOS7
        CGFloat x = self.contentView.frame.origin.x;
        if (iOS_7_OR_LATER())
            x += 8.f;
        CGRect frame = CGRectMake(
                                  x - markerImage.size.width / 2,
                                  (self.contentView.frame.size.height - markerImage.size.height) / 2,
                                  markerImage.size.width,
                                  markerImage.size.height
                                  );
        view.frame = frame;
        _markerView = view;
        [self addSubview:_markerView];
    }
    
    return _markerView;
}

////////////////////////////////////////////////////////////////////////////////
- (void)animateView:(UIView *)view withIOMarkedAnimationFade:(IOMarkedAnimationFade)fadeInOrOut
{
    if (fadeInOrOut == IOMarkedAnimationFadeIn)
    {
        view.alpha = 0.0f;
        view.hidden = NO;
    }
    else
        view.alpha = 1.0f;
    
    [UIView animateWithDuration:kIOMarkedAnimationDuration animations:^{
        if (fadeInOrOut == IOMarkedAnimationFadeIn)
            view.alpha = 1.0f;
        else
            view.alpha = 0.0f;
    } completion:^(BOOL finished) {
        if (fadeInOrOut == IOMarkedAnimationFadeOut)
            view.hidden = YES;
    }];
}

////////////////////////////////////////////////////////////////////////////////
- (void)setMarked:(BOOL)marked animated:(BOOL)animated
{
    if (marked == _marked)
        return;
    
    _marked = marked;
    
    if (animated)
        [self animateView:self.markerView withIOMarkedAnimationFade:marked ? IOMarkedAnimationFadeIn : IOMarkedAnimationFadeOut];
    else
        self.markerView.hidden = !marked;
}

////////////////////////////////////////////////////////////////////////////////
- (void)setMarked:(BOOL)marked
{
    [self setMarked:marked animated:NO];
}

////////////////////////////////////////////////////////////////////////////////
- (void)willDisplay
{
}

////////////////////////////////////////////////////////////////////////////////
- (void)didEndDisplay
{
}

@end
