//
//  IOAuth-defines.h
//  Redmap
//
//  Created by Evo Stamatov on 5/09/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#ifndef Redmap_IOAuth_defines_h
#define Redmap_IOAuth_defines_h

#define kIOExpiryIntervalThreeMinutes 180
#define kIOExpiryIntervalOneHour 3600

#if DEBUG
    #define kIOExpiryIntervalDefault kIOExpiryIntervalThreeMinutes
#else
    #define kIOExpiryIntervalDefault kIOExpiryIntervalOneHour
#endif

#define kIOExpiryIntervalForCurrentUsersAttributes kIOExpiryIntervalDefault
#define kIOExpiryIntervalForSightingAttributes     kIOExpiryIntervalDefault
#define kIOExpiryIntervalForRegions                kIOExpiryIntervalDefault
#define kIOExpiryIntervalForCategories             kIOExpiryIntervalDefault
#define kIOExpiryIntervalForSpecies                kIOExpiryIntervalDefault


#define IOTooShortValueException @"IOTooShortValueException"
#define IOTooLongValueException @"IOTooLongValueException"

#endif
