//
//  IOCommentVC.m
//  RedMap
//
//  Created by Evo Stamatov on 6/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOCommentVC.h"
#import "IOLoggingCellControllerKeys.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface IOCommentVC ()

@property (nonatomic, strong) UIView *topBorder;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation IOCommentVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.text)
        self.commentText.text = self.text;
    
}

////////////////////////////////////////////////////////////////////////////////
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

////////////////////////////////////////////////////////////////////////////////
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

////////////////////////////////////////////////////////////////////////////////
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (self.topBorder == nil)
    {
        self.view.translatesAutoresizingMaskIntoConstraints = YES;
        self.topBorder = [[UIView alloc] init];
        self.topBorder.backgroundColor = [UIColor colorWithRed:160/255.0f
                                                         green:160/255.0f
                                                          blue:160/255.0f
                                                         alpha:1.0f];
        [self.view addSubview:self.topBorder];
    }
    
    CGRect frame = self.commentText.frame;
    frame.size.height = 1.0f;
    self.topBorder.frame = frame;
    
    if (iOS_7_OR_LATER())
    {
        UIEdgeInsets insets = self.commentText.contentInset;
        insets.top = 0;
        self.commentText.contentInset = insets;
    }
    [self.view layoutSubviews];
}

////////////////////////////////////////////////////////////////////////////////
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.commentText becomeFirstResponder];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [self.commentText resignFirstResponder];
    
    self.text = self.commentText.text;
    
    if ([[segue identifier] isEqualToString:@"ReturnCommentInput"])
        [self.delegate acceptedSelection:@{ kIOCommentKey: self.text }];
    else if ([[segue identifier] isEqualToString:@"CancelInput"] && [self.delegate respondsToSelector:@selector(cancelled)])
        [self.delegate cancelled];
}

@end
