//
//  IODateVC.m
//  RedMap
//
//  Created by Evo Stamatov on 23/04/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IODateVC.h"
#import "IOLoggingCellControllerKeys.h"

@implementation IODateVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.date)
        self.datePicker.date = self.date;
    
    if (self.minimumDate)
        self.datePicker.minimumDate = self.minimumDate;
    
    if (self.maximumDate)
        self.datePicker.maximumDate = self.maximumDate;
    
    UIBarButtonItem *todayButton =
        [[UIBarButtonItem alloc] initWithTitle:@"Today"
                                         style:UIBarButtonItemStyleBordered
                                        target:self
                                        action:@selector(goToToday:)];
    
    NSMutableArray *rightBarButtonItems =
        [self.navigationItem.rightBarButtonItems mutableCopy];
    [rightBarButtonItems addObject:todayButton];
        self.navigationItem.rightBarButtonItems = rightBarButtonItems;
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - Private Methods

- (void)goToToday:(id)sender
{
    [self.datePicker setDate:[NSDate date] animated:YES];
}



#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"ReturnDateInput"])
        [self.delegate acceptedSelection:@{ kIOTimeDateKey: self.datePicker.date }];
    else if ([[segue identifier] isEqualToString:@"CancelInput"] && [self.delegate respondsToSelector:@selector(cancelled)])
        [self.delegate cancelled];
}

@end
