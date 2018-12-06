//
//  IOLocationVC.m
//  RedMap
//
//  Created by Evo Stamatov on 22/04/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOLocationVC.h"
#import "IOLocationVCAnnotation.h"
#import "UIColor+IOColor.h"
#import "IOMapSettingsViewController.h"
#import "IOLocationVCAnnotationView.h"
#import "IOSightingAttributesController.h"
#import "IOLoggingCellControllerKeys.h"
#import "IOMapRegionObject.h"


#define USE_DEFAULT_PIN_VIEW 0
#define kPinDropAnimationDuration 0.45
#define kPinPtOffsetWhenDragging 44.0

static NSString *IOLocationViewControllerDoneText = @"Update";
static NSString *IOLocationViewControllerApproveText = @"Confirm";

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface IOLocationVC () <IOMapSettingsDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *levelSegments;
- (IBAction)setAccuracyLevel:(id)sender;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *refreshLocationButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;

@property (nonatomic, strong) NSDictionary *levelsInMetres;
@property (nonatomic, strong) IOLocationVCAnnotation *pinAnnotation;
@property (nonatomic, strong) MKCircle *circle;
@property (nonatomic, assign) BOOL mapInitialized;
@property (strong, nonatomic) UILongPressGestureRecognizer *longPress;
@property (nonatomic, assign) BOOL showingRegionBorders;
@property (nonatomic, strong) MKPolygon *regionBorders;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation IOLocationVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    self.longPress.delegate = self;
    [self.view addGestureRecognizer:self.longPress];
    
    [self.refreshLocationButton setTarget:self];
    [self.refreshLocationButton setAction:@selector(refreshLocationButtonClicked:)];
    
    [self updateCircle];
    [self updateZoomSegmentIndexByMetres:self.locationAccuracyInMetres];
    
    self.doneButton.title = self.unconfirmed ? IOLocationViewControllerApproveText : IOLocationViewControllerDoneText;
}

////////////////////////////////////////////////////////////////////////////////
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

////////////////////////////////////////////////////////////////////////////////
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Getters and Setters

- (NSDictionary *)levelsInMetres
{
    if (_levelsInMetres == nil)
    {
        _levelsInMetres = @{
                           @"10m":  @10.0f,
                           @"100m": @100.0f,
                           @"1km":  @1000.0f,
                           @"10km": @10000.0f,
                           };
    }
    return _levelsInMetres;
}

////////////////////////////////////////////////////////////////////////////////
- (void)setLocationCoordinate:(CLLocationCoordinate2D)locationCoordinate
{
    if (_locationCoordinate.latitude != locationCoordinate.latitude || _locationCoordinate.longitude != locationCoordinate.longitude)
    {
        _locationCoordinate = locationCoordinate;
        [self updateCircle];
    }
}

////////////////////////////////////////////////////////////////////////////////
- (void)setLocationAccuracyInMetres:(CGFloat)locationAccuracyInMetres
{
    NSDictionary *accuracy = [[IOSightingAttributesController sharedInstance] accuracyEntryFromNearestHigherValue:locationAccuracyInMetres];
    if (accuracy == nil)
        return;
    
    CGFloat correctedLocationAccuracy = [accuracy.code floatValue];
    if (_locationAccuracyInMetres != correctedLocationAccuracy)
    {
        _locationAccuracyInMetres = correctedLocationAccuracy;
        [self updateCircle];
        [self updateZoomSegmentIndexByMetres:correctedLocationAccuracy];
    }
}

////////////////////////////////////////////////////////////////////////////////
- (void)setLocationCoordinate:(CLLocationCoordinate2D)locationCoordinate andLocationAccuracyInMetres:(CGFloat)locationAccuracyInMetres
{
    BOOL updateCircle = NO;
    if (_locationCoordinate.latitude != locationCoordinate.latitude || _locationCoordinate.longitude != locationCoordinate.longitude)
    {
        _locationCoordinate = locationCoordinate;
        updateCircle = YES;
    }
    
    if (_locationAccuracyInMetres != locationAccuracyInMetres)
    {
        _locationAccuracyInMetres = locationAccuracyInMetres;
        updateCircle = YES;
    }
    
    if (updateCircle)
        [self updateCircle];
}

////////////////////////////////////////////////////////////////////////////////
#if ALLOW_SHOWING_OF_REGION_BORDERS
- (void)setShowingRegionBorders:(BOOL)showingRegionBorders
{
    _showingRegionBorders = showingRegionBorders;
    if (showingRegionBorders && self.regionName)
        [self addRegionOverlay:self.regionName];
    else
        if (self.regionBorders)
            [self.mapView removeOverlay:self.regionBorders];
}
#endif

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Custom methods

