//
//  IOSpotTableViewCell.m
//  RedMap
//
//  Created by Evo Stamatov on 30/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOSpotTableViewCell.h"
#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import "UIColor+IOColor.h"
#import "IOSpotImageView.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface IOSpotTableViewCell ()
{
    BOOL _readyToInit;
    BOOL _initialized;
    
    CGFloat _defaultSubTitleHeightContant;
    CGFloat _defaultImageViewWidthConstant;
}

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subTitleLabel;
@property (weak, nonatomic) IBOutlet IOSpotImageView *theImageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *imageActivityIndicator;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *contentActivityIndicator;

// Constraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *subTitleHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageViewWidthConstraint;

@property (strong, nonatomic) NSArray *subTitleHeightEqualConstraints;
@property (copy, nonatomic) NSString *UUID;                                     // a random value holder for loadImageFromURL callback

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation IOSpotTableViewCell

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
    {
        _readyToInit = YES;
        _title = nil;
        _subTitle = nil;
        _image = nil;
    }
    
    return self;
}

////////////////////////////////////////////////////////////////////////////////
- (void)prepareForReuse
{
    [super prepareForReuse];
    
    _readyToInit = YES;
    _initialized = NO;
    _title = nil;
    _subTitle = nil;
    _image = nil;
    
    if (self.subTitleHeightEqualConstraints)
    {
        [self.subTitleLabel removeConstraints:self.subTitleHeightEqualConstraints];
        self.subTitleHeightEqualConstraints = nil;
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Custom Methods

- (void)initialSetup
{
    self.theImageView.image = nil;
    
    if (_readyToInit && !_initialized)
    {
        _initialized = YES;
        
        _defaultSubTitleHeightContant = self.subTitleHeightConstraint.constant;
        _defaultImageViewWidthConstant = self.imageViewWidthConstraint.constant;
        
        self.title = nil;
        self.subTitle = nil;
        
        self.theImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.theImageView.image = [UIImage imageNamed:@"no-image"];
        [self.theImageView setPersistentBackgroundColor:[UIColor IODarkGreyColor]];
        
        self.imageActivityIndicator.hidesWhenStopped = YES;
        [self.imageActivityIndicator stopAnimating];
        
        self.contentActivityIndicator.hidesWhenStopped = YES;
        [self.contentActivityIndicator stopAnimating];
    }
}

////////////////////////////////////////////////////////////////////////////////
- (void)setTitle:(NSString *)title
{
    _title = [title copy];
    self.titleLabel.text = _title;
}

////////////////////////////////////////////////////////////////////////////////
- (void)setSubTitle:(NSString *)subTitle
{
    BOOL empty = (subTitle == nil || [subTitle isEqualToString:@""]);
    
    /*
    if (empty)
    {
        // allow the addition of equal height constraints
        self.subTitleHeightConstraint.constant = 0;
        
        // add an equal height constraint, because the subTitleHeightConstraint is >= related
        UILabel *refLabel = self.subTitleLabel;
        self.subTitleHeightEqualConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[refLabel(0)]"
                                                                                      options:0
                                                                                      metrics:nil
                                                                                        views:NSDictionaryOfVariableBindings(refLabel)];
        [self.subTitleLabel addConstraints:self.subTitleHeightEqualConstraints];
    }
    else
    {
        // remove the custom constraint before we revert the >= related one
        if (self.subTitleHeightEqualConstraints)
        {
            [self.subTitleLabel removeConstraints:self.subTitleHeightEqualConstraints];
            self.subTitleHeightEqualConstraints = nil;
        }
        
        // revert default constraint constant
        self.subTitleHeightConstraint.constant = _defaultSubTitleHeightContant;
    }
     */
    
    _subTitle = (empty ? @"empty" : [subTitle copy]);
    self.subTitleLabel.text = _subTitle;
    self.subTitleLabel.hidden = empty;
}

////////////////////////////////////////////////////////////////////////////////
- (void)loadImageFromURL:(NSString *)url
{
    [self.imageActivityIndicator startAnimating];
    
    NSString *uuid = [[NSUUID UUID] UUIDString];
    self.UUID = uuid;
    
    __weak IOSpotTableViewCell *weakSelf = self;
    [ApplicationDelegate.imageEngine loadImageFromURL:url successBlock:^(UIImage *image) {
        if (![weakSelf.UUID isEqualToString:uuid])
        {
            // bail out - the cell is reused
            //IOLog(@"UUID differs: %@ %@", self.UUID, uuid);
            return;
        }
        
        [weakSelf.imageActivityIndicator stopAnimating];
        
        [weakSelf.theImageView setPersistentBackgroundColor:[UIColor whiteColor]];
        weakSelf.theImageView.image = image;
    } errorBlock:^(NSError *error, NSInteger statusCode) {
        if (![weakSelf.UUID isEqualToString:uuid])
        {
            // bail out - the cell is reused
            //IOLog(@"UUID differs: %@ %@", self.UUID, uuid);
            return;
        }
        
        [weakSelf.imageActivityIndicator stopAnimating];
    }];
}

@end
