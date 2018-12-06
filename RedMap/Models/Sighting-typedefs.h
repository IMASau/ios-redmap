//
//  Sighting-typedefs.h
//  RedMap
//
//  Created by Evo Stamatov on 18/06/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#ifndef RedMap_Sighting_typedefs_h
#define RedMap_Sighting_typedefs_h

typedef NS_ENUM(NSInteger, IOSightingStatus) {
    IOSightingStatusDraft = 0,
    IOSightingStatusSaved,
    IOSightingStatusSyncing,
    IOSightingStatusSynced
};

typedef NS_ENUM(NSInteger, IOSightingLocationStatus) {
    IOSightingLocationStatusNotSet = 0,
    IOSightingLocationStatusAcquired,
    IOSightingLocationStatusManuallySet
};

#endif



#ifndef RedMap_Sighting_properties
#define RedMap_Sighting_properties

#define kIOSightingEntityName                     @"Sighting"
#define kIOSightingPropertyActivity               @"activity"
#define kIOSightingPropertyComment                @"comment"
#define kIOSightingPropertyDateCreated            @"dateCreated"
#define kIOSightingPropertyDateModified           @"dateModified"
#define kIOSightingPropertyDateSpotted            @"dateSpotted"
#define kIOSightingPropertyDepth                  @"depth"
#define kIOSightingPropertyLocationAccuracy       @"locationAccuracy"
#define kIOSightingPropertyLocationLat            @"locationLat"
#define kIOSightingPropertyLocationLng            @"locationLng"
#define kIOSightingPropertyLocationStatus         @"locationStatus"
#define kIOSightingPropertyOtherSpecies           @"otherSpecies"
#define kIOSightingPropertyOtherSpeciesCommonName @"otherSpeciesCommonName"
#define kIOSightingPropertyOtherSpeciesName       @"otherSpeciesName"
#define kIOSightingPropertyPhotosCount            @"photosCount"
#define kIOSightingPropertyRegion                 @"region"
#define kIOSightingPropertySpeciesCount           @"speciesCount"
#define kIOSightingPropertySpeciesHabitat         @"speciesHabitat"
#define kIOSightingPropertySpeciesLength          @"speciesLength"
#define kIOSightingPropertySpeciesLengthMethod    @"speciesLengthMethod"
#define kIOSightingPropertySpeciesSex             @"speciesSex"
#define kIOSightingPropertySpeciesWeight          @"speciesWeight"
#define kIOSightingPropertySpeciesWeightMethod    @"speciesWeightMethod"
#define kIOSightingPropertyStatus                 @"status"
#define kIOSightingPropertyTimeNotSure            @"timeNotSure"
#define kIOSightingPropertyUserID                 @"userID"
#define kIOSightingPropertyUuid                   @"uuid"
#define kIOSightingPropertyWaterTemperature       @"waterTemperature"
#define kIOSightingPropertyTime                   @"time"
#define kIOSightingPropertyCategory               @"category"
#define kIOSightingPropertySpecies                @"species"

#endif