- (void)updateZoomSegmentIndexByMetres:(CGFloat)metres
{
    NSInteger index = 0;
    if (metres > 1000.0f)
        index = 3;
    else if (metres > 100.0f)
        index = 2;
    else if (metres > 10.0f)
        index = 1;
    
    self.levelSegments.selectedSegmentIndex = index;
}

////////////////////////////////////////////////////////////////////////////////
- (void)dropThePin
{
    if (self.pinAnnotation)
    {
        [self.mapView removeAnnotation:self.pinAnnotation];
        self.pinAnnotation.coordinate = self.locationCoordinate;
    }
    else
        self.pinAnnotation = [[IOLocationVCAnnotation alloc] initWithCoordinate:self.locationCoordinate];
    
    self.pinAnnotation.animatesDrop = YES;
    [self.mapView addAnnotation:self.pinAnnotation];
    [self.mapView selectAnnotation:self.pinAnnotation animated:NO];
}

////////////////////////////////////////////////////////////////////////////////
- (void)moveThePinToCoordinate:(CLLocationCoordinate2D)pinCoordinate
{
    if (self.pinAnnotation)
    {
        [self.mapView removeAnnotation:self.pinAnnotation];
        self.locationCoordinate = pinCoordinate;
        self.pinAnnotation.coordinate = self.locationCoordinate;
    }
    else
    {
        self.locationCoordinate = pinCoordinate;
        self.pinAnnotation = [[IOLocationVCAnnotation alloc] initWithCoordinate:self.locationCoordinate];
    }
    
    self.pinAnnotation.animatesDrop = NO;
    [self.mapView addAnnotation:self.pinAnnotation];
}

////////////////////////////////////////////////////////////////////////////////
- (void)updateCircle
{
    [self addCircleOverlayWithCenterCoordinate:self.locationCoordinate radius:self.locationAccuracyInMetres];
}

////////////////////////////////////////////////////////////////////////////////
- (void)addCircleOverlayWithCenterCoordinate:(CLLocationCoordinate2D)centerCoordinate radius:(CGFloat)radius
{
    if (self.circle)
        [self.mapView removeOverlay:self.circle];
    
    self.circle = [MKCircle circleWithCenterCoordinate:centerCoordinate radius:radius];
    [self.mapView addOverlay:self.circle];
}

////////////////////////////////////////////////////////////////////////////////
- (void)zoomInto:(CLLocationCoordinate2D)zoomCoordinate distance:(CGFloat)distance animated:(BOOL)animated
{
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(zoomCoordinate, distance, distance);
    [self.mapView setRegion:region animated:animated];
}

////////////////////////////////////////////////////////////////////////////////
- (NSArray *)regionPointsForRegion:(NSString *)regionName
{
    static id regionsPaths = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *regionsPathsJSON = @"{\"New South Wales\":[[149.6510187328861,-39.33284222173442],[156.6447797975237,-39.5413110018877],[159.4980333071544,-27.09125952600292],[141.0655124305001,-29.16733244809674],[141.1320928654111,-34.06243822399932],[149.746172553171,-37.47278600141384],[149.6510187328861,-39.33284222173442]],\"Northern Territory\":[[138.1236108545581,-10.2516925663555],[127.9977731065961,-9.0645241337951],[128.9118274580214,-26.14341734492546],[138.0283716212627,-26.03988222620065],[138.1236108545581,-10.2516925663555]],\"Queensland\":[[138.0345474282234,-26.08713861405066],[141.0001993573809,-26.16533362790543],[141.1049469687183,-29.04820288487291],[153.521736679225,-28.28907377918563],[158.0644917925188,-25.43935957006736],[145.6076768183317,-9.495249291650364],[139.8501220318818,-10.02615982575578],[138.0278356628233,-16.80981979704593],[138.0345474282234,-26.08713861405066]],\"South Australia\":[[129.6315930938666,-37.23429115008388],[140.93384257679,-39.32729354152659],[140.8098409997071,-26.26951514986825],[129.161587340565,-26.30921632490599],[129.6315930938666,-37.23429115008388]],\"Tasmania\":[[141.9509842435199,-43.48355127390608],[147.0158429295712,-44.88135409569165],[150.7146233887154,-44.24412224317301],[150.9049959105599,-40.48660735682775],[148.9910524123078,-39.30271798355914],[142.3837012007776,-39.35990228822149],[141.9509842435199,-43.48355127390608]],\"Victoria\":[[141.0534847571628,-34.14430776342346],[141.0544273179301,-39.33226144118233],[148.8616529485754,-39.46564263311937],[149.5687044103001,-39.30967263464959],[149.6841943465396,-37.51725198108272],[141.0534847571628,-34.14430776342346]],\"Western Australia\":[[129.1301644985577,-15.04063693280441],[128.4500714588889,-12.90413227570088],[121.4928303942802,-12.17482067443013],[110.2718695145673,-21.36547558382702],[108.9736667824489,-34.28968215098432],[116.1471228637673,-40.00251657168517],[129.5866527753336,-37.20388013389088],[128.9531480324681,-31.79266577045803],[129.1301644985577,-15.04063693280441]]}";
        regionsPaths = [NSJSONSerialization JSONObjectWithData:[regionsPathsJSON dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    });
    
    NSArray *path = (NSArray *)[(NSDictionary *)regionsPaths objectForKey:regionName];
    return path;
}

