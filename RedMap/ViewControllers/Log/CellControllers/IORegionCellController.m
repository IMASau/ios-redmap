//
//  IORegionCellController.m
//  Redmap
//
//  Created by Lidiya Stamatova on 16/08/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IORegionCellController.h"
#import "IOCommonListingTVC.h"
#import "IORegionsDataSource.h"
#import "Region.h"
#import "IOSightingAttributesController.h"
#import "IOGeoLocation.h"
#import "IORegionCell.h"


@interface IORegionCellController ()
{
    BOOL _dirty;
}

@property (nonatomic, strong) IORegionsDataSource *regionsDataSource;
@property (nonatomic, strong) Region *region;
@property (nonatomic, assign) BOOL gaveUp;

@property (nonatomic, weak) NSManagedObjectContext *managedObjectContext;

@end


@implementation IORegionCellController

#pragma mark - Overrides

- (id)initWithSettings:(NSDictionary *)settings delegate:(id<IOBaseCellControllerDelegate>)delegate managedObjectContext:(NSManagedObjectContext *)context
{
    self = [super initWithSettings:settings delegate:delegate];
    if (self)
    {
        _managedObjectContext = context;
        _regionsDataSource = [[IORegionsDataSource alloc] initWithContext:_managedObjectContext];
        
        if (self.managedObjectValue != nil)
        {
            _region = self.managedObjectValue;
        }
        else if (_region == nil && ![IOSightingAttributesController shouldAutodetectRegion])
        {
            // Bypass the tableView update by directly setting the ivar, not using self.region
            _region = [_regionsDataSource regionByNameOrSlugLookup:[IOSightingAttributesController userPreSelectedRegionName]];
            self.managedObjectValue = _region;
        }
        else if (_region == nil)
        {
            IOGeoLocation *geo = [IOGeoLocation sharedInstance];
            if (geo.regionAcquired)
            {
                _region = [_regionsDataSource regionByNameOrSlugLookup:geo.region];
                self.managedObjectValue = _region;
            }
            
            // Use the notification center instead of a delegate, since there are other cells that will use the IOGeoLocation shared instance
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(geoLocationRegionAcquiredNotification:) name:kIOGeoLocationRegionAcquiredNotification object:nil];
            
            [geo updateIfNeeded];
        }
        
        // TODO: add user defaults observer to monitor region change
        /*
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onDefaultsChanged:)
                                                     name:NSUserDefaultsDidChangeNotification
                                                   object:nil];
         */
    }
    return self;
}



- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
#if TRACK
    [GoogleAnalytics sendEventWithCategory:@"uiAction" withAction:@"cellSelect" withLabel:[NSString stringWithFormat:@"Listing - %@", self.managedObjectKey] withValue:@1];
#endif
    
    IOCommonListingTVC *vc = (IOCommonListingTVC *)[segue destinationViewController];
    vc.delegate = self;
    vc.dataSource = self.regionsDataSource;
    vc.selectedValue = self.region;
    vc.navigationTitle = @"Choose sighting region";
    
    if ([self.delegate respondsToSelector:@selector(setHidesBottomBarWhenPushed:)])
        [self.delegate setHidesBottomBarWhenPushed:YES];
}



- (void)configureTableViewCell:(IOBaseCell *)cell
{
    //[super configureTableViewCell:cell];
    self.connectedTableViewCell = cell;
    [self updateCell:(IORegionCell *)cell];
}



- (BOOL)isDirty
{
    return _dirty;
}



#pragma mark - IOCellConnection

- (void)acceptedSelection:(NSDictionary *)object
{
    _dirty = YES;
    self.region = object.ID; // which should hold a Region object
}



#pragma mark - Custom methods

- (void)updateCell:(IORegionCell *)cell
{
    if (!cell)
        cell = (IORegionCell *)self.connectedTableViewCell;
    
    cell.activityIndicator.hidesWhenStopped = YES;
    if (self.region)
    {
        cell.detailLabel.text = self.region.desc;
        [cell.activityIndicator stopAnimating];
    }
    else if (self.gaveUp)
    {
        cell.detailLabel.text = @"(unable to detect)";
        [cell.activityIndicator stopAnimating];
    }
    else
    {
        cell.detailLabel.text = nil;
        [cell.activityIndicator startAnimating];
    }
}



#pragma mark - Setters and Getters

- (void)setRegion:(Region *)region
{
    if (_region == region)
        return;
    
    _region = region;
    
    if (region != nil)
    {
        //_changingUserDefaults = YES;
        [[NSUserDefaults standardUserDefaults] setObject:region.desc forKey:kIOUserDefaultsRegionKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        //_changingUserDefaults = NO;
        
        [self updateCell:nil];
    }
    
    self.managedObjectValue = region;
}



#pragma mark - Notifications

- (void)geoLocationRegionAcquiredNotification:(NSNotification *)aNotification
{
    IOGeoLocation *geo = [[aNotification userInfo] objectForKey:kIOGeoLocationObject]; // should be the same as [IOGeoLocation sharedInstance]
    self.region = [self.regionsDataSource regionByNameOrSlugLookup:geo.region];
    
    if (self.region != nil)
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (self.region == nil && geo.finalCall)
    {
        self.gaveUp = YES;
        [self updateCell:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}



- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
