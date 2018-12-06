//
//  IOSightingsController.m
//  Redmap
//
//  Created by Evo Stamatov on 6/09/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOSightingsController.h"
#import "Sighting.h"
#import "IOAuth.h"
#import "User.h"
#import "IOSpeciesController.h"
#import "IOSightingAttributesController.h"
#import "Species.h"
#import "IOPhotoCollection.h"
#import "Sighting-typedefs.h"

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

@implementation IOSightingsController

@synthesize managedObjectContext = _managedObjectContext, entityName = _entityName, cacheName = _cacheName, sortBy = _sortBy, ascending = _ascending, fetchPredicate = _fetchPredicate;

- (id)initWithContext:(NSManagedObjectContext *)context
{
    self = [super init];
    if (self)
    {
        assert(context != nil);
        
        _managedObjectContext = context;
        
        _entityName = @"Sighting";
        _cacheName = [_entityName copy];
        _sortBy = @"dateSpotted";
        _ascending = YES;
        
        /*
        NSMutableArray *predicatesArray = [NSMutableArray arrayWithCapacity:2];
        [predicatesArray addObject:[NSPredicate predicateWithFormat:@"(ANY categories.id == %@)", categoryOrNil.id]];
        
        if ([predicatesArray count])
            _fetchPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicatesArray];
         */
    }
    return self;
}



- (id)initWithContext:(NSManagedObjectContext *)context userID:(NSNumber *)userID
{
    self = [self initWithContext:context];
    if (self)
    {
        if (userID)
            _fetchPredicate = [NSPredicate predicateWithFormat:@"(user.userID == %@)", userID];
    }
    return self;
}



- (id)insertNewObject:(id)object
{
    Sighting *sighting = (Sighting *)[NSEntityDescription insertNewObjectForEntityForName:self.entityName
                                                                   inManagedObjectContext:self.managedObjectContext];
    
    return [self updateObject:sighting withObject:object];
}



- (NSString *)idKey
{
    return @"sightingID";
}



#pragma mark - IOBaseModelControllerProtocol

- (BOOL)similarObject:(id)NSDictionaryObject withObject:(id)CoreDataObject
{
    NSDictionary *data = (NSDictionary *)NSDictionaryObject;
    Sighting *oldSighting = (Sighting *)CoreDataObject;
    
    /*
    id dateObj = [data objectForKey:@"update_time"];
    
    NSDate *newSightingDateModified = nil;
    if (![dateObj isEqual:[NSNull null]])
        newSightingDateModified = [self dateFromISO8601String:(NSString *)dateObj withTime:YES];
    
    if (newSightingDateModified == nil)
        return NO;
    
    NSDate *oldSightingDateModified = oldSighting.dateModified;
    
    // Consider them different only if newSightingDateModified is later than oldSightingDateModified
    NSDate *laterDate = [newSightingDateModified laterDate:oldSightingDateModified]; // get the later of the two or newSightingDateModified (if the same)
    return [laterDate isEqualToDate:oldSightingDateModified]; // if laterDate is the same as oldSightingDateModified, then the two objects are the considered similar
     */

    BOOL published = [data[@"is_published"] boolValue];
    BOOL validSighting = [data[@"is_valid_sighting"] boolValue];

    //IOLog(@"OLD Published: %@, OLD Valid: %@", [oldSighting.published boolValue] ? @"Y" : @"N", [oldSighting.validSighting boolValue] ? @"Y" : @"N");
    //IOLog(@"Published: %@, Valid: %@", published ? @"Y" : @"N", validSighting ? @"Y" : @"N");
    return ([oldSighting.published boolValue] == published && [oldSighting.validSighting boolValue] == validSighting);
}



