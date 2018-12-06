//
//  IOCommonListingCellController.m
//  Redmap
//
//  Created by Lidiya Stamatova on 16/08/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOCommonListingCellController.h"
#import "IOCommonListingTVC.h"
#import "IOSightingAttributesController.h"

@implementation IOCommonListingCellController

- (id)initWithSettings:(NSDictionary *)settings delegate:(id<IOBaseCellControllerDelegate>)delegate
{
    self = [super initWithSettings:settings delegate:delegate];
    
    if (self && self.settings[kIOLVCSetDefaultValue] && [self.settings[kIOLVCSetDefaultValue] boolValue] == YES && self.managedObjectKey != nil && self.managedObjectValue == nil)
        self.managedObjectValue = [[IOSightingAttributesController sharedInstance] defaultEntryForCategory:self.settings[kIOLVCPlistDataSource]];
    
    return self;
}



- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
#if TRACK
    [GoogleAnalytics sendEventWithCategory:@"uiAction" withAction:@"cellSelect" withLabel:[NSString stringWithFormat:@"Listing - %@", self.managedObjectKey] withValue:@1];
#endif
    
    IOCommonListingTVC *vc = (IOCommonListingTVC *)[segue destinationViewController];
    vc.delegate = self;
    if (self.settings[kIOLVCNavigationTitle])
        vc.navigationTitle = self.settings[kIOLVCNavigationTitle];
    vc.listingKey = self.settings[kIOLVCPlistDataSource];
    vc.selectedTitle = [self theManagedObjectTitle];
    
    if ([self.delegate respondsToSelector:@selector(setHidesBottomBarWhenPushed:)])
        [self.delegate setHidesBottomBarWhenPushed:YES];
}



- (void)configureTableViewCell:(IOBaseCell *)cell
{
    [super configureTableViewCell:cell];
    if (self.managedObjectKey)
        cell.detailTextLabel.text = [self theManagedObjectTitle];
}



#pragma mark - IOCellConnection Protocol

- (void)acceptedSelection:(NSDictionary *)object
{
    [super acceptedSelection:object];
    
    if (self.managedObjectKey)
    {
        self.managedObjectValue = object;
        self.connectedTableViewCell.detailTextLabel.text = [self theManagedObjectTitle];
    }
}



#pragma mark - Custom methods

- (NSString *)theManagedObjectTitle
{
    if (self.managedObjectKey)
        return [self.managedObjectValue objectForKey:kIOSightingEntryTitleKey];
    return nil;
}

@end
