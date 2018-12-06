//
//  CategoriesDataSource.m
//  RedMap
//
//  Created by Evo Stamatov on 26/03/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "CategoriesDataSource.h"
#import "AppDelegate.h"
#import "Category.h"
#import "IOSpotTableViewCell.h"


@interface CategoriesDataSource ()

@end


@implementation CategoriesDataSource

@synthesize managedObjectContext = _managedObjectContext, entityName = _entityName, cacheName = _cacheName, sortBy = _sortBy, ascending = _ascending, searchKeys = _searchKeys;

- (id)initWithContext:(NSManagedObjectContext *)context
{
    self = [super init];
    
    if (self)
    {
        assert(context != nil);
        
        _managedObjectContext = context;
        _entityName = @"Category";
        _cacheName = @"Categories";
        _sortBy = @"desc";
        _ascending = YES;
        //_searchKeys = @[@"desc"];
    }
    
    return self;
}



#pragma mark - IOSpotDataSource protocol

- (NSUInteger)heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 73.0;
}




#pragma mark - Custom Methods

- (void)syncEntries
{
    __weak CategoriesDataSource *weakSelf = self;
    __block NSInteger count = 0;
    
    [RMAPI requestCategories:^(NSArray *categories, BOOL hasMore, NSInteger total, BOOL cached) {
        if (count == 0 && hasMore && !cached)
        {
            // TODO: show status
        }
        
        count += [categories count];
        
        // TODO: update status - count/total
        
        [weakSelf updateCacheWithDataFromArray:categories moreComing:hasMore];
    } errorBlock:^(NSError *error, NSInteger statusCode) {
        if ([weakSelf.delegate respondsToSelector:@selector(errorFetchingRemoteObjects:statusCode:)])
            [weakSelf.delegate errorFetchingRemoteObjects:error statusCode:statusCode];
    }];
}



/*
// Fetch all categories, filtered by specific URLs
- (NSSet *)fetchCategoriesByArrayOfUrls:(NSArray *)urlArray
{
    NSArray *fetchedObjects = [self.fetchedResultsController fetchedObjects];
    NSArray *filteredObjects = [fetchedObjects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(url IN %@)", urlArray]];
    return [NSSet setWithArray:filteredObjects];
}
 */



#pragma mark - Table View data source

- (void)configureCell:(IOSpotTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    //cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    Category *category = (Category *)[self objectAtIndexPath:indexPath];
    
    if (category)
    {
        cell.title = category.desc;
        //cell.subTitle = category.longDesc;
        
        [cell loadImageFromURL:category.pictureUrl];
    }
}



/*
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"All species";
}
 */



#pragma mark - Core Data

- (void)setupNewManagedObject:(NSManagedObject *)managedObject withDictionary:(NSDictionary *)data
{
    Category *category = (Category *)managedObject;
    
    category.id         = @([[data objectForKey:@"id"] intValue]);
    category.url        = [data objectForKey:@"url"];
    category.desc       = [data objectForKey:@"description"];
    category.longDesc   = [data objectForKey:@"long_description"];
    category.pictureUrl = [data objectForKey:@"picture_url"];
}




@end
