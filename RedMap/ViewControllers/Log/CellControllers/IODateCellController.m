//
//  IODateCellController.m
//  Redmap
//
//  Created by Evo Stamatov on 19/08/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IODateCellController.h"
#import "IODateVC.h"
#import "IOLoggingCellControllerKeys.h"


@interface IODateCellController ()

@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSCalendar *calendar;
@property (nonatomic, strong) NSDate *selectedDate;
@property (nonatomic, strong) NSDate *minimumDate;
@property (nonatomic, strong) NSDate *maximumDate;

@end


@implementation IODateCellController

- (id)initWithSettings:(NSDictionary *)settings delegate:(id<IOBaseCellControllerDelegate>)delegate
{
    self = [super initWithSettings:settings delegate:delegate];
    if (self)
    {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        [_dateFormatter setDateStyle:NSDateFormatterMediumStyle];

        _calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    }
    return self;
}



- (void)configureTableViewCell:(IOBaseCell *)cell
{
    [super configureTableViewCell:cell];
    NSDate *date = self.managedObjectValue;
    cell.detailTextLabel.text = [self.dateFormatter stringFromDate:date];
}



- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
#if TRACK
    [GoogleAnalytics sendEventWithCategory:@"uiAction" withAction:@"cellSelect" withLabel:self.managedObjectKey withValue:@1];
#endif
    
    IODateVC *vc = (IODateVC *)[segue destinationViewController];
    vc.delegate = self;
    
    // make sure we've got the latest value
    self.selectedDate = (NSDate *)self.managedObjectValue;
    
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    
    NSDate *date = self.managedObjectValue;
    
    NSDate *today = [NSDate date];
    dateComponents.year = -1;
    NSDate *minimumDate =[self.calendar dateByAddingComponents:dateComponents
                                                        toDate:today
                                                       options:0];
    dateComponents.year = 0;
    dateComponents.day = 0;
    NSDate *maximumDate = [self.calendar dateByAddingComponents:dateComponents
                                                         toDate:today
                                                        options:0];
    vc.date = date;
    vc.minimumDate = minimumDate;
    vc.maximumDate = maximumDate;
    
    if ([self.delegate respondsToSelector:@selector(setHidesBottomBarWhenPushed:)])
        [self.delegate setHidesBottomBarWhenPushed:YES];
}



#pragma mark - IOCellConnection Protocol

- (void)acceptedSelection:(NSDictionary *)object
{
    [super acceptedSelection:object];
    
    NSDate *date = [object objectForKey:kIOTimeDateKey];
    self.managedObjectValue = date;
    
    [self configureTableViewCell:self.connectedTableViewCell];
}

@end
