//
//  IOLocationCell.h
//  RedMap
//
//  Created by Evo Stamatov on 2/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOBaseCell.h"

@interface IOLocationCell : IOBaseCell

@property (weak, nonatomic) IBOutlet UILabel *detailLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (nonatomic, assign) BOOL markedAsUnchecked;
- (void)setMarkedAsUnchecked:(BOOL)markedAsUnchecked animated:(BOOL)animated;

@end
