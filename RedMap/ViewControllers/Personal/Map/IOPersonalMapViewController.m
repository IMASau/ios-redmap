//
//  IOPersonalMapViewController.m
//  RedMap
//
//  Created by Evo Stamatov on 13/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOPersonalMapViewController.h"
#import "AppDelegate.h"
#import "IOMapSettingsViewController.h"
#import "IOPersonalAnnotation.h"
#import "IOPhotoCollection.h"
#import "IOPhotoWrapperViewController.h"
#import "IOSightingAttributesController.h"
#import "IOViewCurlButton.h"
#import "Sighting.h"
#import "Species.h"
#import "UIColor+IOColor.h"
#import <QuartzCore/QuartzCore.h>
#import "IOCoreDataHelper.h"

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

#define kDistaceFromPin 100000
#define kPinDropAnimationDuration 0.45

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface IOPersonalMapViewController () <MKMapViewDelegate, IOMapSettingsDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet IOViewCurlButton *cornerCurlButton;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
- (IBAction)showCornerView:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *showCornerViewButton;

@property (nonatomic, strong) NSDictionary *accuracy;
@property (assign) BOOL userLocationAcquired;

//@property (nonatomic, strong) IOMainTabBarViewController *mainTabBarViewController;

@property (nonatomic, strong) IOPhotoCollection *photos;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation IOPersonalMapViewController
{
    NSString *_currentlyVisibleUUID;
    BOOL _mapInitialized;
    BOOL _userInteractedWithMap;
    MKMapRect _zoomRect;
}

- (void)viewDidLoad
{
    logmethod();
    [super viewDidLoad];
    
#if TRACK
    [GoogleAnalytics sendEventWithCategory:@"checkpoint" withAction:@"viewDidLoad" withLabel:@"IOPersonalMapViewController" withValue:@1];
#endif
    
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = NO;
    
    _zoomRect = MKMapRectNull;
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didDragMap:)];
    pan.delegate = self;
    [self.mapView addGestureRecognizer:pan];
}

////////////////////////////////////////////////////////////////////////////////
- (void)didReceiveMemoryWarning
{
    logmethod();
    [super didReceiveMemoryWarning];
}

////////////////////////////////////////////////////////////////////////////////
- (void)dealloc
{
    logmethod();
    DDLogWarn(@"%@: Deallocating", self.class);
    
    _context = nil;
    _justPublishedSightingID = nil;
    _accuracy = nil;
    self.mapView.delegate = nil;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Gestures
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    logmethod();
    return YES;
}

- (void)didDragMap:(UIPanGestureRecognizer *)r
{
    logmethod();
    if (r.state == UIGestureRecognizerStateEnded)
    {
        r.delegate = nil;
        [self.mapView removeGestureRecognizer:r];
        
        DDLogVerbose(@"%@: The user moved the map", self.class);
        _userInteractedWithMap = YES;
    }
}

////////////////////////////////////////////////////////////////////////////////
#if TRACK
- (void)viewWillAppear:(BOOL)animated
{
    logmethod();
    [super viewWillAppear:animated];
    
    [GoogleAnalytics sendView:@"Personal - Map view"];
}
#endif

////////////////////////////////////////////////////////////////////////////////
- (void)viewWillDisappear:(BOOL)animated
{
    logmethod();
    [super viewWillDisappear:animated];
    
    self.parentViewController.hidesBottomBarWhenPushed = NO;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - MKMapView delegate

- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView
{
    logmethod();
    if (_mapInitialized)
        return;
    
    _mapInitialized = YES;
    [self initializeMapView:mapView];
}

////////////////////////////////////////////////////////////////////////////////
- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay
{
    logmethod();
    if ([overlay isKindOfClass:[MKCircle class]])
    {
        MKCircleView *circleView = [[MKCircleView alloc] initWithOverlay:overlay];
        
        circleView.lineWidth = 1.0;
        circleView.strokeColor = [UIColor IOBlueColor];
        circleView.fillColor = [[UIColor IOLightBlueColor] colorWithAlphaComponent:0.4f];
        
        return circleView;
    }
    else if ([overlay isKindOfClass:[MKPolygon class]])
    {
        MKPolygonView *polygonView = [[MKPolygonView alloc] initWithOverlay:overlay];
        polygonView.lineWidth = 1.0;
        polygonView.strokeColor = [UIColor IORedColor];
        polygonView.fillColor = [[UIColor IORedColor] colorWithAlphaComponent:0.4f];
        
        return polygonView;
    }
    
    return nil;
}

////////////////////////////////////////////////////////////////////////////////
- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    logmethod();
    // in case it's the user location, we already have an annotation, so just return nil
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    static NSString *annotationIdentifier = @"annotationIdentifier";
    MKAnnotationView *pinView = (MKPinAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
    
    if (!pinView)
    {
        pinView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationIdentifier];
        UIImage *pinImage = [UIImage imageNamed:@"marker-64"];
        CGFloat centerOffset = -5.0;
        pinView.centerOffset = CGPointMake(pinView.centerOffset.x + pinImage.size.width / 2 + centerOffset, pinView.centerOffset.y - pinImage.size.height / 2);
        pinView.image = pinImage;
    }
    else
        pinView.annotation = annotation;
    
    pinView.canShowCallout = YES;
    pinView.leftCalloutAccessoryView = nil;
    
    return pinView;
}

