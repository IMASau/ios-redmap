//
//  IOGeoLocation.h
//  Redmap
//
//  Created by Evo Stamatov on 14/08/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <Foundation/Foundation.h>

#define IOGeoLocationKeepMonitoringSignificantLocationChanges 0

#define kIOMaxLocationUpdates 10
#define kIOMinimumLocationReads 2
#define kIOLocationUnknownText NSLocalizedString(@"Unknown", @"When Geolocation initializes and the current region is unknown");

// Notifications
// Recieves a notification with userInfo with kIOGeoLocationObject - the shared IOGeoLocation object
#define kIOGeoLocationAcquiredNotification @"IOGeoLocationAcquiredNotification"
#define kIOGeoLocationRegionAcquiredNotification @"IOGeoLocationRegionAcquiredNotification"
#define kIOGeoLocationErrorAcquiringNotification @"IOGeoLocationErrorAcquiringNotification"

// Notifications userInfo object keys
#define kIOGeoLocationObject @"IOGeoLocationObject" // self
#define kIOGeoLocationError @"IOGeoLocationError" // NSError

@protocol IOGeoLocationDelegate;


@interface IOGeoLocation : NSObject

+ (IOGeoLocation *)sharedInstance;
- (void)deactivate;
- (void)updateIfNeeded;

@property (nonatomic, weak) id <IOGeoLocationDelegate> delegate;
@property (nonatomic, assign, readonly) BOOL finalCall;
@property (nonatomic, assign, readonly, getter=isSearching) BOOL searching;

@property (nonatomic, assign, readonly) double lat;
@property (nonatomic, assign, readonly) double lng;
@property (nonatomic, assign, readonly) double accuracy;
@property (nonatomic, copy, readonly) NSString *region;

@property (nonatomic, assign, readonly) BOOL regionAcquired;
@property (nonatomic, assign, readonly) BOOL locationAcquired;

@property (nonatomic, assign) BOOL showAlertOnError;
@property (nonatomic, assign) BOOL showAlertOnFinalCallWhenNoLocationWasAcquired;

@end


@protocol IOGeoLocationDelegate <NSObject>

@optional
- (void)geoLocationAcquired:(IOGeoLocation *)geoLocation latitude:(double)latitude longitude:(double)longitude accuracy:(double)accuracy;
- (void)geoLocationAcquired:(IOGeoLocation *)geoLocation region:(NSString *)regionName; // can be kIOLocationUnknownText

@end