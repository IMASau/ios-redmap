//
//  IORegionCell.h
//  RedMap
//
//  Created by Evo Stamatov on 30/04/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOBaseCell.h"

@interface IORegionCell : IOBaseCell

@property (weak, nonatomic) IBOutlet UILabel *detailLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end
