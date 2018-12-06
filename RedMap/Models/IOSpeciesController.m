//
//  IOSpeciesController.m
//  Redmap
//
//  Created by Evo Stamatov on 12/08/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOSpeciesController.h"
#import "Species.h"
#import "Region.h"
#import "Species-typedefs.h"
#import "IOCategory.h"
#import "IORegionsController.h"
#import "IOCategoriesController.h"


@interface IOSpeciesController ()

@property (nonatomic, copy) Species *region;
@property (nonatomic, copy) IOCategory *category;

@property (nonatomic, strong) NSArray *categoriesIds;
@property (nonatomic, strong) NSArray *regionsIds;

@end


@implementation IOSpeciesController

@synthesize managedObjectContext = _managedObjectContext, searchString = _searchString, entityName = _entityName, cacheName = _cacheName, sortBy = _sortBy, ascending = _ascending, fetchPredicate = _fetchPredicate, sectionNameKeyPath = _sectionNameKeyPath, searchKeys = _searchKeys;

- (id)initWithContext:(NSManagedObjectContext *)context region:(Species *)regionOrNil category:(IOCategory *)categoryOrNil searchString:(NSString *)searchStringOrNil
{
    self = [super init];
    if (self)
    {
        assert(context != nil);
        
        _managedObjectContext = context;
        _region = regionOrNil;
        _category = categoryOrNil;
        _searchString = searchStringOrNil;
        
        _entityName = @"Species";
        _cacheName = [NSString stringWithFormat:@"%@-%@", _entityName, _category.desc];
        _sortBy = kIOSpeciesPropertySpeciesName;
        _ascending = YES;
        
        _sectionNameKeyPath = kIOSpeciesPropertySection;
        _searchKeys = @[kIOSpeciesPropertyCommonName, kIOSpeciesPropertySpeciesName];
        
        NSMutableArray *predicatesArray = [NSMutableArray arrayWithCapacity:2];
        if (regionOrNil.id)
            [predicatesArray addObject:[NSPredicate predicateWithFormat:@"(ANY regions.id == %@)", regionOrNil.id]];
        if (categoryOrNil.id)
            [predicatesArray addObject:[NSPredicate predicateWithFormat:@"(ANY categories.id == %@)", categoryOrNil.id]];
        
        if ([predicatesArray count])
            _fetchPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicatesArray];
    }
    return self;
}



- (id)initWithContext:(NSManagedObjectContext *)context speciesURL:(NSString *)speciesURL
{
    self = [self initWithContext:context region:nil category:nil searchString:nil];
    if (self)
    {
        _searchKeys = @[@"url"];
        _fetchPredicate = [NSPredicate predicateWithFormat:@"(url == %@)", speciesURL];
    }
    return self;
}



- (void)prepareForDealloc
{
    _region = nil;
    _category = nil;
    
    _regionsIds = nil;
    _categoriesIds = nil;
    
    [super prepareForDealloc];
}



- (id)insertNewObject:(id)object
{
    NSDictionary *data = (NSDictionary *)object;
    Species *species = (Species *)[NSEntityDescription insertNewObjectForEntityForName:self.entityName
                                                                inManagedObjectContext:self.managedObjectContext];
    
    species.id = @([data[@"id"] intValue]);
    species = [self updateObject:species withObject:data];
    
    return species;
}



