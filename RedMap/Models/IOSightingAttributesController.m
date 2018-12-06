//
//  IOSightingAttributesController.m
//  Redmap
//
//  Created by Evo Stamatov on 14/08/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOSightingAttributesController.h"
#import "IOAuth.h"
#import "NSFileManager+IOFileManager.h"


@interface IOSightingAttributesController ()

@property (nonatomic, strong, readwrite) NSDictionary *sightingAttributes;

@end


@implementation IOSightingAttributesController

+ (IOSightingAttributesController *)sharedInstance
{
    static IOSightingAttributesController *instance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[IOSightingAttributesController alloc] init];
    });
    
    return instance;
}



+ (NSURL *)sightingAttributesPlistURL
{
    static NSURL *attributesFileURL;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSFileManager *fm = [NSFileManager defaultManager];
        
        NSString *attributesFileName = @"sightingAttributes.plist";
        attributesFileURL = [[fm URLForApplicationBundleDirectory] URLByAppendingPathComponent:attributesFileName];
        
        // On error revert back to /Library/ which should always be reachable
        if (!attributesFileURL)
        {
            NSURL *libDirURL = [[fm URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
            attributesFileURL = [libDirURL URLByAppendingPathComponent:attributesFileName];
        }
    });
    
    return attributesFileURL;
}



- (NSDictionary *)sightingAttributes
{
    if (_sightingAttributes != nil)
        return _sightingAttributes;
    
    NSURL *plistFile = [IOSightingAttributesController sightingAttributesPlistURL];
    _sightingAttributes = [[NSDictionary alloc] initWithContentsOfURL:plistFile];
    
    return _sightingAttributes;
}



- (NSDictionary *)entryForCategory:(NSString *)category key:(NSString *)key andValue:(id)value
{
    if (value == nil)
        return nil;
    
    __block BOOL found = NO;
    __block NSDictionary *dict = nil;
    
    NSArray *entries = [self entriesForCategory:category];
    
    [entries enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        dict = (NSDictionary *)obj;
        id val = [dict valueForKey:key];
        if ([val isEqual:value])
        {
            *stop = YES;
            found = YES;
        }
    }];
    
    if (found)
        return dict;
    
    return nil;
}

- (NSDictionary *)entryForCategory:(NSString *)category withEntryID:(id)ID
{
    return [self entryForCategory:category key:kIOSightingEntryIDKey andValue:ID];
}

- (NSDictionary *)entryForCategory:(NSString *)category withEntryTitle:(NSString *)title
{
    return [self entryForCategory:category key:kIOSightingEntryTitleKey andValue:title];
}

- (NSDictionary *)entryForCategory:(NSString *)category withEntryCode:(NSString *)code
{
    return [self entryForCategory:category key:kIOSightingEntryCodeKey andValue:code];
}

- (NSString *)titleForCategory:(NSString *)category withEntryID:(id)ID
{
    NSDictionary *dict = [self entryForCategory:category withEntryID:ID];
    return dict.title;
}

- (id)idForCategory:(NSString *)category withEntryTitle:(NSString *)title
{
    NSDictionary *dict = [self entryForCategory:category withEntryTitle:title];
    return dict.ID;
}

- (NSString *)codeForCategory:(NSString *)category withEntryTitle:(NSString *)title
{
    NSDictionary *dict = [self entryForCategory:category withEntryTitle:title];
    return dict.code;
}




- (NSArray *)entriesForCategory:(NSString *)category
{
    return [self.sightingAttributes objectForKey:category];
}

- (NSArray *)accuracyEntries
{
    return [self entriesForCategory:kIOSightingCategoryAccuracy];
}

- (NSArray *)activityEntries
{
    return [self entriesForCategory:kIOSightingCategoryActivity];
}

- (NSArray *)countEntries
{
    return [self entriesForCategory:kIOSightingCategoryCount];
}

- (NSArray *)habitatEntries
{
    return [self entriesForCategory:kIOSightingCategoryHabitat];
}

- (NSArray *)regionEntries
{
    return [self entriesForCategory:kIOSightingCategoryRegion];
}

- (NSArray *)genderEntries
{
    return [self entriesForCategory:kIOSightingCategoryGender];
}

- (NSArray *)timeEntries
{
    return [self entriesForCategory:kIOSightingCategoryTime];
}

- (NSArray *)sizeMethodEntries
{
    return [self entriesForCategory:kIOSightingCategorySizeMethod];
}

- (NSArray *)weightMethodEntries
{
    return [self entriesForCategory:kIOSightingCategoryWeightMethod];
}



- (NSDictionary *)defaultEntryForCategory:(NSString *)category
{
    NSArray *firstEntry = [self entriesForCategory:category];
    
    if (firstEntry != nil)
        return [firstEntry objectAtIndex:0];
    
    return nil;
}

- (NSDictionary *)defaultAccuracy
{
    return [self defaultEntryForCategory:kIOSightingCategoryAccuracy];
}

- (NSDictionary *)defaultActivity
{
    return [self defaultEntryForCategory:kIOSightingCategoryActivity];
}

- (NSDictionary *)defaultCount
{
    return [self defaultEntryForCategory:kIOSightingCategoryCount];
}

- (NSDictionary *)defaultHabitat
{
    NSDictionary *def = [self entryForCategory:kIOSightingCategoryHabitat withEntryTitle:@"Unknown"];
    if (!def)
        def = [self defaultEntryForCategory:kIOSightingCategoryHabitat];
    return def;
}

- (NSDictionary *)defaultRegion
{
    return [self defaultEntryForCategory:kIOSightingCategoryRegion];
}

