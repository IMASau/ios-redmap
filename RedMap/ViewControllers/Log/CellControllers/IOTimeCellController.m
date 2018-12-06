//
//  IOTimeCellController.m
//  Redmap
//
//  Created by Evo Stamatov on 19/08/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOTimeCellController.h"
#import "IOCommonListingTVC.h"
#import "IOSightingAttributesController.h"


@interface IOTimeCellController ()

@property (nonatomic, strong) NSDateFormatter *timeFormatter;
@property (nonatomic, strong) NSCalendar *calendar;
@property (nonatomic, strong) NSDate *selectedTime;
@property (assign) BOOL timeNotSure;

@end


@implementation IOTimeCellController

- (id)initWithSettings:(NSDictionary *)settings delegate:(id<IOBaseCellControllerDelegate>)delegate
{
    self = [super initWithSettings:settings delegate:delegate];
    if (self)
    {
        _timeFormatter = [[NSDateFormatter alloc] init];
        [_timeFormatter setTimeStyle:NSDateFormatterShortStyle];
        [_timeFormatter setDateStyle:NSDateFormatterNoStyle];
        
        _calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    }
    return self;
}



- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [super prepareForSegue:segue sender:sender];
    
    IOCommonListingTVC *vc = (IOCommonListingTVC *)[segue destinationViewController];
    vc.selectedTitle = nil;
    
    NSDictionary *timeObj = [self.delegate getManagedObjectDataForKey:self.managedObjectKeys[@"time"]];
    vc.selectedValue = timeObj.ID;
    
    if ([self.delegate respondsToSelector:@selector(setHidesBottomBarWhenPushed:)])
        [self.delegate setHidesBottomBarWhenPushed:YES];
}



- (void)configureTableViewCell:(IOBaseCell *)cell
{
    [super configureTableViewCell:cell];
    cell.detailTextLabel.text = [[self.delegate getManagedObjectDataForKey:self.managedObjectKeys[@"time"]] objectForKey:kIOSightingEntryTitleKey];
}



#pragma mark - IOCellConnection Protocol

- (void)acceptedSelection:(NSDictionary *)object
{
    [super acceptedSelection:object];
    
    BOOL timeNotSure = NO;
    if ([object.title isEqualToString:kIOTimeNotSureTitle])
        timeNotSure = YES;
        
    [self.delegate setManagedObjectDataForKey:self.managedObjectKeys[@"time"] withObject:object];
    [self.delegate setManagedObjectDataForKey:self.managedObjectKeys[@"timeNotSure"] withObject:@(timeNotSure)];
    
    [self configureTableViewCell:self.connectedTableViewCell];
}

@end
