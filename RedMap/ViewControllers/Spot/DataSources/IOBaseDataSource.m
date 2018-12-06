//
//  IOBaseDataSource.m
//  RedMap
//
//  Created by Evo Stamatov on 17/06/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOBaseDataSource.h"
#import "AppDelegate.h"
#import "IOSpotTableViewCell.h"
#import "IORedMapThemeManager.h"

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation IOBaseDataSource

- (id)init
{
    self = [super init];
    
    if (self)
    {
        _cellIdentifier = @"SpotCell";
        _searchIsActive = NO;
    }
    
    return self;
}

////////////////////////////////////////////////////////////////////////////////
- (void)didRecieveMemoryWarning
{
    // TODO: send a message to release the delegate and fetchedResultsController
    self.regularController = nil;
    self.searchController = nil;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - IOSpotDataSource Protocol

- (NSUInteger)heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 53.0; // minimum 44.0
}

////////////////////////////////////////////////////////////////////////////////
- (BOOL)isSearchAvailable
{
    return NO;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Controllers

- (id <IOFetchedResultsProtocol>)currentController
{
    if (self.isSearchAvailable && self.searchIsActive)
        return self.searchController;
    
    return self.regularController;
}

////////////////////////////////////////////////////////////////////////////////
- (id <IOFetchedResultsProtocol>)controllerForTableView:(UITableView *)tableView
{
    if ([self.delegate respondsToSelector:@selector(isMainTableView:)])
        return [self.delegate isMainTableView:tableView] ? self.regularController : self.searchController;
    
    return self.regularController;
}

////////////////////////////////////////////////////////////////////////////////
- (id)objectAtIndexPath:(NSIndexPath *)indexPath
{
    return [[self currentController] objectAtIndexPath:indexPath];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - UITableViewDataSource protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self controllerForTableView:tableView] numberOfSections];
}

////////////////////////////////////////////////////////////////////////////////
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self controllerForTableView:tableView] numberOfRowsInSection:section];
}

////////////////////////////////////////////////////////////////////////////////
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    IOSpotTableViewCell *cell;
    
    id <IOFetchedResultsProtocol> controller = [self controllerForTableView:tableView];
    
    // try to dequeue a cell
    if ([controller isEqual:self.regularController])                            // main tableView
        cell = (IOSpotTableViewCell *)[tableView dequeueReusableCellWithIdentifier:self.cellIdentifier forIndexPath:indexPath];
    else if ([self.delegate respondsToSelector:@selector(dequeueReusableCellWithIdentifier:)]) // the tableView is the searchController's
        cell = (IOSpotTableViewCell *)[self.delegate dequeueReusableCellWithIdentifier:self.cellIdentifier];
    else                                                                        // unknown
        cell = [[IOSpotTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:self.cellIdentifier];
    
    [cell initialSetup];
    
    // TODO: [search] configure cell, based on frc
    /*if ([self respondsToSelector:@selector(fetchedResourceController:configureCell:atIndexPath:)])
        [self controller:controller configureCell:cell atIndexPath:indexPath];
    else */
    if ([self respondsToSelector:@selector(configureTableView:cell:atIndexPath:)])
        [self configureTableView:tableView cell:cell atIndexPath:indexPath];
    
    [IORedMapThemeManager styleTableViewCell:cell atIndexPath:indexPath as:IOTableViewStyleWithBackground];
    
    return cell;
}

////////////////////////////////////////////////////////////////////////////////
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([[self controllerForTableView:tableView] sectionNameKeyPath]) {
        static NSString *charSet = @"#ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        id sectionObject = [[self controllerForTableView:tableView] sectionObjectAtIndex:section];
        int position = [[sectionObject valueForKey:@"name"] intValue];
        if (position == 0)
            return @"#";
        else
            return [charSet substringWithRange:NSMakeRange(position, 1)];
    }
    
    return nil;
}

////////////////////////////////////////////////////////////////////////////////
/*
 - (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"All species";
}
 */

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSFetchedResultsControllerDelegate protocol

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    if ([self.delegate respondsToSelector:@selector(beginUpdates:)])
    {
        BOOL isSearchController = [controller isEqual:self.searchController.fetchedResultsController];
        [self.delegate beginUpdates:isSearchController];
    }
}

