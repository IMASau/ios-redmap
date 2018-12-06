//
//  Sighting.h
//  Redmap
//
//  Created by Evo Stamatov on 18/09/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Sighting-typedefs.h"

@class Category, Region, Species, User;

@interface Sighting : NSManagedObject

@property (nonatomic, retain) id activity;
@property (nonatomic, retain) NSString * comment;
@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) NSDate * dateModified;
@property (nonatomic, retain) NSDate * dateSpotted;
@property (nonatomic, retain) NSNumber * depth;
@property (nonatomic, retain) id locationAccuracy;
@property (nonatomic, retain) NSNumber * locationLat;
@property (nonatomic, retain) NSNumber * locationLng;
@property (nonatomic, retain) NSNumber * locationStatus;
@property (nonatomic, retain) NSNumber * otherSpecies;
@property (nonatomic, retain) NSString * otherSpeciesCommonName;
@property (nonatomic, retain) NSString * otherSpeciesName;
@property (nonatomic, retain) NSNumber * photosCount;
@property (nonatomic, retain) NSNumber * published;
@property (nonatomic, retain) NSNumber * sightingID;
@property (nonatomic, retain) id speciesCount;
@property (nonatomic, retain) id speciesHabitat;
@property (nonatomic, retain) NSNumber * speciesLength;
@property (nonatomic, retain) id speciesLengthMethod;
@property (nonatomic, retain) id speciesSex;
@property (nonatomic, retain) NSNumber * speciesWeight;
@property (nonatomic, retain) id speciesWeightMethod;
@property (nonatomic, retain) NSNumber * status;
@property (nonatomic, retain) id time;
@property (nonatomic, retain) NSNumber * timeNotSure;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * uuid;
@property (nonatomic, retain) NSNumber * validSighting;
@property (nonatomic, retain) NSNumber * waterTemperature;
@property (nonatomic, retain) Category *category;
@property (nonatomic, retain) Region *region;
@property (nonatomic, retain) Species *species;
@property (nonatomic, retain) User *user;

@end