////////////////////////////////////////////////////////////////////////////////
- (MKPolygon *)polygonForRegion:(NSString *)regionName
{
    NSArray *path = [self regionPointsForRegion:regionName];
    
    NSInteger numberOfPoints = [path count];
    CLLocationCoordinate2D coordinates[numberOfPoints];
    
    for (NSInteger index = 0; index < numberOfPoints; index++)
    {
        CLLocation *location = [[CLLocation alloc] initWithLatitude:[[path[index] objectAtIndex:1] floatValue] longitude:[[path[index] objectAtIndex:0] floatValue]];
        coordinates[index] = location.coordinate;
    }
    
    MKPolygon *polygon = [MKPolygon polygonWithCoordinates:coordinates count:numberOfPoints];
    return polygon;
}

////////////////////////////////////////////////////////////////////////////////
#if ALLOW_SHOWING_OF_REGION_BORDERS
- (void)addRegionOverlay:(NSString *)regionName
{
    if (self.regionBorders)
    {
        [self.mapView removeOverlay:self.regionBorders];
        self.regionBorders = nil;
    }
    
    MKPolygon *polygon = [self polygonForRegion:regionName];
    self.regionBorders = polygon;
    [self.mapView addOverlay:polygon];
}
#endif

////////////////////////////////////////////////////////////////////////////////
/*
- (BOOL)locationCoordinate:(CLLocationCoordinate2D)location inRegion:(NSString *)regionName
{
    MKMapPoint mapPoint = MKMapPointForCoordinate(location);
    MKPolygonRenderer *polygonView = [[MKPolygonRenderer alloc] initWithPolygon:[self polygonForRegion:regionName]];
    CGPoint polygonViewPoint = [polygonView pointForMapPoint:mapPoint];
    return CGPathContainsPoint(polygonView.path, NULL, polygonViewPoint, NO);
}
*/

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - MapView delegate

- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView
{
    if (!self.mapInitialized)
    {
        self.mapInitialized = YES;
        
        if (self.visibleMapRegion)
        {
            [mapView setRegion:self.visibleMapRegion.mapRegion animated:NO];
        }
        else if (self.locationCoordinate.longitude == 0.0f && self.locationCoordinate.latitude == 0.0f)
        {
            // Zoom to the boundaries of Australia
            CLLocationCoordinate2D nw, se;//, ne, sw;
            nw = CLLocationCoordinate2DMake(-7.410849283839832,  112.41210912499992);
            //ne = CLLocationCoordinate2DMake(-7.410849283839832,  154.07226537499992);
            se = CLLocationCoordinate2DMake(-44.248667520681586, 154.07226537499992);
            //sw = CLLocationCoordinate2DMake(-44.248667520681586, 112.41210912499992);
            MKMapPoint topLeftCorner = MKMapPointForCoordinate(nw);
            MKMapPoint bottomRightCorner = MKMapPointForCoordinate(se);
            CGFloat width = bottomRightCorner.x - topLeftCorner.x;
            CGFloat height = bottomRightCorner.y - topLeftCorner.y;
            MKMapRect zoomRect = MKMapRectMake(topLeftCorner.x, topLeftCorner.y, width, height);
            [mapView setVisibleMapRect:zoomRect edgePadding:UIEdgeInsetsMake(20.0f, 20.0f, 20.0f, 20.0f) animated:NO];
            
            self.locationCoordinate = mapView.centerCoordinate;
        }
        else
            [self zoomInto:self.locationCoordinate distance:10000.0f animated:NO];
        
        [self dropThePin];
    }
}