////////////////////////////////////////////////////////////////////////////////
- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)pinView
{
    logmethod();
    _userInteractedWithMap = YES;
    
    // TODO: cache the rendered images
    if ([pinView.annotation isKindOfClass:[IOPersonalAnnotation class]])
    {
        IOPersonalAnnotation *personalAnnotation = (IOPersonalAnnotation *)pinView.annotation;

        self.photos = [[IOPhotoCollection alloc] init];
        _currentlyVisibleUUID = personalAnnotation.sightingUUID;
        
        __weak __typeof(self)weakSelf = self;
        [self.photos reSetTheUUID:personalAnnotation.sightingUUID withCallback:^(NSError *error) {
            if (!error && weakSelf.photos.count > 0)
            {
                //UIImage *image = [photos photoAtIndex:0];
                UIImage *image = [weakSelf.photos photoAtIndex:0 forSize:CGSizeMake(32.0, 32.0)];
                CGRect frame = (CGRect){CGPointZero, image.size};
                
                UIImageView *imgView;
                imgView = [[UIImageView alloc] initWithImage:image];
                
                imgView.layer.borderColor = [[UIColor whiteColor] CGColor];
                imgView.layer.borderWidth = 2.0f;
                imgView.frame = frame;
                //imgView.contentMode = UIViewContentModeScaleAspectFit;
                UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
                button.frame = frame;
                //button.showsTouchWhenHighlighted = YES;
                [button addTarget:self action:@selector(openPhotoViewer:) forControlEvents:UIControlEventTouchUpInside];
                [button addSubview:imgView];
                pinView.leftCalloutAccessoryView = button;
                
            }
            
            weakSelf.photos = nil;
        }];
    }
}

////////////////////////////////////////////////////////////////////////////////
- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    logmethod();
    _currentlyVisibleUUID = nil;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Custom methods

- (void)initializeMapView:(MKMapView *)mapView
{
    logmethod();
    DDLogVerbose(@"%@: Initializing the map view", self.class);
    
    Sighting *sighting;
    
    if (self.justPublishedSightingID)
    {
        DDLogVerbose(@"%@: Have a just published sighting", self.class);
        sighting = (Sighting *)[self.context objectWithID:self.justPublishedSightingID];
        self.justPublishedSightingID = nil;
    }
    
    if (self.fetchedResultsController.fetchedObjects.count > 0)
    {
        __weak __typeof(self)weakSelf = self;
        
        NSArray *fetchedObjects = [self.fetchedResultsController.fetchedObjects copy];
        
        [fetchedObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            Sighting *aSighting = (Sighting *)obj;
            
            if (sighting && sighting == aSighting)
            {
                DDLogVerbose(@"%@: Skipping the just published sighting", weakSelf.class);
                return;
            }
            
            [weakSelf dropPinForSighting:aSighting mapView:mapView animated:NO andSelectIt:NO];
            
            //[IOCoreDataHelper faultObjectWithID:aSighting.objectID inContext:weakSelf.context];
        }];
        
        if (!sighting && !_userInteractedWithMap)
            [self zoomMapToShowAnnotations:mapView];
    }
    else if (!sighting)
    {
        DDLogVerbose(@"%@: Zoom to the boundaries of Australia", self.class);
    
        [self zoomMapViewIntoBoundariesOfAustralia:mapView];
    }
    
    if (sighting)
    {
        DDLogVerbose(@"%@: Adding a special pin for the just published sighting", self.class);
        [self dropPinForSighting:sighting mapView:mapView animated:YES andSelectIt:YES];
        
        DDLogVerbose(@"%@: Zooming to show the just published sighting", self.class);
        [self zoomMapView:mapView into:CLLocationCoordinate2DMake([sighting.locationLat floatValue], [sighting.locationLng floatValue]) distance:kDistaceFromPin animated:YES];
        
        //[IOCoreDataHelper faultObjectWithID:sighting.objectID inContext:self.context];
    }
}

