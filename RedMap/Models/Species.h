//
//  Species.h
//  Redmap
//
//  Created by Evo Stamatov on 6/09/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class IOCategory, Region, Sighting;

@interface Species : NSManagedObject

@property (nonatomic, retain) NSString * commonName;
@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSString * distributionUrl;
@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSString * imageCredit;
@property (nonatomic, retain) NSString * pictureUrl;
@property (nonatomic, retain) NSNumber * section;
@property (nonatomic, retain) NSString * shortDesc;
@property (nonatomic, retain) NSString * sightingsUrl;
@property (nonatomic, retain) NSString * speciesName;
@property (nonatomic, retain) NSDate * updateTime;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * notes;
@property (nonatomic, retain) NSSet *categories;
@property (nonatomic, retain) NSSet *regions;
@property (nonatomic, retain) NSSet *sightings;
@end

@interface Species (CoreDataGeneratedAccessors)

- (void)addCategoriesObject:(IOCategory *)value;
- (void)removeCategoriesObject:(IOCategory *)value;
- (void)addCategories:(NSSet *)values;
- (void)removeCategories:(NSSet *)values;

- (void)addRegionsObject:(Region *)value;
- (void)removeRegionsObject:(Region *)value;
- (void)addRegions:(NSSet *)values;
- (void)removeRegions:(NSSet *)values;

- (void)addSightingsObject:(Sighting *)value;
- (void)removeSightingsObject:(Sighting *)value;
- (void)addSightings:(NSSet *)values;
- (void)removeSightings:(NSSet *)values;

@end