////////////////////////////////////////////////////////////////////////////////
- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay
{
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
        MKPolygonView *polygonView = [[MKPolygonView alloc] initWithPolygon:overlay];
        
        polygonView.lineWidth = 2.0;
        polygonView.strokeColor = [UIColor IORedColor];
        polygonView.fillColor = [[UIColor IORedColor] colorWithAlphaComponent:0.4f];
        
        return polygonView;
    }
    
    return nil;
}

////////////////////////////////////////////////////////////////////////////////
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    // in case it's the user location, we already have an annotation, so just return nil
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    static NSString *annotationIdentifier = @"draggablePin";
#if USE_DEFAULT_PIN_VIEW
    MKPinAnnotationView *thePin = (MKPinAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
#else
    IOLocationVCAnnotationView *thePin = (IOLocationVCAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:annotationIdentifier];
#endif
    
    if (!thePin)
    {
#if USE_DEFAULT_PIN_VIEW
        thePin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationIdentifier];
        thePin.animatesDrop = YES;
#else
        thePin = [[IOLocationVCAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:annotationIdentifier];
        UIImage *pinImage = [UIImage imageNamed:@"marker-64"];
        CGFloat centerOffset = -5.0;
        thePin.centerOffset = CGPointMake(thePin.centerOffset.x + pinImage.size.width / 2 + centerOffset, thePin.centerOffset.y - pinImage.size.height / 2);
        thePin.image = pinImage;
#endif
        thePin.draggable = YES;
        thePin.canShowCallout = YES;
    }
    
    if ([annotation isKindOfClass:[IOLocationVCAnnotation class]])
    {
        IOLocationVCAnnotation *anAnnotation = (IOLocationVCAnnotation *)annotation;
        thePin.animatesDrop = anAnnotation.animatesDrop;
    }
    
    return thePin;
}

////////////////////////////////////////////////////////////////////////////////
#if !USE_DEFAULT_PIN_VIEW
- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    MKAnnotationView *thePin;
    for (thePin in views)
    {
        if ([thePin.annotation isKindOfClass:[MKUserLocation class]])
            continue;
        
        MKMapPoint point = MKMapPointForCoordinate(thePin.annotation.coordinate);
        if (!MKMapRectContainsPoint(self.mapView.visibleMapRect, point))
            continue;
        
        CGRect endFrame = thePin.frame;
        CGRect startFrame = endFrame;
        startFrame.origin.y -= 230;
        
        thePin.frame = startFrame;
        
        IOLocationVCAnnotationView *annotationView = (IOLocationVCAnnotationView *)thePin;
        if (annotationView.animatesDrop)
        {
            [UIView animateWithDuration:kPinDropAnimationDuration
                                  delay:0.04 * [views indexOfObject:thePin]
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 thePin.frame = endFrame;
                             } completion:^(BOOL finished){
                                 [UIView animateWithDuration:0.1 animations:^{
                                     thePin.transform = CGAffineTransformMake(1.0, 0, 0, 0.8, 0, + thePin.frame.size.height * 0.1);
                                 } completion:^(BOOL finished){
                                     [UIView animateWithDuration:0.1 animations:^{
                                         thePin.transform = CGAffineTransformIdentity;
                                     }];
                                 }];
                             }];
        }
        else
             thePin.frame = endFrame;
    }
}

////////////////////////////////////////////////////////////////////////////////
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)thePin didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState
{
    if ([thePin.annotation isKindOfClass:[MKUserLocation class]])
        return;
    
    switch ((NSUInteger)newState) {
        case MKAnnotationViewDragStateStarting:
        {
            CGRect endFrame = thePin.frame;
            endFrame.origin.y -= kPinPtOffsetWhenDragging;
            
            CGRect midFrame = endFrame;
            midFrame.origin.y -= 5;
            [UIView animateWithDuration:0.2
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 thePin.frame = midFrame;
                             } completion:^(BOOL finished){
                                 [UIView animateWithDuration:0.1
                                                       delay:0.0
                                                     options:UIViewAnimationOptionCurveEaseIn
                                                  animations:^{
                                                      thePin.frame = endFrame;
                                                  } completion:^(BOOL finished) {
                                                      [thePin setDragState:MKAnnotationViewDragStateDragging];
                                                  }];
                             }];
        } break;
            
        case MKAnnotationViewDragStateEnding:
        case MKAnnotationViewDragStateCanceling:
        {
            CGRect endFrame = thePin.frame;
            
            if (newState == MKAnnotationViewDragStateCanceling)
                endFrame.origin.y += kPinPtOffsetWhenDragging;
            
            CGRect midFrame = endFrame;
            midFrame.origin.y -= kPinPtOffsetWhenDragging;
            
            [UIView animateWithDuration:0.2
                                  delay:0.0
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 thePin.frame = midFrame;
                             } completion:^(BOOL finished){
                                 [UIView animateWithDuration:0.2
                                                       delay:0.0
                                                     options:UIViewAnimationOptionCurveEaseIn
                                                  animations:^{
                                                      thePin.frame = endFrame;
                                                  } completion:^(BOOL finished) {
                                                      [UIView animateWithDuration:0.1 animations:^{
                                                          thePin.transform = CGAffineTransformMake(1.0, 0, 0, 0.8, 0, + thePin.frame.size.height * 0.1);
                                                      } completion:^(BOOL finished){
                                                          [UIView animateWithDuration:0.1 animations:^{
                                                              thePin.transform = CGAffineTransformIdentity;
                                                              [thePin setDragState:MKAnnotationViewDragStateNone];
                                                          }];
                                                      }];
                                                  }];
                             }];
             
            self.locationCoordinate = thePin.annotation.coordinate;
        } break;
    }
}
#endif

