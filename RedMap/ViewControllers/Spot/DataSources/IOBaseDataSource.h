//
//  IOBaseDataSource.h
//  RedMap
//
//  Created by Evo Stamatov on 17/06/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IOSpotDataSource.h"
#import "IOSpotDataSourceDelegate.h"
#import "IOSpotTableViewCell.h"
#import "IOBaseModelController.h"

@interface IOBaseDataSource : NSObject <IOSpotDataSource, UITableViewDataSource, NSFetchedResultsControllerDelegate, UISearchBarDelegate, UISearchDisplayDelegate>

// OVERRIDE in the child class
- (void)configureTableView:(UITableView *)tableView cell:(IOSpotTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

// Base level methods and properties
@property (strong, nonatomic) id <IOSpotDataSourceDelegate> delegate;

// IOSpotDataSource Protocol
- (id)objectAtIndexPath:(NSIndexPath *)indexPath;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
- (void)didRecieveMemoryWarning;
- (NSUInteger)heightForRowAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)isSearchAvailable;

// Fetch Controllers
@property (nonatomic, strong) id <IOFetchedResultsProtocol> regularController;
@property (nonatomic, strong) id <IOFetchedResultsProtocol> searchController;
- (id <IOFetchedResultsProtocol>)currentController;

// Search related
@property (nonatomic, copy) NSString *savedSearchTerm;
@property (nonatomic, assign) NSInteger savedScopeButtonIndex;
@property (nonatomic, assign) BOOL searchWasActive;
@property (nonatomic, assign) BOOL searchIsActive;

// Private
@property (nonatomic, copy) NSString *cellIdentifier;

@end
