//
//  IOCategoriesController.m
//  Redmap
//
//  Created by Evo Stamatov on 30/07/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOCategoriesController.h"
#import "IOCategory.h"
#import "Region.h"
#import "IOCategory.h"

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

@interface IOCategoriesController ()

@property (nonatomic, strong) Region *region;

@end


@implementation IOCategoriesController

@synthesize managedObjectContext = _managedObjectContext, searchString = _searchString, entityName = _entityName, cacheName = _cacheName, sortBy = _sortBy, ascending = _ascending, fetchPredicate = _fetchPredicate;

- (id)initWithContext:(NSManagedObjectContext *)context region:(Region *)regionOrNil searchString:(NSString *)searchStringOrNil
{
    self = [super init];
    if (self)
    {
    logmethod();
        assert(context != nil);
        
        _managedObjectContext = context;
        _region = regionOrNil;
        _searchString = searchStringOrNil;
        
        _entityName = @"Category";
        _cacheName = @"Categories";
        _sortBy = @"desc";
        _ascending = YES;
        //_searchKeys = nil;
        //_sectionNameKeyPath = nil;
        //_storedIDs = nil;
        
        NSMutableArray *predicatesArray = [NSMutableArray arrayWithCapacity:2];
        if (regionOrNil.id)
        {
            [predicatesArray addObject:[NSPredicate predicateWithFormat:@"(ANY regions.id == %@)", regionOrNil.id]];
            [predicatesArray addObject:[NSPredicate predicateWithFormat:@"(0 != SUBQUERY(species, $x, (0 != SUBQUERY($x.regions, $y, $y.id == %@).@count)).@count)", regionOrNil.id]];
        }
        
        if ([predicatesArray count])
            _fetchPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicatesArray];
    }
    return self;
}



- (void)prepareForDealloc
{
    logmethod();
    _region = nil;
    [super prepareForDealloc];
}



- (id)insertNewObject:(id)object
{
    logmethod();
    //DDLogVerbose(@"%@: Inserting a new category object into store", self.class);
    
    NSDictionary *data = (NSDictionary *)object;
    IOCategory *category = (IOCategory *)[NSEntityDescription insertNewObjectForEntityForName:self.entityName
                                                                   inManagedObjectContext:self.managedObjectContext];
    
    category.id = @([data[@"id"] intValue]);
    category = [self updateObject:category withObject:data];
    
    return category;
}

#pragma mark - IOBaseModelControllerProtocol

////////////////////////////////////////////////////////////////////////////////
- (BOOL)similarObject:(id)NSDictionaryObject withObject:(id)CoreDataObject
{
    NSDictionary *data = (NSDictionary *)NSDictionaryObject;
    IOCategory *category = (IOCategory *)CoreDataObject;
    
    NSString *url             = [self getString:data key:@"url"];
    if (![url isEqualToString:category.url]) return NO;
    
    NSString *desc            = [self getString:data key:@"description"];
    if (![desc isEqualToString:category.desc]) return NO;
    
    NSString *longDesc       = [self getString:data key:@"long_description"];
    if (![longDesc isEqualToString:category.longDesc]) return NO;
    
    NSString *pictureUrl      = [self getString:data key:@"picture_url"];
    if (![pictureUrl isEqualToString:category.pictureUrl]) return NO;
    
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
- (id)updateObject:(id)CoreDataObject withObject:(id)NSDictionaryObject
{
    IOCategory *category = (IOCategory *)CoreDataObject;
    NSDictionary *data = (NSDictionary *)NSDictionaryObject;
    
    category.url        = [self getString:data key:@"url"];
    category.desc       = [self getString:data key:@"description"];
    category.longDesc   = [self getString:data key:@"long_description"];
    category.pictureUrl = [self getString:data key:@"picture_url"];
    
    return category;
}

@end
