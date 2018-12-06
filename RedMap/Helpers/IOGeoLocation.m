//
//  IOGeoLocation.m
//  Redmap
//
//  Created by Evo Stamatov on 14/08/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOGeoLocation.h"
#import <CoreLocation/CoreLocation.h>

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

@interface IOGeoLocation () <CLLocationManagerDelegate>
{
    NSTimer *_initiateLocationManagerTimer;
}

@property (nonatomic, assign, readwrite) double lat;
@property (nonatomic, assign, readwrite) double lng;
@property (nonatomic, assign, readwrite) double accuracy;
@property (nonatomic, copy, readwrite) NSString *region;

@property (nonatomic, strong) CLLocation *previousLocation;
@property (nonatomic, assign) int locationUpdatesCounter;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign, readwrite) BOOL finalCall;
@property (nonatomic, assign, readwrite) BOOL regionAcquired;
@property (nonatomic, assign, readwrite) BOOL locationAcquired;

@property (nonatomic, assign, readwrite, getter=isSearching) BOOL searching;
@property (nonatomic, strong) NSTimer *locationManagerTimeoutTimer;

@end


@implementation IOGeoLocation

+ (IOGeoLocation *)sharedInstance
{
    static IOGeoLocation *instance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[IOGeoLocation alloc] init];
    });
    
    return instance;
}



- (id)init
{
    self = [super init];
    if (self)
    {
        logmethod();
        _accuracy = DBL_MAX;
        _lat = 0.0;
        _lng = 0.0;
        _region = kIOLocationUnknownText;
        _locationAcquired = NO;
        _regionAcquired = NO;
        _initiateLocationManagerTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                                         target:self
                                                                       selector:@selector(initiateLocationManager)
                                                                       userInfo:nil
                                                                        repeats:NO];
    }
    return self;
}



- (void)deactivate
{
    logmethod();

    if (_initiateLocationManagerTimer)
    {
        [_initiateLocationManagerTimer invalidate];
    }

    if (self.locationManagerTimeoutTimer)
    {
        [self.locationManagerTimeoutTimer invalidate];
    }
    
    [self.locationManager stopUpdatingLocation];
}



- (void)reactivate
{
    logmethod();
    // NOTE: lat lng of 0.0 is an actual location, but it is unlikely,
    // because it is in the middle of the Atlantic ocean
    // I hope noone goes exactly there with this app running :)
    if (self.accuracy > 10.0 || self.lat == 0.0 || self.lng == 0.0)
        [self initiateLocationManager];
}



- (void)updateIfNeeded
{
    logmethod();
    if (self.finalCall)
        [self updateLocalVariablesWithLocation:self.previousLocation];
}



- (void)initiateLocationManager
{
    logmethod();
    //IOLog(@"Autodetecting location");
    
    self.finalCall = NO;

    if ([CLLocationManager locationServicesEnabled])
    {
        CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
        if (authorizationStatus == kCLAuthorizationStatusDenied || authorizationStatus == kCLAuthorizationStatusRestricted)
        {
            [self takeActionUponLocationManagerAuthorizationStatusUpdate:authorizationStatus];
        }
        else
        {
            self.locationManager = [[CLLocationManager alloc] init];
            self.locationManager.delegate = self;
            self.locationManager.distanceFilter = kCLDistanceFilterNone;
            self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;

            [self takeActionUponLocationManagerAuthorizationStatusUpdate:authorizationStatus];
        }
    }
    else
    {
        DDLogError(@"Location services are disabled");
    }

    //[self.locationManager startUpdatingLocation];
    
    _initiateLocationManagerTimer = nil;
}



