//
//  IOMeasurementCellController.m
//  Redmap
//
//  Created by Evo Stamatov on 19/08/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOMeasurementCellController.h"
#import "IOMeasurementTVC.h"
#import "IOSightingAttributesController.h"
#import "IOLoggingCellControllerKeys.h"



@interface IOMeasurementCellController ()

@property (nonatomic, assign) CGFloat value;
@property (nonatomic, strong) NSDictionary *method;

@end


@implementation IOMeasurementCellController


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
#if TRACK
    [GoogleAnalytics sendEventWithCategory:@"uiAction" withAction:@"cellSelect" withLabel:[NSString stringWithFormat:@"Measurement - %@", self.managedObjectKeys[@"value"]] withValue:@1];
#endif
    
    IOMeasurementTVC *vc = (IOMeasurementTVC *)[segue destinationViewController];

    vc.title = self.settings[kIOMeasurementTitleKey];
    vc.units = self.settings[kIOMeasurementUnitsKey];
    
    if (self.settings[kIOLVCNavigationTitle])
        vc.navigationTitle = self.settings[kIOLVCNavigationTitle];
    
    if (self.settings[kIOMeasurementPlaceholderKey])
        vc.placeholder = self.settings[kIOMeasurementPlaceholderKey];
    
    CGFloat value = self.value;
    if (value != 0.0f)
        vc.value = value;
    
    if (!self.managedObjectKeys)
        vc.hiddenMethodsSegment = YES;
    else
    {
        vc.method = self.method;
        vc.methods = [[IOSightingAttributesController sharedInstance] entriesForCategory:self.managedObjectKeys[kIOMeasurementMethodCategoryKey]];
    }
    
    if (self.settings[kIOMeasurementVisibleNegativeSwitchKey])
        vc.visibleNegativeSwitch = YES;

    vc.delegate = self;
    
    if ([self.delegate respondsToSelector:@selector(setHidesBottomBarWhenPushed:)])
        [self.delegate setHidesBottomBarWhenPushed:YES];
}



- (void)configureTableViewCell:(IOBaseCell *)cell
{
    [super configureTableViewCell:cell];
    CGFloat value = self.value;
    if (value != 0.0f)
    {
        NSString *methodPart = @"";
        if (self.managedObjectKeys)
            methodPart = [NSString stringWithFormat:@" (%@)", self.method.title];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@%@%@", [@(value) stringValue], self.settings[kIOMeasurementUnitsKey], methodPart];
    }
    else
        cell.detailTextLabel.text = nil;
}



#pragma mark - Custom Getters and Setters

- (CGFloat)value
{
    if (self.managedObjectKey)
        return [self.managedObjectValue floatValue];
    else
        return [[self.delegate getManagedObjectDataForKey:self.managedObjectKeys[kIOMeasurementValueKey]] floatValue];
}



- (void)setValue:(CGFloat)value
{
    if (self.managedObjectKey)
        self.managedObjectValue = @(value);
    else
        [self.delegate setManagedObjectDataForKey:self.managedObjectKeys[kIOMeasurementValueKey] withObject:@(value)];
}



- (NSDictionary *)method
{
    NSDictionary *currentMethod = [self.delegate getManagedObjectDataForKey:self.managedObjectKeys[kIOMeasurementMethodKey]];
    if (!currentMethod)
        currentMethod = [[IOSightingAttributesController sharedInstance] defaultEntryForCategory:self.managedObjectKeys[kIOMeasurementMethodCategoryKey]];
    return currentMethod;
}



- (void)setMethod:(NSDictionary *)method
{
    [self.delegate setManagedObjectDataForKey:self.managedObjectKeys[kIOMeasurementMethodKey] withObject:method];
}



#pragma mark - IOCellConnection

- (void)acceptedSelection:(NSDictionary *)object
{
    [super acceptedSelection:object];
    
    NSDictionary *method = (NSDictionary *)[object objectForKey:kIOMeasurementMethodKey];
    if (![method isEqual:[NSNull null]])
        self.method = method;
    
    self.value = (CGFloat)[[object objectForKey:kIOMeasurementValueKey] floatValue];
    [self configureTableViewCell:self.connectedTableViewCell];
}

/*
#pragma mark - Custom methods

- (void)detectMinimumsAndMaximumsFromEntityDescription
{
    NSEntityDescription *sightignDescription = [NSEntityDescription entityForName:@"Sighting" inManagedObjectContext:context];
    id propertyObject = [sightignDescription.propertiesByName objectForKey:@"depth"];
    NSAttributeDescription *attributeDescription = (NSAttributeDescription *)propertyObject;
    NSArray *validationPredicates = attributeDescription.validationPredicates;
}
 */

@end
