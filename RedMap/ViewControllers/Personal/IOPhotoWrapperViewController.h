//
//  IOPhotoWrapperViewController.h
//  RedMap
//
//  Created by Evo Stamatov on 28/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IOPhotoWrapperViewController : UIViewController

@property (nonatomic, copy) NSString *sightingUUID;

@property (weak, nonatomic) IBOutlet UIImageView *mapImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *spottedOnLabel;
@property (weak, nonatomic) IBOutlet UIImageView *validatedOverlay;

@property (weak, nonatomic) IBOutlet UIView *overlayView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;

- (IBAction)shareButtonAction:(id)sender;

@end
