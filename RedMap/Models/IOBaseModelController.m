//
//  IOBaseModelController.m
//  Redmap
//
//  Created by Evo Stamatov on 13/08/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOBaseModelController.h"
#import "IOSpeciesController.h"
#import "IOCoreDataHelper.h"

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

@interface IOBaseModelController ()

@property (nonatomic, strong, readwrite) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, copy, readwrite) NSString *searchString;

@property (nonatomic, copy, readwrite) NSString *entityName;
@property (nonatomic, copy, readwrite) NSString *cacheName;
@property (nonatomic, copy, readwrite) NSString *sortBy;
@property (nonatomic, assign, readwrite) BOOL ascending;
@property (nonatomic, strong, readwrite) NSArray *searchKeys;
@property (nonatomic, strong, readwrite) NSPredicate *fetchPredicate;

@property (nonatomic, strong, readwrite) NSMutableSet *storedIDs;

@property (nonatomic, strong, readwrite) NSArray *objects;
@property (nonatomic, copy, readwrite) NSString *sectionNameKeyPath;
@property (nonatomic, strong, readwrite) NSFetchedResultsController *fetchedResultsController;

@end


@implementation IOBaseModelController

- (void)prepareForDealloc
{
    _fetchedResultsController.delegate = nil;
    _fetchedResultsController = nil;
    _fetchedResultsControllerDelegate = nil;
    
    _managedObjectContext = nil;
    _searchString = nil;
    
    _entityName = nil;
    _cacheName = nil;
    _sortBy = nil;
    
    _fetchPredicate = nil;
    
    _searchKeys = nil;
    _sectionNameKeyPath = nil;
    _storedIDs = nil;
}



- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil)
        return _fetchedResultsController;
    
    _fetchedResultsController= [self fetchedResultsControllerWithSearchString:self.searchString];
    
    return _fetchedResultsController;
}



- (NSFetchedResultsController *)fetchedResultsControllerWithSearchString:(NSString *)searchString
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:self.entityName inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    [fetchRequest setFetchBatchSize:20];
    
    // Sorting
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:self.sortBy ascending:self.ascending];
    NSArray *sortDescriptors = @[sortDescriptor];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Predicate/Search
    NSPredicate *filterPredicate;
    NSMutableArray *predicateArray = [NSMutableArray array];
    
    // if there is a search string set and the class has searchKeys as well,
    // then we build a predicateArray that holds all searchKeys
    if (searchString.length && self.searchKeys.count)
    {
        [self.searchKeys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSString *format = [NSString stringWithFormat:@"%@ CONTAINS[cd] %%@", (NSString *)obj];
            [predicateArray addObject:[NSPredicate predicateWithFormat:format, searchString]];
        }];
    }
    
    // if we've got a predicateArray from above, then check for a fetchPredicate
    // and if there is one - add it as an AND compound + OR compound of the
    // predicateArray above. Otherwise - convert the above predicateArray to an
    // OR compound predicate
    if (predicateArray.count)
    {
        if (self.fetchPredicate)
            filterPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[self.fetchPredicate, [NSCompoundPredicate orPredicateWithSubpredicates:predicateArray]]];
        else
            filterPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:predicateArray];
    }
    // last approach is to not have a predicateArray, but have a filterPredicate
    else if (self.fetchPredicate)
        filterPredicate = self.fetchPredicate;
    
    // at last if there is a filterPredicate set - assign it to the fetchRequest
    if (filterPredicate)
        [fetchRequest setPredicate:filterPredicate];
    
    // TODO: figure out why having a cache crashes
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                                managedObjectContext:self.managedObjectContext
                                                                                                  sectionNameKeyPath:self.sectionNameKeyPath
                                                                                                           cacheName:nil];//self.cacheName];
    
    // Set the delegate
    aFetchedResultsController.delegate = self.fetchedResultsControllerDelegate;
    
    // doing a performBlockAndWait since this code might be called from a different thread
    __weak __typeof(self)weakSelf = self;
    [self.managedObjectContext performBlockAndWait:^{
        // Perform the fetch
        NSError *error = nil;
        if (![aFetchedResultsController performFetch:&error])
        {
            DDLogError(@"%@: ERROR performing a fetch. [%d]: %@", weakSelf.class, error.code, error.localizedDescription);
        }
    }];
    
    return aFetchedResultsController;
}



