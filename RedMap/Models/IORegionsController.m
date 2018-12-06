//
//  IORegionsController.m
//  Redmap
//
//  Created by Evo Stamatov on 12/08/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IORegionsController.h"
#import "Region.h"
#import "IOCategory.h"
#import "IOCategoriesController.h"

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

@interface IORegionsController ()

@property (nonatomic, strong) NSArray *categoriesUrls;

@end


@implementation IORegionsController

@synthesize managedObjectContext = _managedObjectContext, searchString = _searchString, entityName = _entityName, cacheName = _cacheName, sortBy = _sortBy, ascending = _ascending, searchKeys = _searchKeys;

- (id)initWithContext:(NSManagedObjectContext *)context searchString:(NSString *)searchStringOrNil
{
    self = [super init];
    if (self)
    {
        assert(context != nil);
        
        _managedObjectContext = context;
        _searchString = searchStringOrNil;
        _searchKeys = @[@"desc"];

        _entityName = @"Region";
        _cacheName = @"Regions";
        _sortBy = @"desc";
        _ascending = YES;
    }
    return self;
}



- (id)insertNewObject:(id)object
{
    NSDictionary *data = (NSDictionary *)object;
    Region *region = (Region *)[NSEntityDescription insertNewObjectForEntityForName:self.entityName
                                                             inManagedObjectContext:self.managedObjectContext];
    
    region.id           = @([data[@"id"] intValue]);
    region = [self updateObject:region withObject:data];
    
    return region;
}



- (NSSet *)fetchCategoriesByArrayOfUrls:(NSArray *)urlArray
{
    if (self.categoriesUrls == nil)
    {
        DDLogInfo(@"Creating a category list for the RegionsController.");
        IOCategoriesController *cc = [[IOCategoriesController alloc] initWithContext:self.managedObjectContext region:nil searchString:nil];
        self.categoriesUrls = cc.objects;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(url IN %@)", urlArray];
    NSArray *filteredObjects = [self.categoriesUrls filteredArrayUsingPredicate:predicate];
    
    return [NSSet setWithArray:filteredObjects];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Custom methods

- (Region *)lookupBy:(NSString *)key value:(id)value
{
    __block Region *foundRegion = nil;
    
    [self.objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        Region *region = (Region *)obj;
        if ([[region valueForKey:key] isEqual:value])
        {
            foundRegion = region;
            *stop = YES;
        }
    }];
    return foundRegion;
}

////////////////////////////////////////////////////////////////////////////////
- (Region *)lookupByName:(NSString *)name
{
    return [self lookupBy:@"desc" value:name];
}

////////////////////////////////////////////////////////////////////////////////
- (Region *)lookupBySlug:(NSString *)slug
{
    return [self lookupBy:@"slug" value:slug];
}

#pragma mark - IOBaseModelControllerProtocol

////////////////////////////////////////////////////////////////////////////////
- (BOOL)similarObject:(id)NSDictionaryObject withObject:(id)CoreDataObject
{
    NSDictionary *data = (NSDictionary *)NSDictionaryObject;
    Region *theRegion = (Region *)CoreDataObject;
    
    NSString *url = [self getString:data key:@"url"];
    if (![theRegion.url isEqualToString:url]) return NO;
    
    NSString *slug = [self getString:data key:@"slug"];
    if (![theRegion.slug isEqualToString:slug]) return NO;
    
    NSString *desc = [self getString:data key:@"description"];
    if (![theRegion.desc isEqualToString:desc]) return NO;
    
    NSString *sightingsUrl = [self getString:data key:@"sightings_url"];
    if (![theRegion.sightingsUrl isEqualToString:sightingsUrl]) return NO;

    id categoryListObj = data[@"category_list"];
    if ([categoryListObj isKindOfClass:[NSArray class]])
    {
        NSSet *oldCategories = theRegion.categories;
        NSSet *newCategories = [self fetchCategoriesByArrayOfUrls:categoryListObj];
        if (![newCategories isEqualToSet:oldCategories])
            return NO;
    }

    return YES;
}

////////////////////////////////////////////////////////////////////////////////
- (id)updateObject:(id)CoreDataObject withObject:(id)NSDictionaryObject
{
    NSDictionary *data = (NSDictionary *)NSDictionaryObject;
    Region *region = (Region *)CoreDataObject;
    
    region.url          = [self getString:data key:@"url"];
    region.slug         = [self getString:data key:@"slug"];
    region.desc         = [self getString:data key:@"description"];
    region.sightingsUrl = [self getString:data key:@"sightings_url"];
    
    // Categories
    id categoriesObj = data[@"category_list"];
    if ([categoriesObj isKindOfClass:[NSArray class]])
        region.categories = [self fetchCategoriesByArrayOfUrls:(NSArray *)categoriesObj];

    return region;
}

@end