- (NSSet *)fetchRegionsByArrayOfIds:(NSArray *)idArray
{
    if (self.regionsIds == nil)
    {
        //IOLog(@"Creating a regions list for the SpeciesController.");
        IORegionsController *rc = [[IORegionsController alloc] initWithContext:self.managedObjectContext searchString:nil];
        self.regionsIds = rc.objects;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(id IN %@)", idArray];
    NSArray *filteredObjects = [self.regionsIds filteredArrayUsingPredicate:predicate];
    
    return [NSSet setWithArray:filteredObjects];
}



- (NSSet *)fetchCategoriesByArrayOfIds:(NSArray *)idArray
{
    if (self.categoriesIds == nil)
    {
        //IOLog(@"Creating a category list for the RegionsController.");
        IOCategoriesController *cc = [[IOCategoriesController alloc] initWithContext:self.managedObjectContext region:nil searchString:nil];
        self.categoriesIds = cc.objects;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(id IN %@)", idArray];
    NSArray *filteredObjects = [self.categoriesIds filteredArrayUsingPredicate:predicate];
    
    return [NSSet setWithArray:filteredObjects];
}


#pragma mark - IOBaseModelControllerProtocol

////////////////////////////////////////////////////////////////////////////////
- (BOOL)similarObject:(id)NSDictionaryObject withObject:(id)CoreDataObject
{
    NSDictionary *data = (NSDictionary *)NSDictionaryObject;
    Species *species = (Species *)CoreDataObject;
    
    id dateObj = data[@"update_time"];
    if (![dateObj isEqual:[NSNull null]])
    {
        NSDate *updateTime = [self dateFromISO8601String:(NSString *)dateObj withTime:YES];
        if (![updateTime isEqualToDate:species.updateTime])
            return NO;
    }

    NSString *url             = [self getString:data key:@"url"];
    if (![url isEqualToString:species.url]) return NO;

    NSString *speciesName     = [self getString:data key:@"species_name"];
    if (![speciesName isEqualToString:species.speciesName]) return NO;
    
    NSString *commonName      = [self getString:data key:@"common_name"];
    if (![commonName isEqualToString:species.commonName]) return NO;
    
    NSString *shortDesc       = [self getString:data key:@"short_description"];
    if (![shortDesc isEqualToString:species.shortDesc]) return NO;
    
    NSString *desc            = [self getString:data key:@"description"];
    if (![desc isEqualToString:species.desc]) return NO;
    
    NSString *imageCredit     = [self getString:data key:@"image_credit"];
    if (![imageCredit isEqualToString:species.imageCredit]) return NO;
    
    NSString *pictureUrl      = [self getString:data key:@"picture_url"];
    if (![pictureUrl isEqualToString:species.pictureUrl]) return NO;
    
    NSString *sightingsUrl    = [self getString:data key:@"sightings_url"];
    if (![sightingsUrl isEqualToString:species.sightingsUrl]) return NO;
    
    NSString *distributionUrl = [self getString:data key:@"distribution_url"];
    if (![distributionUrl isEqualToString:species.distributionUrl]) return NO;
    
    NSString *notes           = [self getString:data key:@"notes"];
    if (![notes isEqualToString:species.notes]) return NO;

    id regionsObj = data[@"region_id_list"];
    if ([regionsObj isKindOfClass:[NSArray class]])
    {
        NSSet *regions = [self fetchRegionsByArrayOfIds:(NSArray *)regionsObj];
        if (![regions isEqualToSet:species.regions])
            return NO;
    }
    
    id categoriesObj = data[@"category_id_list"];
    if ([categoriesObj isKindOfClass:[NSArray class]])
    {
        NSSet *categories = [self fetchCategoriesByArrayOfIds:(NSArray *)categoriesObj];
        if (![categories isEqualToSet:species.categories])
            return NO;
    }
    
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
- (id)updateObject:(id)CoreDataObject withObject:(id)NSDictionaryObject
{
    Species *species = (Species *)CoreDataObject;
    NSDictionary *data = (NSDictionary *)NSDictionaryObject;
    
    // The simple ones...
    species.url             = [self getString:data key:@"url"];
    species.speciesName     = [self getString:data key:@"species_name"];
    species.commonName      = [self getString:data key:@"common_name"];
    species.shortDesc       = [self getString:data key:@"short_description"];
    species.desc            = [self getString:data key:@"description"];
    species.imageCredit     = [self getString:data key:@"image_credit"];
    species.pictureUrl      = [self getString:data key:@"picture_url"];
    species.sightingsUrl    = [self getString:data key:@"sightings_url"];
    species.distributionUrl = [self getString:data key:@"distribution_url"];
    species.notes           = [self getString:data key:@"notes"];
    
    // The more complicated ones...
    // Date
    id dateObj = data[@"update_time"];
    if (![dateObj isEqual:[NSNull null]])
    {
        NSDate *updateTime = [self dateFromISO8601String:(NSString *)dateObj withTime:YES];
        species.updateTime = updateTime;
    }
    
    
    // Regions
    id regionsObj = data[@"region_id_list"];
    // NOTE: this cannot be NULL, because the DB field REQUIRES a minimum of one entry in the set
    if (![regionsObj isEqual:[NSNull null]])
        species.regions = [self fetchRegionsByArrayOfIds:(NSArray *)regionsObj];
    
    
    // Categories
    id categoriesObj = data[@"category_id_list"];
    // NOTE: this cannot be NULL, because the DB field REQUIRES a minimum of one entry in the set
    if (![categoriesObj isEqual:[NSNull null]])
        species.categories = [self fetchCategoriesByArrayOfIds:(NSArray *)categoriesObj];
    
    
    // Section
    if (self.sortBy)
    {
        static NSString *charSet = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        
        NSString *sectionValue = [species valueForKey:self.sortBy];
        NSString *firstChar = [[sectionValue substringWithRange:NSMakeRange(0, 1)] uppercaseString];
        NSRange range = [charSet rangeOfString:firstChar];
        
        if (range.location == NSNotFound)
            species.section = @0;
        else
            species.section = @(range.location + 1);
    }
    
    return species;
}

@end
