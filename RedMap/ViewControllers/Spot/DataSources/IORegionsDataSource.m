//
//  IORegionsDataSource.m
//  RedMap
//
//  Created by Evo Stamatov on 18/06/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IORegionsDataSource.h"
#import "AppDelegate.h"
#import "Region.h"
#import "IORegionsController.h"
#import "IOSightingAttributesController.h"


@interface IORegionsDataSource ()

@end


@implementation IORegionsDataSource

@synthesize managedObjectContext = _managedObjectContext, regularController = _regularController;

- (id)initWithContext:(NSManagedObjectContext *)context
{
    self = [super init];
    
    if (self)
    {
        assert(context != nil);
        
        _managedObjectContext = context;
    }
    
    return self;
}



- (id <IOFetchedResultsProtocol>)regularController
{
    // Return the cached value if available
    if (_regularController != nil)
        return _regularController;
    
    _regularController = [[IORegionsController alloc] initWithContext:self.managedObjectContext searchString:nil];
    
    return _regularController;
}



#pragma mark - IOCommonListingDataSource protocol

- (NSInteger)numberOfRowsInSection:(NSInteger)section
{
    id <IOFetchedResultsProtocol>controller = [self regularController];
    return [controller numberOfRowsInSection:section];
}



- (id)objectAtIndexPath:(NSIndexPath *)indexPath
{
    id object = [super objectAtIndexPath:indexPath];
    
    if (object)
    {
        Region *region = (Region *)object;
        NSDictionary *result = @{
                                 kIOSightingEntryTitleKey: region.desc,
                                 kIOSightingEntryIDKey: region,
                                 //kIOSightingEntryCodeKey: [NSNull null],
                                 };
        return result;
    }
    
    return nil;
}



- (NSInteger)numberOfSections
{
    id <IOFetchedResultsProtocol>controller = [self regularController];
    return [controller numberOfSections];
}



#pragma mark - Custom methods

- (Region *)regionByNameOrSlugLookup:(NSString *)regionName
{
    IORegionsController *regionsController = (IORegionsController *)self.regularController;
    
    Region *region = [regionsController lookupByName:regionName];
    if (region == nil)
    {
        region = [regionsController lookupBySlug:regionName];
        
        if (region == nil)
            region = [regionsController lookupBySlug:[regionName lowercaseString]];
    }
    
    return region;
}

@end