////////////////////////////////////////////////////////////////////////////////
- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    [self moveThePinToCoordinate:userLocation.coordinate];
    self.locationAccuracyInMetres = MAX(userLocation.location.horizontalAccuracy, userLocation.location.verticalAccuracy);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - IBActions

- (IBAction)setAccuracyLevel:(id)sender {
    UISegmentedControl *control = (UISegmentedControl *)sender;
    NSString *title = [control titleForSegmentAtIndex:control.selectedSegmentIndex];
    
    CGFloat metres = [[self.levelsInMetres objectForKey:title] floatValue];
    self.locationAccuracyInMetres = metres;
}

////////////////////////////////////////////////////////////////////////////////
- (void)refreshLocationButtonClicked:(id)sender
{
    if (!self.mapView.showsUserLocation)
    {
        self.mapView.showsUserLocation = YES;
        [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    }
    else
    {
        self.mapView.showsUserLocation = NO;
        self.mapView.userTrackingMode = MKUserTrackingModeNone;
    }
}

////////////////////////////////////////////////////////////////////////////////
- (IBAction)showCornerView:(id)sender
{
    if (self.mapView.showsUserLocation)
        [self refreshLocationButtonClicked:nil];
    
    IOMapSettingsViewController *hiddenVC = [self.storyboard instantiateViewControllerWithIdentifier:@"MapSettingsSBID"];
    hiddenVC.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    hiddenVC.delegate = self;
#if ALLOW_SHOWING_OF_REGION_BORDERS
    if (self.regionName)
    {
        hiddenVC.showRegionBorderSwitch = YES;
        hiddenVC.regionBorderSwithchIsOn = self.showingRegionBorders;
    }
#endif
    hiddenVC.mapType = self.mapView.mapType;
    
    [self presentViewController:hiddenVC animated:YES completion:nil];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - IOMapSettingsDelegate Protocol

- (void)mapTypeChangedTo:(MKMapType)mapType
{
    self.mapView.mapType = mapType;
}

////////////////////////////////////////////////////////////////////////////////
#if ALLOW_SHOWING_OF_REGION_BORDERS
- (void)showRegionBorders:(BOOL)showOrHide
{
    self.showingRegionBorders = showOrHide;
}
#endif

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"ReturnMapInput"])
    {
        IOMapRegionObject *mapRegionObject = [[IOMapRegionObject alloc] init];
        mapRegionObject.mapRegion = self.mapView.region;
        
        [self.delegate acceptedSelection:@{
                  kIOLocationLatitudeKey: @(self.locationCoordinate.latitude),
                 kIOLocationLongitudeKey: @(self.locationCoordinate.longitude),
                  kIOLocationAccuracyKey: @(self.locationAccuracyInMetres),
                     @"visibleMapRegion": mapRegionObject,
         }];
    }
    else if ([[segue identifier] isEqualToString:@"CancelInput"] && [self.delegate respondsToSelector:@selector(cancelled)])
        [self.delegate cancelled];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Gestures

- (void)handleLongPress:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        CGPoint longPressPoint = [recognizer locationInView:self.view];
        CLLocationCoordinate2D longPressPointCoordinate = [self.mapView convertPoint:longPressPoint toCoordinateFromView:self.view];
        self.locationCoordinate = longPressPointCoordinate;
        [self dropThePin];
    }
}

@end