- (void)zoomMapToShowAnnotations:(MKMapView *)mapView
{
    logmethod();
    if (mapView.annotations.count > 1)
    {
        DDLogVerbose(@"%@: Zooming to wrap all annotations", self.class);
        
        for (id <MKAnnotation> annotation in mapView.annotations)
            _zoomRect = [self includeAnnotation:annotation intoMapRect:_zoomRect];
        [mapView setVisibleMapRect:_zoomRect edgePadding:UIEdgeInsetsMake(20.0f, 20.0f, 20.0f, 20.0f) animated:YES];
    }
    else if (mapView.annotations.count == 1)
    {
        DDLogVerbose(@"%@: Zooming to show a single annotation", self.class);
        
        id <MKAnnotation> annotation = [mapView.annotations lastObject];
        [self zoomMapView:mapView into:annotation.coordinate distance:kDistaceFromPin animated:YES];
    }
}

////////////////////////////////////////////////////////////////////////////////
- (void)zoomMapViewIntoBoundariesOfAustralia:(MKMapView *)mapView
{
    logmethod();
    CLLocationCoordinate2D nw, se;
    
    nw = CLLocationCoordinate2DMake(-7.410849283839832,  112.41210912499992);
    se = CLLocationCoordinate2DMake(-44.248667520681586, 154.07226537499992);
    
    MKMapPoint topLeftCorner = MKMapPointForCoordinate(nw);
    MKMapPoint bottomRightCorner = MKMapPointForCoordinate(se);
    
    CGFloat width = bottomRightCorner.x - topLeftCorner.x;
    CGFloat height = bottomRightCorner.y - topLeftCorner.y;
    
    MKMapRect zoomRect = MKMapRectMake(topLeftCorner.x, topLeftCorner.y, width, height);
    [mapView setVisibleMapRect:zoomRect edgePadding:UIEdgeInsetsMake(20.0f, 20.0f, 20.0f, 20.0f) animated:NO];
}

////////////////////////////////////////////////////////////////////////////////
- (MKMapRect)includeAnnotation:(id <MKAnnotation>)annotation intoMapRect:(MKMapRect)mapRect
{
    logmethod();
    MKMapPoint coordinatePoint = MKMapPointForCoordinate(annotation.coordinate);
    MKMapRect pointRect = MKMapRectMake(coordinatePoint.x, coordinatePoint.y, 0.1f, 0.1f);
    return MKMapRectUnion(mapRect, pointRect);
}

////////////////////////////////////////////////////////////////////////////////
- (void)openPhotoViewer:(id)sender
{
    logmethod();
    DDLogVerbose(@"%@: Opening photo viewer", self.class);
    
    IOPhotoWrapperViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"IOPhotoWrapperSBID"];
    vc.sightingUUID = _currentlyVisibleUUID;
    self.parentViewController.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

////////////////////////////////////////////////////////////////////////////////
- (void)dropPinForSighting:(Sighting *)sighting mapView:(MKMapView *)mapView animated:(BOOL)animated andSelectIt:(BOOL)selectIt
{
    logmethod();
    DDLogVerbose(@"%@: Adding a pin for sighting: %@", self.class, sighting.uuid);
    
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([sighting.locationLat doubleValue], [sighting.locationLng doubleValue]);
    
    NSString *pinTitle, *pinSubtitle;
    Species *species = sighting.species;
    
    if (species != nil)
    {
        pinTitle = species.commonName;
        pinSubtitle = species.speciesName;
    }
    else if ([sighting.otherSpecies boolValue])
    {
        pinTitle = sighting.otherSpeciesCommonName;
        pinSubtitle = sighting.otherSpeciesName;
    }
    else
        pinTitle = @"Error";
    
    IOPersonalAnnotation *droppedPin = [[IOPersonalAnnotation alloc] initWithCoordinate:coordinate
                                                                                  title:pinTitle
                                                                               subtitle:pinSubtitle];
    if (animated)
        droppedPin.animatesDrop = YES;
    
    droppedPin.sightingUUID = sighting.uuid;
    
    double accuracy = [[IOSightingAttributesController sharedInstance] accuracyFromEntry:sighting.locationAccuracy];
    MKCircle *circle = [MKCircle circleWithCenterCoordinate:coordinate radius:accuracy];
    [mapView addOverlay:circle];
    droppedPin.overlay = circle;
    
    [mapView addAnnotation:droppedPin];
    if (selectIt)
        [mapView selectAnnotation:droppedPin animated:YES];
}

