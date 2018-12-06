//
//  IOSightingAttributesController.h
//  Redmap
//
//  Created by Evo Stamatov on 14/08/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <Foundation/Foundation.h>


// Categories -- these are the root keys from sightingAttributes.plist
#define kIOSightingCategoryAccuracy     @"accuracy"
#define kIOSightingCategoryActivity     @"activity"
#define kIOSightingCategoryCount        @"count"
#define kIOSightingCategoryHabitat      @"habitat"
#define kIOSightingCategoryRegion       @"region"
#define kIOSightingCategoryGender       @"sex"
#define kIOSightingCategoryTime         @"time"
#define kIOSightingCategorySizeMethod   @"sizeMethod"
#define kIOSightingCategoryWeightMethod @"weightMethod"

// Entry keys -- these are the keys of each entry of a Category
#define kIOSightingEntryTitleKey @"title"
#define kIOSightingEntryIDKey @"id"
#define kIOSightingEntryCodeKey @"code"

// Time related
#define kIOTimeNotSureTitle @"Not sure"
#define kIOTimeNotSureCode @"NS"
enum {
  kIOTimeNotSure          = -1
};


@interface IOSightingAttributesController : NSObject

+ (IOSightingAttributesController *)sharedInstance;
+ (NSURL *)sightingAttributesPlistURL;

@property (nonatomic, strong, readonly) NSDictionary *sightingAttributes;

- (NSArray *)entriesForCategory:(NSString *)kIOSightingCategory;
- (NSArray *)accuracyEntries;
- (NSArray *)activityEntries;
- (NSArray *)countEntries;
- (NSArray *)habitatEntries;
- (NSArray *)regionEntries;
- (NSArray *)genderEntries;
- (NSArray *)timeEntries;
- (NSArray *)sizeMethodEntries;
- (NSArray *)weightMethodEntries;

- (NSDictionary *)defaultEntryForCategory:(NSString *)category;
- (NSDictionary *)defaultAccuracy;
- (NSDictionary *)defaultActivity;
- (NSDictionary *)defaultCount;
- (NSDictionary *)defaultHabitat;
- (NSDictionary *)defaultRegion;
- (NSDictionary *)defaultGender;
- (NSDictionary *)defaultTime;
- (NSDictionary *)defaultSizeMethod;
- (NSDictionary *)defaultWeightMethod;

- (NSString *)titleForEntry:(NSDictionary *)entry;
- (id)idForEntry:(NSDictionary *)entry;

- (NSDictionary *)entryForCategory:(NSString *)kIOSightingCategory withEntryTitle:(NSString *)title;
- (NSDictionary *)entryForCategory:(NSString *)kIOSightingCategory withEntryID:(id)ID;

- (NSString *)titleForCategory:(NSString *)kIOSightingCategory withEntryID:(id)ID;
- (id)idForCategory:(NSString *)kIOSightingCategory withEntryTitle:(NSString *)title;

// Accuracy helpers
- (double)accuracyFromEntry:(NSDictionary *)accuracyEntry;
- (NSDictionary *)accuracyEntryFromID:(NSInteger)ID;                            // finds the entry by looking up the ID
- (NSDictionary *)accuracyEntryFromValue:(double)value;                         // finds the entry by looking up the Code
- (NSDictionary *)accuracyEntryFromNearestHigherValue:(double)value;            // finds the nearest higher entry - 5 => 10, 65 => 100, 20000 => 10000

// Time helpers
- (NSInteger)timeFromEntry:(NSDictionary *)timeEntry;                           // returns kIOTimeNotSure if Not sure entry
- (NSDictionary *)timeEntryFromValue:(id)value;                                 // could be used with NSNumber or NSString - eg. @(1) or @"01"
- (BOOL)isNotSureEntry:(NSDictionary *)timeEntry;

// Region helpers
+ (BOOL)shouldAutodetectRegion;
+ (NSString *)userPreSelectedRegionName;

@end







@interface NSDictionary (IOSightingAttributeDictionary)

- (NSComparisonResult)compare:(NSDictionary *)anotherDict;

- (NSString *)title;
- (id)ID;
- (NSString *)code;

@end
