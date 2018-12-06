//
//  SpeciesDataSource.m
//  RedMap
//
//  Created by Evo Stamatov on 26/03/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "SpeciesDataSource.h"
#import "IOCategory.h"
#import "Species.h"
#import "IOSpotTableViewCell.h"
#import "IOSpeciesController.h"

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface SpeciesDataSource ()

@property (nonatomic, strong, readwrite) IOCategory *speciesCategory;
@property (nonatomic, strong) Region *region;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation SpeciesDataSource

@synthesize managedObjectContext = _managedObjectContext, regularController = _regularController, searchController = _searchController;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context category:(IOCategory *)category region:(Region *)regionOrNil
{
    self = [super init];
    
    if (self)
    {
        assert(category != nil);
        assert(context != nil);
        
        _managedObjectContext = context;
        _speciesCategory = category;
        _region = regionOrNil;
    }
    
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - IOSpotDataSource Protocol

- (BOOL)isSearchAvailable
{
    return YES;
}

/*
////////////////////////////////////////////////////////////////////////////////
- (void)scrollViewWillBeginDragging
{
    IOLog(@"Will begin dragging");
}

////////////////////////////////////////////////////////////////////////////////
- (void)scrollViewDidEndDraggingAndWillDecelerate:(BOOL)decelerate
{
    IOLog(@"Did end dragging and will decelerate: %@", decelerate ? @"Y" : @"N");
}

////////////////////////////////////////////////////////////////////////////////
- (void)scrollViewDidEndDecelerating
{
    IOLog(@"Did end decelerating");
}
 */

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - IOBaseDataSource overrides

- (id <IOFetchedResultsProtocol>)regularController
{
    // Return the cached value if available
    if (_regularController != nil)
        return _regularController;
    
    _regularController = [[IOSpeciesController alloc] initWithContext:self.managedObjectContext region:self.region category:self.speciesCategory searchString:nil];
    
    return _regularController;
}

////////////////////////////////////////////////////////////////////////////////
- (id <IOFetchedResultsProtocol>)searchController
{
    // Return the cached value if available
    if (_searchController != nil)
        return _searchController;
    
    if (![self.delegate respondsToSelector:@selector(searchBarText)])
    {
        // TODO: make this optional if no searchBar is set/available
        DDLogWarn(@"%@: You should implement the searchBarText method in your delegate, since you are requesting a searchFetchedResultsController", self.class);
        abort();
    }
    
    _searchController = [[IOSpeciesController alloc] initWithContext:self.managedObjectContext region:self.region category:self.speciesCategory searchString:[self.delegate searchBarText]];
    
    return _searchController;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - UITableViewDataSource Protocol overrides

- (void)configureTableView:(UITableView *)tableView cell:(IOSpotTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    //cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    Species *species = (Species *)[self objectAtIndexPath:indexPath];
    
    if (species)
    {
        cell.title = species.commonName;
        cell.subTitle = species.speciesName;
        
        //if (!tableView.dragging && !tableView.decelerating)
            [cell loadImageFromURL:species.pictureUrl];
    }
}

@end
