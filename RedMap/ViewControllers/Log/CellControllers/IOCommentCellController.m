//
//  IOCommentCellController.m
//  Redmap
//
//  Created by Evo Stamatov on 20/08/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOCommentCellController.h"
#import "IOCommentVC.h"
#import "IOCommentCell.h"
#import "IOLoggingCellControllerKeys.h"

@implementation IOCommentCellController

- (void)configureTableViewCell:(IOBaseCell *)aCell
{
    [super configureTableViewCell:aCell];
    IOCommentCell *cell = (IOCommentCell *)aCell;
    cell.commentTextView.text = self.managedObjectValue;
}



- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
#if TRACK
    [GoogleAnalytics sendEventWithCategory:@"uiAction" withAction:@"cellSelect" withLabel:self.managedObjectKey withValue:@1];
#endif
    
    IOCommentVC *vc = (IOCommentVC *)[segue destinationViewController];
    vc.text = self.managedObjectValue;
    vc.delegate = self;
    
    if ([self.delegate respondsToSelector:@selector(setHidesBottomBarWhenPushed:)])
        [self.delegate setHidesBottomBarWhenPushed:YES];
}



#pragma mark - IOCellConnection Protocol

- (void)acceptedSelection:(NSDictionary *)object
{
    [super acceptedSelection:object];
    
    self.managedObjectValue = [object objectForKey:kIOCommentKey];
    [self configureTableViewCell:self.connectedTableViewCell];
}

@end