- (void)syncCoreDataWithDataFromArray:(NSArray *)entries moreComing:(BOOL)moreComing callback:(void (^)(NSSet *insertedObjects, NSSet *updatedObjects, NSError *error))callback
{
    NSAssert(callback != nil, @"This call has to have a callback!");
    
    // 1. Fetch all categories' ids to compare with all new entries
    if (self.storedIDs == nil)
        self.storedIDs = [[self fetchStoredIDs] mutableCopy];
    
    NSMutableSet *insertedObjectIDs = [NSMutableSet set];
    NSMutableSet *updatedObjectIDs = [NSMutableSet set];
    
    // 2. Insert new data into the Categories entity
    @autoreleasepool {
        for (NSDictionary *entry in entries)
        {
            NSString *theID = [entry objectForKey:@"id"];
            if (![self.storedIDs member:theID])
            {
                NSManagedObject *insertedObject = (NSManagedObject *)[self insertNewObject:entry];
                if ([insertedObject isKindOfClass:[NSManagedObject class]])
                {
                    [insertedObjectIDs addObject:insertedObject.objectID];
                }
                
                // add the id to the stored array, either way
                [self.storedIDs addObject:theID];
            }
            else if ([self conformsToProtocol:@protocol(IOBaseModelControllerProtocol)])
            {
                id storedEntry = [self fetchObjectByID:[theID integerValue]];
                if (![(id <IOBaseModelControllerProtocol>)self similarObject:entry withObject:storedEntry])
                {
                    NSManagedObject *updatedObject = (NSManagedObject *)[(id <IOBaseModelControllerProtocol>)self updateObject:storedEntry withObject:entry];
                    if ([updatedObject isKindOfClass:[NSManagedObject class]])
                    {
                        [updatedObjectIDs addObject:updatedObject.objectID];
                    }
                }
                else
                {
                    DDLogVerbose(@"%@: Similar entry found. No update needed.", self.class);
                }
            }
            else
            {
                DDLogVerbose(@"%@: Similar entry found. No insertion needed.", self.class);
            }
        }
    }
    
    DDLogVerbose(@"%@: Inserted %d entries, updated %d entries.", self.class, insertedObjectIDs.count, updatedObjectIDs.count);
    
    // 3. After all entries are parset - save them to the DB
    if (!moreComing)
    {
        DDLogVerbose(@"%@: Persisting to store", self.class);
        [IOCoreDataHelper saveContextHierarchy:self.managedObjectContext];
    }
    
    DDLogVerbose(@"%@: Calling callback", self.class);
    callback(insertedObjectIDs, updatedObjectIDs, nil);
    /*
    __weak NSManagedObjectContext *context = self.managedObjectContext;
    if (!moreComing && [context hasChanges])
    {
        [context performBlock:^{
            NSError *error = nil;
            if ([context save:&error])
            {
                if (callback)
                    callback([insertedObjects copy], [updatedObjects copy], nil);
            }
            else
            {
                if (callback)
                    callback(nil, nil, error);
            }
        }];
    }
    else
    {
        if (callback)
            callback([insertedObjects copy], [insertedObjects copy], nil);
    }
     */
}



- (NSString *)idKey
{
    return @"id";
}



- (NSArray *)objects
{
    return [self.fetchedResultsController fetchedObjects];
}



- (id)objectAtIndexPath:(NSIndexPath *)indexPath
{
    id object = nil;
    @try {
        object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    }
    @catch (NSException *exception) {
        DDLogWarn(@"%@: Object at indexPath not found. Exception: %@", self.class, exception);
        abort();
    }
    
    return object;
}



- (id)fetchObjectByID:(NSInteger)ID
{
    __block id foundObj = nil;
    
    [self.objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([[obj valueForKey:[self idKey]] integerValue] == ID)
        {
            foundObj = obj;
            *stop = YES;
        }
    }];
    
    return foundObj;
}



- (NSSet *)fetchStoredIDs
{
    return [NSSet setWithArray:[self.objects valueForKey:[self idKey]]];
}



- (NSInteger)numberOfSections
{
    return self.fetchedResultsController.sections.count;
}



- (NSInteger)numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[section];
    return [sectionInfo numberOfObjects];
}



- (id)sectionObjectAtIndex:(NSUInteger)index
{
    return [[self.fetchedResultsController sections] objectAtIndex:index];
}



- (id)insertNewObject:(id)object
{
    DDLogVerbose(@"%@: Override this method in your instance!", self.class);
    abort();
}



#pragma mark - Helpers

- (NSDate *)dateFromISO8601String:(id)dateInput withTime:(BOOL)withTime
{
    
    if ((id)[NSNull null] == dateInput)
        return nil;
    
    NSString *dateString = dateInput;
    
    if (!dateString)
        return nil;
    
    if ([dateString hasSuffix:@"Z"])
        dateString = [dateString substringToIndex:(dateString.length-1)];

    dateString = [dateString stringByReplacingOccurrencesOfString:@":" withString:@""];
    
    // Remove milliseconds from the date stamp if there are any
    NSError *regexpError = nil;
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:@"\\.[0-9]{1,6}$" options:kNilOptions error:&regexpError];
    dateString = [regexp stringByReplacingMatchesInString:dateString options:0 range:NSMakeRange(0, [dateString length]) withTemplate:@""];
    
    static NSDateFormatter *dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:@"Australia/Hobart"];
        dateFormatter.timeZone = timeZone;
    });
    dateFormatter.dateFormat = withTime ? @"yyyy-MM-dd'T'HHmmss" : @"yyyy-MM-dd";
    
    NSDate *date = [dateFormatter dateFromString:dateString];
    return date;
}



- (NSString *)getString:(NSDictionary *)dict key:(id)key default:(NSString *)fallback
{
    id result = [dict objectForKey:key];
    
    if (!result || [result isKindOfClass:[NSNull class]])
        result = fallback;
    else if (![result isKindOfClass:[NSString class]])
        result = [result description];
    
    return result;
}



- (NSString *)getString:(NSDictionary *)dict key:(id)key
{
    static NSString *emptyString = @"";
    return [self getString:dict key:key default:emptyString];
}

@end
