//
//  CategoriesDataSource.m
//  RedMap
//
//  Created by Evo Stamatov on 26/03/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "CategoriesDataSource.h"
#import "AppDelegate.h"
#import "IOCategory.h"
#import "IOSpotTableViewCell.h"
#import "IOAuth.h"

#import "IORedMapThemeManager.h"

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

@interface CategoriesDataSource ()

@property (nonatomic, strong, readwrite) Region *region;

@end


@implementation CategoriesDataSource

@synthesize managedObjectContext = _managedObjectContext, regularController = _regularController, searchController = _searchController;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context region:(Region *)regionOrNil
{
    self = [super init];
    
    if (self)
    {
        assert(context != nil);
        
        _managedObjectContext = context;
        _region = regionOrNil;
    }
    
    return self;
}



- (NSUInteger)heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 73.0;
}



- (id <IOFetchedResultsProtocol>)regularController
{
    // Return the cached value if available
    if (_regularController != nil)
        return _regularController;
    
    _regularController = [[IOCategoriesController alloc] initWithContext:self.managedObjectContext region:self.region searchString:nil];
    
    return _regularController;
}



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
    
    _searchController = [[IOCategoriesController alloc] initWithContext:self.managedObjectContext region:self.region searchString:[self.delegate searchBarText]];
    
    return _searchController;
}



- (void)configureTableView:(UITableView *)tableView cell:(IOSpotTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    //cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    IOCategory *category = (IOCategory *)[self.currentController objectAtIndexPath:indexPath];
    
    if (category)
    {
        cell.title = category.desc;
        //cell.subTitle = category.longDesc;
        
        [cell loadImageFromURL:category.pictureUrl];
    }
}

@end
