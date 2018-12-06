//
//  IOLocationCellController.m
//  Redmap
//
//  Created by Evo Stamatov on 19/08/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOLocationCellController.h"

#import "IOGeoLocation.h"
#import "IOLocationCell.h"
#import "IOLocationVC.h"
#import "IOLoggingCellControllerKeys.h"
#import "IOMapRegionObject.h"
#import "IORegionsDataSource.h"
#import "IOSightingAttributesController.h"
#import "Region.h"
#import "Sighting-typedefs.h"
#import "Sighting.h"

static BOOL IOAcquiredLocationChecked = NO;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface IOLocationCellController ()

@property (nonatomic, assign) CGFloat lat;
@property (nonatomic, assign) CGFloat lng;
@property (nonatomic, assign) CGFloat accuracy;
@property (nonatomic, assign) IOSightingLocationStatus status;
@property (nonatomic, weak) Region *region;
@property (nonatomic, strong) IORegionsDataSource *regionDataSource;
@property (nonatomic, strong) IOMapRegionObject *savedVisibleMapRegion;

@property (nonatomic, weak) NSManagedObjectContext *managedObjectContext;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation IOLocationCellController

- (id)initWithSettings:(NSDictionary *)settings delegate:(id<IOBaseCellControllerDelegate>)delegate managedObjectContext:(NSManagedObjectContext *)context
{
    self = [self initWithSettings:settings delegate:delegate];
    if (self && self.status == IOSightingLocationStatusNotSet)
    {
        _managedObjectContext = context;
        
        IOGeoLocation *geo = [IOGeoLocation sharedInstance];
        
        if (geo.locationAcquired)
            [self updateManagedObjectLocationLatitude:geo.lat longitude:geo.lng accuracy:geo.accuracy status:IOSightingLocationStatusAcquired];
        
        // Use the notification center instead of a delegate, since there are other cells that will use the IOGeoLocation shared instance
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(geoLocationAcquiredNotification:) name:kIOGeoLocationAcquiredNotification object:nil];
        
        if (self.region == nil && geo.regionAcquired)
        {
            self.regionDataSource = [[IORegionsDataSource alloc] initWithContext:self.managedObjectContext];
            self.region = [self.regionDataSource regionByNameOrSlugLookup:geo.region];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(geoLocationRegionAcquiredNotification:) name:kIOGeoLocationRegionAcquiredNotification object:nil];
        }
        
        [geo updateIfNeeded];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Overrides

- (void)configureTableViewCell:(IOBaseCell *)aCell
{
    [super configureTableViewCell:aCell];
    IOLocationCell *cell = (IOLocationCell *)aCell;
    cell.activityIndicator.hidesWhenStopped = YES;
    [self updateCell:cell];
}

////////////////////////////////////////////////////////////////////////////////
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
#if TRACK
    [GoogleAnalytics sendEventWithCategory:@"uiAction" withAction:@"cellSelect" withLabel:@"Location" withValue:@1];
#endif
    
    IOLocationVC *vc = (IOLocationVC *)[segue destinationViewController];
    vc.locationCoordinate = CLLocationCoordinate2DMake(self.lat, self.lng);
    vc.locationAccuracyInMetres = self.accuracy;
    if (self.region)
        vc.regionName = self.region.desc;
    vc.delegate = self;
    
    vc.unconfirmed = !IOAcquiredLocationChecked;
    
    if (self.savedVisibleMapRegion)
        vc.visibleMapRegion = self.savedVisibleMapRegion;
    
    if (self.managedObjectKeys[kIOLocationAccuracyCategoryKey])
        vc.accuracySegments = [[IOSightingAttributesController sharedInstance] entriesForCategory:self.managedObjectKeys[kIOLocationAccuracyCategoryKey]];
    
    if ([self.delegate respondsToSelector:@selector(setHidesBottomBarWhenPushed:)])
        [self.delegate setHidesBottomBarWhenPushed:YES];
}

