//
//  IOLocationCell.m
//  RedMap
//
//  Created by Evo Stamatov on 2/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOLocationCell.h"
#import "IOBaseCell.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface IOLocationCell ()

@property (nonatomic, strong) UIImageView *checkedView;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation IOLocationCell

- (UIImageView *)checkedView
{
    if (_checkedView == nil)
    {
        UIImage *checkedImage = [UIImage imageNamed:@"blue-marker"];
        UIImageView *view = [[UIImageView alloc] initWithImage:checkedImage];
        // fix marker position on iOS7
        CGFloat x = self.contentView.frame.origin.x;
        if (iOS_7_OR_LATER())
            x += 8.f;
        CGRect frame = CGRectMake(
                                  x - checkedImage.size.width / 2,
                                  (self.contentView.frame.size.height - checkedImage.size.height) / 2,
                                  checkedImage.size.width,
                                  checkedImage.size.height
                                  );
        view.frame = frame;
        _checkedView = view;
        [self addSubview:_checkedView];
    }
    
    return _checkedView;
}

////////////////////////////////////////////////////////////////////////////////
- (void)setMarkedAsUnchecked:(BOOL)markedAsUnchecked animated:(BOOL)animated
{
    if (markedAsUnchecked == _markedAsUnchecked)
        return;
    
    _markedAsUnchecked = markedAsUnchecked;
    
    if (animated)
        [self animateView:self.checkedView withIOMarkedAnimationFade:markedAsUnchecked ? IOMarkedAnimationFadeIn : IOMarkedAnimationFadeOut];
    else
        self.checkedView.hidden = !markedAsUnchecked;
}

////////////////////////////////////////////////////////////////////////////////
- (void)setMarkedAsUnchecked:(BOOL)markedAsUnchecked
{
    [self setMarkedAsUnchecked:markedAsUnchecked animated:NO];
}

@end