- (void)takeActionUponLocationManagerAuthorizationStatusUpdate:(CLAuthorizationStatus)status
{
    logmethod();

    if (status == kCLAuthorizationStatusNotDetermined)
    {
        [self requestWhenInUseAuthorizationBasedOnStatus:status];
    }
    else if (status == kCLAuthorizationStatusRestricted || status == kCLAuthorizationStatusDenied)
    {
        //logmessage(@"LocationServices are denied or restricted");

        self.searching = NO;

        /*
        if (_callback)
        {
            NSString *description;
            if (status == kCLAuthorizationStatusDenied)
                description = @"Cannot obtain Current Location. Location services are denied. This can be changed in the Settings app, under Privacy.";
            else
                description = @"Cannot obtain Current Location. Location services are restricted and may not be possible to change. Check in the Settings app, under Privacy.";
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: description };

            NSInteger code = status == kCLAuthorizationStatusDenied ? MTSLocationErrorLocationServicesDenied : MTSLocationErrorLocationServicesRestricted;

            NSError *error = [NSError errorWithDomain:kMTSLocationErrorDomain code:code userInfo:userInfo];

            [self unsetCallback:nil error:error];
        }
         */
    }
    else if (status > kCLAuthorizationStatusDenied)
    {
        [self fireLocationManager];
    }
}



- (void)requestWhenInUseAuthorizationBasedOnStatus:(CLAuthorizationStatus)status
{
    logmethod();

    if (self.locationManager)
    {
        if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)] && status == kCLAuthorizationStatusNotDetermined)
            // NOTE: make sure to add "NSLocationWhenInUseUsageDescription" in Info.plist
            [self.locationManager requestWhenInUseAuthorization];
        else
            [self fireLocationManager];
    }
}



- (void)fireLocationManager
{
    logmethod();

    if (!self.isSearching)
    {
        self.searching = YES;

        [self.locationManager startUpdatingLocation];
        
        self.locationManagerTimeoutTimer = [NSTimer timerWithTimeInterval:10.0
                                                                   target:self
                                                                 selector:@selector(timeoutLocationManager:)
                                                                 userInfo:nil
                                                                  repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:self.locationManagerTimeoutTimer
                                     forMode:NSRunLoopCommonModes];
    }
}



- (void)timeoutLocationManager:(NSTimer *)timer
{
    logmethod();

    if (self.previousLocation == nil)
    {
        NSDictionary *userInfo = @{
                                  NSLocalizedDescriptionKey: @"Locating timed out"
                                  };
        NSError *error = [NSError errorWithDomain:@"IOGeoLocation" code:9000 userInfo:userInfo];
        [self locationManager:self.locationManager didFailWithError:error];
    }
    //else
        //[self locationManager:_locationManager didGetGoodEnoughLocation:_latestCLLocation];
}



- (void)updateLocalVariablesWithLocation:(CLLocation *)location
{
    logmethod();
    self.accuracy = MAX(location.horizontalAccuracy, location.verticalAccuracy);
    self.lat = location.coordinate.latitude;
    self.lng = location.coordinate.longitude;
    
    self.locationAcquired = YES;
    
    //IOLog(@"Acquired Lat: %f, Lng: %f, Accuracy: %f", self.lat, self.lng, self.accuracy);
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(geoLocationAcquired:latitude:longitude:accuracy:)])
        [self.delegate geoLocationAcquired:self latitude:self.lat longitude:self.lng accuracy:self.accuracy];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kIOGeoLocationAcquiredNotification object:nil userInfo:@{ kIOGeoLocationObject: self }];
    
    [self geocodeLocation:location];
}



- (void)updateLocalVariablesWithPlacemark:(CLPlacemark *)placemark
{
    logmethod();
    if (![[placemark administrativeArea] isEqualToString:@""])
    {
        self.region = [placemark administrativeArea];
        self.regionAcquired = YES;
    }
    
    //IOLog(@"Acquired Region: %@", self.region);
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(geoLocationAcquired:region:)])
        [self.delegate geoLocationAcquired:self region:self.region];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kIOGeoLocationRegionAcquiredNotification object:nil userInfo:@{ kIOGeoLocationObject: self }];
}