////////////////////////////////////////////////////////////////////////////////
- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    if (!self.delegate)
        return;
    
    BOOL isSearchController = [controller isEqual:self.searchController.fetchedResultsController];
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            if ([self.delegate respondsToSelector:@selector(insertSection:andShouldTargetSearchBarTableView:)])
                [self.delegate insertSection:sectionIndex andShouldTargetSearchBarTableView:isSearchController];
            break;
            
        case NSFetchedResultsChangeDelete:
            if ([self.delegate respondsToSelector:@selector(deleteSection:andShouldTargetSearchBarTableView:)])
                [self.delegate deleteSection:sectionIndex andShouldTargetSearchBarTableView:isSearchController];
            break;

        default:
            break;
    }
}

////////////////////////////////////////////////////////////////////////////////
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    if (!self.delegate)
        return;
    
    BOOL isSearchController = [controller isEqual:self.searchController.fetchedResultsController];
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            if ([self.delegate respondsToSelector:@selector(insertRowAtIndexPath:andShouldTargetSearchBarTableView:)])
                [self.delegate insertRowAtIndexPath:newIndexPath andShouldTargetSearchBarTableView:isSearchController];
            break;
            
        case NSFetchedResultsChangeDelete:
            if ([self.delegate respondsToSelector:@selector(deleteRowAtIndexPath:andShouldTargetSearchBarTableView:)])
                [self.delegate deleteRowAtIndexPath:newIndexPath andShouldTargetSearchBarTableView:isSearchController];
            break;
            
        case NSFetchedResultsChangeUpdate:
            if ([self.delegate respondsToSelector:@selector(updateRowAtIndexPath:andShouldTargetSearchBarTableView:)])
                [self.delegate updateRowAtIndexPath:indexPath andShouldTargetSearchBarTableView:isSearchController];
            break;
            
        case NSFetchedResultsChangeMove:
            if ([self.delegate respondsToSelector:@selector(deleteRowAtIndexPath:andShouldTargetSearchBarTableView:)])
                [self.delegate deleteRowAtIndexPath:indexPath andShouldTargetSearchBarTableView:isSearchController];
            if ([self.delegate respondsToSelector:@selector(insertRowAtIndexPath:andShouldTargetSearchBarTableView:)])
                [self.delegate insertRowAtIndexPath:newIndexPath andShouldTargetSearchBarTableView:isSearchController];
            break;
    }
}

////////////////////////////////////////////////////////////////////////////////
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if ([self.delegate respondsToSelector:@selector(endUpdates:)])
    {
        BOOL isSearchController = [controller isEqual:self.searchController.fetchedResultsController];
        [self.delegate endUpdates:isSearchController];
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Content Filtering

- (void)filterContentForSearchText:(NSString *)searchText scope:(NSInteger)scope
{
    // TODO: [search] check if this is required or should be implemented by sub-classes
    
    // Update the filter
    // in this case just nil out the searchController and let lazy evaluation
    // create another with the relevant search info
    
    // TODO: send a message to the controller to release delegate and fetchedResultsController
    self.searchController = nil;
    
    // if you care about the sope - save off the index to be used later
    self.savedScopeButtonIndex = scope;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Search Bar delegate

- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView
{
    self.searchIsActive = YES;
}

////////////////////////////////////////////////////////////////////////////////
- (void)searchDisplayController:(UISearchDisplayController *)controller willUnloadSearchResultsTableView:(UITableView *)tableView
{
    // search is done, so get rid of the searchController and let ARC reclaim memory
    
    // TODO: send a message to the controller to release delegate and fetchedResultsController
    self.searchController = nil;
    
    self.searchIsActive = NO;
}

////////////////////////////////////////////////////////////////////////////////
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    NSInteger scopeIndex = 0;
    if ([self.delegate respondsToSelector:@selector(searchBarScopeIndex)])
        scopeIndex = [self.delegate searchBarScopeIndex];
    
    [self filterContentForSearchText:searchString scope:scopeIndex];
    
    // return YES to cause the search result tableView to be reloaded
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    if ([self.delegate respondsToSelector:@selector(searchBarText)])
    {
        NSInteger scopeIndex = 0;
        if ([self.delegate respondsToSelector:@selector(searchBarScopeIndex)])
            scopeIndex = [self.delegate searchBarScopeIndex];
        
        NSString *searchString = [self.delegate searchBarText];
        [self filterContentForSearchText:searchString scope:scopeIndex];
    }
    
    // return YES to cause the search result tableView to be reloaded
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Custom methods

- (void)configureTableView:(UITableView *)tableView cell:(IOSpotTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    DDLogVerbose(@"%@: Override this method in your instance!", self.class);
    abort();
}

@end
