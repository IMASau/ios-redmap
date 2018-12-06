//
//  IOSpotDataSourceDelegate.h
//  RedMap
//
//  Created by Evo Stamatov on 30/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol IOSpotDataSourceDelegate <NSObject>

@optional

- (void)reloadData;

// Fetch results bulk updates
- (void)beginUpdates;
- (void)endUpdates;

// Section manipulation
- (void)insertSection:(NSUInteger)sectionIndex;
- (void)deleteSection:(NSUInteger)sectionIndex;

// Row manipulation
- (void)insertRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)deleteRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)updateRowAtIndexPath:(NSIndexPath *)indexPath;



// Error handling
- (void)errorFetchingResults:(NSError *)error;
- (void)errorFetchingRemoteObjects:(NSError *)error statusCode:(NSInteger)statusCode;



// TableView cell helpers
- (UITableViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier;



// Search
// These three are required if you are going to use a SearchBar
- (BOOL)isMainTableView:(UITableView *)tableView; // should return YES if tableView == self.tableView (and NO if tableView == self.searchDisplayController.searchResultsTableView)
- (NSString *)searchBarText;                      // should return self.searchDisplayController.searchBar.text
- (NSInteger)searchBarScopeIndex;                 // should return self.searchDisplayController.searchBar.selectedScopeButtonIndex

// The following set of methods extend the above ones in case a SearchBar is used in the controller.
// You don't have to implement both sets. If you use a SearchBar - implement only the below ones.
// In case you have both implemented, they'll be called in this sequence - above, below.

// Fetch results bulk updates
- (void)beginUpdates:(BOOL)shouldTargetSearchBarTableView;
- (void)endUpdates:(BOOL)shouldTargetSearchBarTableView;

// Section manipulation
- (void)insertSection:(NSUInteger)sectionIndex andShouldTargetSearchBarTableView:(BOOL)shouldTargetSearchBarTableView;
- (void)deleteSection:(NSUInteger)sectionIndex andShouldTargetSearchBarTableView:(BOOL)shouldTargetSearchBarTableView;

// Row manipulation
- (void)insertRowAtIndexPath:(NSIndexPath *)indexPath andShouldTargetSearchBarTableView:(BOOL)shouldTargetSearchBarTableView;
- (void)deleteRowAtIndexPath:(NSIndexPath *)indexPath andShouldTargetSearchBarTableView:(BOOL)shouldTargetSearchBarTableView;
- (void)updateRowAtIndexPath:(NSIndexPath *)indexPath andShouldTargetSearchBarTableView:(BOOL)shouldTargetSearchBarTableView;

@end