////////////////////////////////////////////////////////////////////////////////
- (void)zoomMapView:(MKMapView *)mapView into:(CLLocationCoordinate2D)zoomCoordinate distance:(CGFloat)distance animated:(BOOL)animated
{
    logmethod();
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(zoomCoordinate, distance, distance);
    [mapView setRegion:region animated:animated];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - IBActions

- (IBAction)showCornerView:(id)sender
{
    logmethod();
    IOMapSettingsViewController *hiddenVC = [self.storyboard instantiateViewControllerWithIdentifier:@"MapSettingsSBID"];
    hiddenVC.modalTransitionStyle = UIModalTransitionStylePartialCurl;
    hiddenVC.delegate = self;
    hiddenVC.mapType = self.mapView.mapType;
    
    [self presentViewController:hiddenVC animated:YES completion:nil];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Map Settings delegate

- (void)mapTypeChangedTo:(MKMapType)mapType
{
    logmethod();
    self.mapView.mapType = mapType;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - IOPersonalFetchDelegate Protocol

- (void)fetchedResultsInsertedObject:(id)anObject newIndexPath:(NSIndexPath *)newIndexPath
{
    logmethod();
    Sighting *aSighting = (Sighting *)anObject;
    
    if (aSighting)
    {
        NSString *sightingUUID = aSighting.uuid;
        DDLogVerbose(@"%@: Inserting an annotation for UUID: %@", self.class, sightingUUID);
        [self dropPinForSighting:aSighting mapView:self.mapView animated:YES andSelectIt:NO];
        //[IOCoreDataHelper faultObjectWithID:aSighting.objectID inContext:self.context];
    }
}

////////////////////////////////////////////////////////////////////////////////
- (void)fetchedResultsDeletedObject:(id)anObject atIndexPath:(NSIndexPath *)atIndexPath
{
    logmethod();
    Sighting *aSighting = (Sighting *)anObject;
    if (!aSighting)
        return;
    
    NSString *sightingUUID = aSighting.uuid;
    //[IOCoreDataHelper faultObjectWithID:aSighting.objectID inContext:self.context];
    
    NSMutableArray *annotationsToRemove = [NSMutableArray new];
    NSMutableArray *overlaysToRemove = [NSMutableArray new];
    for (id <MKAnnotation> annotation in self.mapView.annotations)
    {
        if ([annotation isKindOfClass:[MKUserLocation class]])
            continue;
        
        if ([annotation isKindOfClass:[IOPersonalAnnotation class]])
        {
            IOPersonalAnnotation *personalAnnotation = (IOPersonalAnnotation *)annotation;
            if ([personalAnnotation.sightingUUID isEqualToString:sightingUUID])
            {
                [annotationsToRemove addObject:personalAnnotation];
                [overlaysToRemove addObject:personalAnnotation.overlay];
            }
        }
    }
    
    if (annotationsToRemove.count > 0)
    {
        DDLogVerbose(@"%@: Removing annotation for UUID: %@", self.class, sightingUUID);
        [self.mapView removeAnnotations:annotationsToRemove];
    }
    
    if (overlaysToRemove.count > 0)
    {
        DDLogVerbose(@"%@: Removing overlays for UUID: %@", self.class, sightingUUID);
        [self.mapView removeOverlays:overlaysToRemove];
    }
}

////////////////////////////////////////////////////////////////////////////////
- (void)fetchedResultsUpdatedObject:(id)anObject atIndexPath:(NSIndexPath *)atIndexPath
{
    logmethod();
    [self fetchedResultsDeletedObject:anObject atIndexPath:atIndexPath];
    [self fetchedResultsInsertedObject:anObject newIndexPath:atIndexPath];
}

////////////////////////////////////////////////////////////////////////////////
- (void)fetchedResultsDidChange
{
    logmethod();
    if (_mapInitialized && !_userInteractedWithMap)
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(zoomMapToShowAnnotations:) object:self.mapView];
        
        NSTimeInterval delay = 0.5f;
        [self performSelector:@selector(zoomMapToShowAnnotations:) withObject:self.mapView afterDelay:delay];
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - IOPersonalViewControllerProtocol

/*
 - (void)viewDidBecomeTopmost
{
    IOLog(@"TOPMOST");
}
 */

@end
