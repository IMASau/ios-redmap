//
//  IOCategory.h
//  Redmap
//
//  Created by Evo Stamatov on 21/08/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Region, Sighting, Species;

@interface IOCategory : NSManagedObject

@property (nonatomic, retain) NSString * desc;
@property (nonatomic, retain) NSNumber * id;
@property (nonatomic, retain) NSString * longDesc;
@property (nonatomic, retain) NSString * pictureUrl;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSSet *regions;
@property (nonatomic, retain) NSSet *species;
@property (nonatomic, retain) NSSet *sightings;
@end

@interface IOCategory (CoreDataGeneratedAccessors)

- (void)addRegionsObject:(Region *)value;
- (void)removeRegionsObject:(Region *)value;
- (void)addRegions:(NSSet *)values;
- (void)removeRegions:(NSSet *)values;

- (void)addSpeciesObject:(Species *)value;
- (void)removeSpeciesObject:(Species *)value;
- (void)addSpecies:(NSSet *)values;
- (void)removeSpecies:(NSSet *)values;

- (void)addSightingsObject:(Sighting *)value;
- (void)removeSightingsObject:(Sighting *)value;
- (void)addSightings:(NSSet *)values;
- (void)removeSightings:(NSSet *)values;

@end
