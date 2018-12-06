//
//  IOSpeciesCell.h
//  RedMap
//
//  Created by Evo Stamatov on 1/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOBaseCell.h"

@interface IOSpeciesCell : IOBaseCell

@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *subTitle;
@property (weak, nonatomic) IBOutlet UIImageView *image;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end