- (id)updateObject:(id)CoreDataObject withObject:(id)NSDictionaryObject
{
    Sighting *sighting = (Sighting *)CoreDataObject;
    NSDictionary *data = (NSDictionary *)NSDictionaryObject;
    
    User *user = [[IOAuth sharedInstance] currentUser];
    // switch the user to the current context
    user = (User *)[self.managedObjectContext objectWithID:user.objectID];
    
    BOOL update = YES;
    
    // The required ones...
    if (sighting.uuid == nil)
    {
        update = NO;
        //IOLog(@"Updating sighting");
        sighting.uuid = [[NSUUID UUID] UUIDString];
    }
    
    // The simple ones...
    if ([sighting.sightingID intValue] == 0)
        sighting.sightingID = @([data[@"id"] intValue]);
    if (user && sighting.user == nil)
        sighting.user = user;
    
    
    // The more complicated ones...
    
    // there should be either other_species or species set
    BOOL checkSpecies = YES;
    id otherSpeciesObj = data[@"other_species"];
    if (![otherSpeciesObj isKindOfClass:[NSNull class]])
    {
        NSString *otherSpeciesString = (NSString *)otherSpeciesObj;
        if (![otherSpeciesString isEqualToString:@""])
        {
            // parse the other_species -- a monster of code
            NSString *otherSpeciesRegexFormat = @"(.*)\\s+\\((.*)\\)";
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:otherSpeciesRegexFormat
                                                                                   options:NSRegularExpressionCaseInsensitive
                                                                                     error:nil];
            NSArray *matchesArray = [regex matchesInString:otherSpeciesString
                                                   options:0
                                                     range:NSMakeRange(0, [otherSpeciesString length])];
            if ([matchesArray count])
            {
                NSTextCheckingResult *result = (NSTextCheckingResult *)[matchesArray lastObject];
                if ([result numberOfRanges] == 3)
                {
                    NSString *newSpeciesName = [otherSpeciesString substringWithRange:[result rangeAtIndex:1]];
                    NSString *newSpeciesCommonName = [otherSpeciesString substringWithRange:[result rangeAtIndex:2]];
                    if (![sighting.otherSpeciesName isEqualToString:newSpeciesName] || [sighting.otherSpeciesCommonName isEqualToString:newSpeciesCommonName])
                    {
                        checkSpecies = NO;
                        sighting.otherSpecies = @YES;
                        sighting.otherSpeciesName = newSpeciesName;
                        sighting.otherSpeciesCommonName = newSpeciesCommonName;
                        sighting.species = nil;
                    }
                }
            }
        }
    }
    
    if (checkSpecies)
    {
        @try {
            id speciesObj = data[@"species"];
            if ([speciesObj isKindOfClass:[NSNull class]])
                @throw [NSException exceptionWithName:IOAuthExceptionMissingValue reason:@"Species is not set" userInfo:nil];
            
            IOSpeciesController *speciesController = [[IOSpeciesController alloc] initWithContext:self.managedObjectContext speciesURL:(NSString *)speciesObj];
            Species *species = [[speciesController objects] lastObject];
            if (!species)
            {
                // Stop processing and return.
                DDLogError(@"%@: ERROR. The specified Species object could not be found", self.class);
                if (!update)
                    [self.managedObjectContext deleteObject:sighting];
                return nil;
            }
            
            if (!sighting || !sighting.species || ![species.id isEqualToNumber:sighting.species.id])
            {
                sighting.species = species;
                sighting.otherSpecies = nil;
                sighting.otherSpeciesName = nil;
                sighting.otherSpeciesCommonName = nil;
            }
        }
        @catch (NSException *exception) {
            // Stop processing and return. Discard any exceptions :)
            DDLogError(@"%@: EXCEPTION: %@", self.class, [exception reason]);
            if (!update)
                [self.managedObjectContext deleteObject:sighting];
            return nil;
        }
    }
    
    if ([sighting.published boolValue] != [data[@"is_published"] boolValue])
        sighting.published = @([data[@"is_published"] boolValue]);
    if ([sighting.validSighting boolValue] != [data[@"is_valid_sighting"] boolValue])
        sighting.validSighting = @([data[@"is_valid_sighting"] boolValue]);
    if (![sighting.url isEqualToString:data[@"url"]])
        sighting.url = data[@"url"];
    
    if (!update)
    {
        NSDate *now = [NSDate date];
        sighting.dateCreated = now;
        sighting.dateModified = now;
    }
    
    // Dates
    id dateObj = [data objectForKey:@"update_time"];
    if (![dateObj isEqual:[NSNull null]])
    {
        NSDate *updateTime = [self dateFromISO8601String:(NSString *)dateObj withTime:YES];
        if (![sighting.dateModified isEqualToDate:updateTime])
            sighting.dateModified = updateTime;
    }
    
    dateObj = [data objectForKey:@"logging_date"];
    if (![dateObj isEqual:[NSNull null]])
    {
        NSDate *loggingDate = [self dateFromISO8601String:(NSString *)dateObj withTime:YES];
        if (![sighting.dateSpotted isEqualToDate:loggingDate])
            sighting.dateSpotted = loggingDate;
    }
    
    // Location
    if ([sighting.locationLat doubleValue] != [data[@"latitude"] doubleValue])
        sighting.locationLat = @([data[@"latitude"] doubleValue]);
    if ([sighting.locationLng doubleValue] != [data[@"longitude"] doubleValue])
        sighting.locationLng = @([data[@"longitude"] doubleValue]);
    id accuracyObj = [[IOSightingAttributesController sharedInstance] accuracyEntryFromID:[data[@"accuracy"] integerValue]];
    if (![sighting.locationAccuracy isEqual:accuracyObj])
        sighting.locationAccuracy = accuracyObj;
    
    // TODO: process
    // * category_list[]
    // * region
    // * photo_url
    
    // TODO: missing
    //sighting.time = @{};
    //sighting.timeNotSure = @(NO);
    
    if ([sighting.status intValue] != IOSightingStatusSynced)
        sighting.status = @(IOSightingStatusSynced);
    
    return sighting;
}

@end
