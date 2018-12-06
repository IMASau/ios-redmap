//
//  Region.h
//  Redmap
//
//  Created by Evo Stamatov on 21/08/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Category, Sighting, Species;

@interface Region : NSManagedObject

@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSString * sightingsUrl;
@property (nonatomic, retain) NSString * slug;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSSet *categories;
@property (nonatomic, retain) NSSet *species;
@property (nonatomic, retain) NSSet *sightings;
@end

@interface Region (CoreDataGeneratedAccessors)

- (void)addCategoriesObject:(Category *)value;
- (void)removeCategoriesObject:(Category *)value;
- (void)addCategories:(NSSet *)values;
- (void)removeCategories:(NSSet *)values;

- (void)addSpeciesObject:(Species *)value;
- (void)removeSpeciesObject:(Species *)value;
- (void)addSpecies:(NSSet *)values;
- (void)removeSpecies:(NSSet *)values;

- (void)addSightingsObject:(Sighting *)value;
- (void)removeSightingsObject:(Sighting *)value;
- (void)addSightings:(NSSet *)values;
- (void)removeSightings:(NSSet *)values;

@end
