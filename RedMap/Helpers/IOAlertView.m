//
//  IOAlertView.m
//  Redmap
//
//  Created by Evo Stamatov on 7/03/2014.
//  Copyright (c) 2014 Ionata. All rights reserved.
//

#import "IOAlertView.h"

@implementation IOAlertView
{
    UIProgressView *_progressView;
    UIActivityIndicatorView *_spinner;
}

+ (instancetype)alertViewWithSpinnerAndTitle:(NSString *)title
{
    IOAlertView *loading = [[self alloc] initWithSpinnerAndTitle:title];
    return loading;
}

+ (instancetype)alertViewWithProgressBarAndTitle:(NSString *)title
{
    return [[self alloc] initWithProgressBarAndTitle:title];
}

- (void)dealloc
{
    if (_spinner)
    {
        [_spinner removeFromSuperview];
        _spinner = nil;
    }
    
    if (_progressView)
    {
        [_progressView removeFromSuperview];
        _progressView = nil;
    }
}

- (instancetype)initWithSpinnerAndTitle:(NSString *)title
{
    self = [super initWithTitle:title
                        message:nil
                       delegate:nil
              cancelButtonTitle:nil
              otherButtonTitles:nil];
    if (self)
    {
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [_spinner startAnimating];
        _spinner.center = CGPointMake(140.0, 70.0);
        [self addSubview:_spinner];
    }
    return self;
}

- (instancetype)initWithProgressBarAndTitle:(NSString *)title
{
    self = [self initWithSpinnerAndTitle:title];
    if (self)
    {
        _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        _progressView.frame = CGRectMake(0, 0, 200.f, 0.f);
        _progressView.center = CGPointMake(140.0, 70.0);
        _progressView.progress = 0.0;
        _progressView.hidden = YES;
        [self addSubview:_progressView];
    }
    return self;
}

- (void)setProgress:(float)progress animated:(BOOL)animated
{
    if (_progressView.hidden)
        _progressView.hidden = NO;
    
    if (_spinner)
    {
        [_spinner removeFromSuperview];
        _spinner = nil;
    }
    
    if (_progressView)
        [_progressView setProgress:progress animated:animated];
}

- (void)dismissAnimated:(BOOL)animated
{
    [self dismissWithClickedButtonIndex:self.cancelButtonIndex animated:animated];
}

@end
