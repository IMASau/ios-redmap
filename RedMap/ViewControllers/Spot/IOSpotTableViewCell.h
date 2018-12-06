//
//  IOSpotTableViewCell.h
//  RedMap
//
//  Created by Evo Stamatov on 30/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IOSpotTableViewCell : UITableViewCell

@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *subTitle;
@property (strong, nonatomic) UIImage *image;

- (void)initialSetup;
- (void)loadImageFromURL:(NSString *)url;

@end