- (void)errorGeocode:(NSError *)error
{
    logmethod();
    switch (error.code) {
        case kCLErrorGeocodeFoundNoResult:
            DDLogError(@"%@: ERROR. A geocode request yielded no result", self.class);
            if (self.finalCall && self.showAlertOnFinalCallWhenNoLocationWasAcquired)
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oopsie"
                                                                message:@"Unfortunately, we could't determine the region you are in. You'll have to choose one manually."
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
            break;
            
        case kCLErrorGeocodeFoundPartialResult:
            //IOLog(@"A geocode request yielded a partial result");
            [[NSNotificationCenter defaultCenter] postNotificationName:kIOGeoLocationErrorAcquiringNotification object:nil userInfo:@{
                                                  kIOGeoLocationObject: self,
                                                   kIOGeoLocationError: error,
             }];
            break;
            
        case kCLErrorGeocodeCanceled:
            //IOLog(@"A geocode request was cancelled");
            [[NSNotificationCenter defaultCenter] postNotificationName:kIOGeoLocationErrorAcquiringNotification object:nil userInfo:@{
                                                  kIOGeoLocationObject: self,
                                                   kIOGeoLocationError: error,
             }];
            break;
            
    }
}



- (void)geocodeLocation:(CLLocation *)location
{
    logmethod();
    __weak IOGeoLocation *weakSelf = self;
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        if (!error && placemarks && placemarks.count > 0)
        {
            CLPlacemark *topResult = [placemarks objectAtIndex:0];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf updateLocalVariablesWithPlacemark:topResult];
            });
        }
        else if (error)
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf errorGeocode:error];
            });
    }];
}



#pragma mark - CLLocationManager delegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    [self takeActionUponLocationManagerAuthorizationStatusUpdate:status];
}



- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    logmethod();

    [self.locationManagerTimeoutTimer invalidate];
    self.locationManagerTimeoutTimer = nil;

    self.locationUpdatesCounter ++;

    CLLocation *location = (CLLocation *)[locations lastObject];
    /*
    CLLocationDistance distanceInMeters = DBL_MAX;
    
    if (self.previousLocation)
    {
        distanceInMeters = [location distanceFromLocation:self.previousLocation];
        IOLog(@"[%@]: distance in meters: %f", self.class, distanceInMeters);
    }
     */

    self.previousLocation = location;
    
    if (self.locationUpdatesCounter > kIOMinimumLocationReads)
        [self updateLocalVariablesWithLocation:location];
    
    if (self.locationUpdatesCounter >= kIOMaxLocationUpdates ||
        (self.locationUpdatesCounter > kIOMinimumLocationReads && MAX(location.horizontalAccuracy, location.verticalAccuracy) <= 10.0)
        //(self.locationUpdatesCounter > kIOMinimumLocationReads && distanceInMeters != DBL_MAX && distanceInMeters < 10)
        )
    {
        self.finalCall = YES;
        self.searching = NO;
        [self.locationManager stopUpdatingLocation];
        self.locationUpdatesCounter = 0;
    }
}



- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    logmethod();

    if (error.code == kCLErrorLocationUnknown)
        return;

    self.searching = NO;

    [self.locationManagerTimeoutTimer invalidate];
    self.locationManagerTimeoutTimer = nil;

    [self.locationManager stopUpdatingLocation];

    switch (error.code) {
        case kCLErrorNetwork:
            //IOLog(@"General network error");
            [[NSNotificationCenter defaultCenter] postNotificationName:kIOGeoLocationErrorAcquiringNotification object:nil userInfo:@{
                                                  kIOGeoLocationObject: self,
                                                   kIOGeoLocationError: error,
             }];
            break;
            
        case kCLErrorDenied:
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:kIOGeoLocationErrorAcquiringNotification object:nil userInfo:@{
                                                  kIOGeoLocationObject: self,
                                                   kIOGeoLocationError: error,
             }];
            
            if (self.showAlertOnError)
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oopsie"
                                                                message:@"You have denied access to the location services on your device. Please, change these setting if you wish to use autodetection of your location within the app."
                                                               delegate:nil
                                                      cancelButtonTitle:@"Dismiss"
                                                      otherButtonTitles:nil];
                
                [alert show];
            }
        }
            break;
            
        default:
            DDLogError(@"%@: ERROR with the location manager. [%ld]: %@", self.class, (long)error.code, error.localizedDescription);
            [[NSNotificationCenter defaultCenter] postNotificationName:kIOGeoLocationErrorAcquiringNotification object:nil userInfo:@{
                                                  kIOGeoLocationObject: self,
                                                   kIOGeoLocationError: error,
             }];
            break;
    }
    // TODO: notify user of the error
}

@end
