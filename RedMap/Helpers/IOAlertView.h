//
//  IOAlertView.h
//  Redmap
//
//  Created by Evo Stamatov on 7/03/2014.
//  Copyright (c) 2014 Ionata. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IOAlertView : UIAlertView

+ (instancetype)alertViewWithSpinnerAndTitle:(NSString *)title;

+ (instancetype)alertViewWithProgressBarAndTitle:(NSString *)title;
- (void)setProgress:(float)progress animated:(BOOL)animated;

- (void)dismissAnimated:(BOOL)animated;

@end
