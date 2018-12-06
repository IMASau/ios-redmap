//
//  IOViewCurlButton.m
//  RedMap
//
//  Created by Evo Stamatov on 17/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOViewCurlButton.h"


@interface IOViewCurlButton ()

@property (strong, nonatomic) UISwipeGestureRecognizer *leftSwipeGesture;
@property (strong, nonatomic) UISwipeGestureRecognizer *upSwipeGesture;

@end


@implementation IOViewCurlButton

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        self.leftSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(gestureRecognizerHandler:)];
        self.leftSwipeGesture.numberOfTouchesRequired = 1;
        self.leftSwipeGesture.direction = UISwipeGestureRecognizerDirectionLeft;
        
        self.upSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(gestureRecognizerHandler:)];
        self.upSwipeGesture.numberOfTouchesRequired = 1;
        self.upSwipeGesture.direction = UISwipeGestureRecognizerDirectionUp;
        
        [self addGestureRecognizer:self.leftSwipeGesture];
        [self addGestureRecognizer:self.upSwipeGesture];
    }
    return self;
}



- (void)gestureRecognizerHandler:(UISwipeGestureRecognizer *)recognizer
{
    [self sendActionsForControlEvents:UIControlEventTouchUpInside];
}

@end
