//
//  IOMeasurementTVC.m
//  RedMap
//
//  Created by Evo Stamatov on 22/04/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOMeasurementTVC.h"
#import "IOSightingAttributesController.h"                                      // just for NSDictionary's title
#import "IOLoggingCellControllerKeys.h"


@interface IOMeasurementTVC ()

@property (assign) BOOL negative;

@end


@implementation IOMeasurementTVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Set the navigation bar title
    if (self.title)
    {
        if (self.navigationTitle)
            self.navigationItem.title = self.navigationTitle;
        else
        {
            if (self.units)
                self.navigationItem.title = [self.title stringByAppendingFormat:@" in %@", self.units];
            else
                self.navigationItem.title = self.title;
        }
    }
    
    // Set the placeholder
    if (self.placeholder)
        self.measurementInput.placeholder = self.placeholder;
    else if (self.title)
        self.measurementInput.placeholder = self.navigationItem.title;
    else
        self.measurementInput.placeholder = nil;
    
    // Set the value if any
    if (self.value)
    {
        if (self.value < 0)
        {
            self.negative = YES;
            [self.negativeSwitch setOn:YES animated:NO];
        }
        self.measurementInput.text = [@(self.value) stringValue];
    }
    
    if (self.methods)
    {
        // remove all dummy methods
        [self.methodsSegment removeAllSegments];
        
        __weak IOMeasurementTVC *weakSelf = self;
        __weak UISegmentedControl *weakMethodsSegmet = self.methodsSegment;
        __block NSUInteger selectedIndex = -1;
        
        // add the measurement methods
        [self.methods enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSDictionary *method = (NSDictionary *)obj;
            if ([weakSelf.method isEqual:obj])
                selectedIndex = idx;
            [weakMethodsSegmet insertSegmentWithTitle:method.title atIndex:idx animated:NO];
        }];
        
        // highlight the selected method
        if (selectedIndex != -1)
            [self.methodsSegment setSelectedSegmentIndex:selectedIndex];
        
        // catch control events
        [self.methodsSegment addTarget:self action:@selector(action:) forControlEvents:UIControlEventValueChanged];
    }
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.measurementInput becomeFirstResponder];
}



#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [self.measurementInput resignFirstResponder];
    
    self.value = [self.measurementInput.text floatValue];

    if ([[segue identifier] isEqualToString:@"ReturnMeasurementInput"])
    {
        [self.delegate acceptedSelection:@{
             kIOMeasurementValueKey: @(self.value),
             kIOMeasurementMethodKey: self.method == nil ? [NSNull null] : self.method,
         }];
    }
    else if ([[segue identifier] isEqualToString:@"CancelInput"] && [self.delegate respondsToSelector:@selector(cancelled)])
        [self.delegate cancelled];
}



#pragma mark - Table view delegate and source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int value = 1;
    
    if (!self.hiddenMethodsSegment)
        value++;
    
    if (self.visibleNegativeSwitch)
        value++;
    
    return value;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:[self alternateIndexPathForIndexPath:indexPath]];
    return cell;
}



- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [super tableView:tableView heightForRowAtIndexPath:[self alternateIndexPathForIndexPath:indexPath]];
}



#pragma mark - TextInput delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];

    static NSString *emptyString = @"";
    static NSString *emptyNegativeString = @"-";
    
    if ([newString isEqualToString:emptyString])
    {
        self.negative = NO;
        [self.negativeSwitch setOn:NO animated:YES];
    }
    
    if ([newString isEqualToString:emptyString] || [newString isEqualToString:emptyNegativeString])
        return YES;

    NSScanner *sc = [NSScanner scannerWithString:newString];
    
    if ([sc scanFloat:NULL])
        return [sc isAtEnd];
    
    return NO;
    
//    [self applyOrRemoveNegativeSymbol];
}



- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    self.negative = NO;
    [self.negativeSwitch setOn:NO animated:YES];
    
    return YES;
}



#pragma mark - IBActions

- (IBAction)switchNegative:(id)sender
{
    UISwitch *negativeSwitch = (UISwitch *)sender;
    self.negative = [negativeSwitch isOn];
    [self applyOrRemoveNegativeSymbol];
}



#pragma mark - Custom methods

- (void)applyOrRemoveNegativeSymbol
{
    if ([self.measurementInput.text isEqualToString:@""])
        return;
    
    self.measurementInput.text = [self.measurementInput.text stringByReplacingOccurrencesOfString:@"-" withString:@""];

    if (self.negative)
        self.measurementInput.text = [NSString stringWithFormat:@"-%@", self.measurementInput.text];
}



- (NSIndexPath *)alternateIndexPathForIndexPath:(NSIndexPath *)indexPath
{
    int row = indexPath.row;
    
    if (self.visibleNegativeSwitch && self.hiddenMethodsSegment && row == 1)
        row = 2;
    
    NSIndexPath *ip = [NSIndexPath indexPathForItem:row inSection:indexPath.section];
    return ip;
}



#pragma mark - Programmatical actions

- (void)action:(id)sender
{
    if (![sender isEqual:self.methodsSegment])
        return;
    
    self.method = [self.methods objectAtIndex:[self.methodsSegment selectedSegmentIndex]];
}

@end