////////////////////////////////////////////////////////////////////////////////
- (void)willDisplayTableViewCell:(IOBaseCell *)cell
{
    [super willDisplayTableViewCell:cell];
    
    IOLocationCell *locationCell = (IOLocationCell *)cell;
    locationCell.markedAsUnchecked = _markedAsUnChecked;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - iVars

- (CGFloat)lat
{
    return [[self.delegate getManagedObjectDataForKey:self.managedObjectKeys[kIOLocationLatitudeKey]] floatValue];
}

////////////////////////////////////////////////////////////////////////////////
- (CGFloat)lng
{
    return [[self.delegate getManagedObjectDataForKey:self.managedObjectKeys[kIOLocationLongitudeKey]] floatValue];
}

////////////////////////////////////////////////////////////////////////////////
- (CGFloat)accuracy
{
    NSDictionary *accuracyObj = [self.delegate getManagedObjectDataForKey:self.managedObjectKeys[kIOLocationAccuracyKey]];
    return [accuracyObj.code floatValue];
}

////////////////////////////////////////////////////////////////////////////////
- (IOSightingLocationStatus)status
{
    return [[self.delegate getManagedObjectDataForKey:self.managedObjectKeys[kIOLocationStatusKey]] intValue];
}

////////////////////////////////////////////////////////////////////////////////
- (Region *)region
{
    return (Region *)[self.delegate getManagedObjectDataForKey:self.managedObjectKeys[kIOLocationRegionKey]];
}

////////////////////////////////////////////////////////////////////////////////
- (BOOL)acquiredLocationChecked
{
    return IOAcquiredLocationChecked;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Custom methods

- (void)updateManagedObjectLocationLatitude:(CLLocationDegrees)lat longitude:(CLLocationDegrees)lng accuracy:(CLLocationAccuracy)accuracy status:(IOSightingLocationStatus)status
{
    NSDictionary *accuracyObj = [[IOSightingAttributesController sharedInstance] accuracyEntryFromNearestHigherValue:accuracy];
    if (accuracyObj)
    {
        [self.delegate setManagedObjectDataWithKeyValueDictionary:@{
                   self.managedObjectKeys[kIOLocationLatitudeKey]:@(lat),
                  self.managedObjectKeys[kIOLocationLongitudeKey]:@(lng),
                   self.managedObjectKeys[kIOLocationAccuracyKey]:accuracyObj,
                     self.managedObjectKeys[kIOLocationStatusKey]:@(status),
         }];
        [self updateCell:nil];
    }
}

////////////////////////////////////////////////////////////////////////////////
- (void)updateCell:(IOLocationCell *)cell
{
    if (!cell)
        cell = (IOLocationCell *)self.connectedTableViewCell;
    
    if (self.status == IOSightingLocationStatusNotSet)
    {
        cell.detailLabel.text = nil;
        [cell.activityIndicator startAnimating];
    }
    else
    {
        [cell.activityIndicator stopAnimating];
        NSString *unit = @"m";
        CGFloat accuracy = self.accuracy;
        if (accuracy >= 1000)
        {
            accuracy /= 1000.0;
            unit = @"km";
        }
        
        cell.detailLabel.text = [NSString stringWithFormat:@"accurate to %.0f%@", accuracy, unit];
    }
}

////////////////////////////////////////////////////////////////////////////////
- (void)markTableViewCell:(IOBaseCell *)cell asUnChecked:(BOOL)markAsUnChecked animated:(BOOL)animated
{
    IOLocationCell *locationCell;
    
    _markedAsUnChecked = markAsUnChecked;
    
    if (cell)
        locationCell = (IOLocationCell *)cell;
    else
        locationCell = (IOLocationCell *)self.connectedTableViewCell;
    
    [locationCell setMarkedAsUnchecked:markAsUnChecked animated:animated];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma makr - IOCellConnection Protocol

- (void)acceptedSelection:(NSDictionary *)object
{
    [super acceptedSelection:object];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    CLLocationDegrees lat = [[object objectForKey:kIOLocationLatitudeKey] doubleValue];
    CLLocationDegrees lng = [[object objectForKey:kIOLocationLongitudeKey] doubleValue];
    CLLocationAccuracy accuracy = [[object objectForKey:kIOLocationAccuracyKey] doubleValue];
    
    self.savedVisibleMapRegion = (IOMapRegionObject *)[object objectForKey:@"visibleMapRegion"];
    
    IOAcquiredLocationChecked = YES;
    
    [self updateManagedObjectLocationLatitude:lat longitude:lng accuracy:accuracy status:IOSightingLocationStatusManuallySet];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Notifications

- (void)geoLocationAcquiredNotification:(NSNotification *)aNotification
{
    IOGeoLocation *geo = [[aNotification userInfo] objectForKey:kIOGeoLocationObject]; // should be the same as [IOGeoLocation sharedInstance]
    
    NSDictionary *accuracyObj = [[IOSightingAttributesController sharedInstance] accuracyEntryFromNearestHigherValue:geo.accuracy];
    if (accuracyObj)
        [self updateManagedObjectLocationLatitude:geo.lat longitude:geo.lng accuracy:geo.accuracy status:IOSightingLocationStatusAcquired];
}

////////////////////////////////////////////////////////////////////////////////
- (void)geoLocationRegionAcquiredNotification:(NSNotification *)aNotification
{
    IOGeoLocation *geo = [[aNotification userInfo] objectForKey:kIOGeoLocationObject]; // should be the same as [IOGeoLocation sharedInstance]
    
    self.region = [self.regionDataSource regionByNameOrSlugLookup:geo.region];
}

@end