- (NSDictionary *)defaultGender
{
    return [self defaultEntryForCategory:kIOSightingCategoryGender];
}

- (NSDictionary *)defaultTime
{
    NSDictionary *def = [self timeEntryFromValue:@(-1)];
//    if (!def)
//        def = [self defaultEntryForCategory:kIOSightingCategoryTime];
    return def;
}

- (NSDictionary *)defaultSizeMethod
{
    return [self defaultEntryForCategory:kIOSightingCategorySizeMethod];
}

- (NSDictionary *)defaultWeightMethod
{
    return [self defaultEntryForCategory:kIOSightingCategoryWeightMethod];
}



- (NSString *)titleForEntry:(NSDictionary *)entry
{
    //return [entry objectForKey:kIOSightingEntryTitleKey];
    return entry.title;
}

- (id)idForEntry:(NSDictionary *)entry
{
    //return [entry objectForKey:kIOSightingEntryIDKey];
    return entry.ID;
}

- (NSString *)codeForEntry:(NSDictionary *)entry
{
    //return [entry objectForKey:kIOSightingEntryCodeKey];
    return entry.code;
}



#pragma mark Accuracy helpers

- (double)accuracyFromEntry:(NSDictionary *)accuracyEntry
{
    return [accuracyEntry.code doubleValue];
}

- (NSDictionary *)accuracyEntryFromID:(NSInteger)ID
{
    return [self entryForCategory:kIOSightingCategoryAccuracy withEntryID:@(ID)];
}

- (NSDictionary *)accuracyEntryFromValue:(double)value
{
    return [self entryForCategory:kIOSightingCategoryAccuracy withEntryCode:[NSString stringWithFormat:@"%0.f", value]];
}

- (NSDictionary *)accuracyEntryFromNearestHigherValue:(double)value
{
    __block NSDictionary *resultingEntry = [self defaultAccuracy];
    
    // Quick check if value is the same as of the default entry
    if (value == [self accuracyFromEntry:resultingEntry])
        return resultingEntry;
    
    NSArray *sortedEntries = [[self accuracyEntries] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [@([self accuracyFromEntry:obj1]) compare:@([self accuracyFromEntry:obj2])];
    }];
    
    // Finds the nearest higher number:
    // given sortedEntries becomes [10, 100, 1000, 10000]
    // if value = 5, it will return 10
    // if value = 65, it will return 100
    // if value = 20000, it will return 10000
    __block NSDictionary *lastEntry = [sortedEntries lastObject];
    for (id obj in [sortedEntries reverseObjectEnumerator])
    {
        double stepValue = [self accuracyFromEntry:obj];
        if (stepValue < value)
        {
            resultingEntry = lastEntry;
            break;
        }
        else
            lastEntry = (NSDictionary *)obj;
    };
    
    return resultingEntry;
}



#pragma mark Time helpers

- (NSInteger)timeFromEntry:(NSDictionary *)timeEntry
{
    if ([self isNotSureEntry:timeEntry])
        return kIOTimeNotSure;
    
    return [timeEntry.code integerValue];
}

- (NSDictionary *)timeEntryFromValue:(id)value
{
    if ([value isKindOfClass:[NSNumber class]])
    {
        NSNumber *number = (NSNumber *)value;
        int num = [number integerValue];
        if (num == -1)
            return [self entryForCategory:kIOSightingCategoryTime withEntryTitle:kIOTimeNotSureTitle];
        
        return [self entryForCategory:kIOSightingCategoryTime withEntryCode:[NSString stringWithFormat:@"%02i", num]];
    }
    
    return [self entryForCategory:kIOSightingCategoryTime withEntryCode:value];
}

- (BOOL)isNotSureEntry:(NSDictionary *)timeEntry
{
    if ([timeEntry.title isEqualToString:kIOTimeNotSureTitle] || [timeEntry.code isEqualToString:kIOTimeNotSureCode])
        return YES;
    
    return NO;
}



#pragma mark Region helpers

+ (BOOL)shouldAutodetectRegion
{
    NSString *regionName = [self userPreSelectedRegionName];
    return [regionName isEqualToString:kIOUserDefaultsRegionAutodetect];
}

+ (NSString *)userPreSelectedRegionName
{
    NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
    return [standardDefaults stringForKey:kIOUserDefaultsRegionKey];
}

@end














@implementation NSDictionary (IOSightingAttributeDictionary)

// REQUIRED by Core Data so it can be used as a Transformable type

- (NSComparisonResult)compare:(NSDictionary *)anotherDict
{
    NSString *title = self.title;
    NSString *anotherTitle = anotherDict.title;
    
    NSComparisonResult titleCompare = [title compare:anotherTitle];
    if (titleCompare == NSOrderedSame)
    {
        NSString *code = self.code;
        NSString *anotherCode = anotherDict.code;
        NSComparisonResult codeCompare = [code compare:anotherCode];
        if (codeCompare == NSOrderedSame)
        {
            id ID = self.ID;
            id anotherID = anotherDict.ID;
            BOOL sameID = [ID isEqual:anotherID];
            if (sameID)
                return NSOrderedSame;
            else
                return NSOrderedAscending;
        }
        else
            return codeCompare;
    }
    else
        return titleCompare;
}



// Helpers

- (NSString *)title
{
    return [self objectForKey:kIOSightingEntryTitleKey];
}

- (id)ID
{
    return [self objectForKey:kIOSightingEntryIDKey];
}

- (NSString *)code
{
    return [self objectForKey:kIOSightingEntryCodeKey];
}

@end
