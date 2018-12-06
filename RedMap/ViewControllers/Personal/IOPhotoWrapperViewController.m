//
//  IOPhotoWrapperViewController.m
//  RedMap
//
//  Created by Evo Stamatov on 28/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOPhotoWrapperViewController.h"
#import "IOPhotoPageViewController.h"
#import "Sighting.h"
#import "AppDelegate.h"
#import "Species.h"
#import <QuartzCore/QuartzCore.h>
#import "UIColor+IOColor.h"
#import <MapKit/MapKit.h>
#import "IOPhotoCollection.h"
#import "IOCoreDataHelper.h"

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

#define IOPhotoWrapperViewControllerAutoHideOverlay 0

#if IOPhotoWrapperViewControllerAutoHideOverlay
#   define kInitialHideTimeInterval 1.0
#   define kHideTimeInterval 5.0
#endif

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface IOPhotoWrapperViewController () <UIGestureRecognizerDelegate>
{
    NSTimer *_hideTimer;
}

@property (nonatomic, strong) IOPhotoPageViewController *photoPageViewController;
@property (nonatomic, strong) Sighting *sighting;
@property (nonatomic, assign) BOOL overlayHidden;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation IOPhotoWrapperViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        logmethod();
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
- (void)viewDidLoad
{
    logmethod();
    [super viewDidLoad];
    
#if TRACK
    [GoogleAnalytics sendEventWithCategory:@"checkpoint" withAction:@"viewDidLoad" withLabel:@"IOPhotoWrapperViewController" withValue:@1];
#endif
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRecognized:)];
    tapGesture.delegate = self;
    [self.view addGestureRecognizer:tapGesture];
    
    // Disable the title, because it is a button btw
    //self.toolbarTitle.title = nil;
    
    // Load the Sighting
    if (self.sightingUUID)
    {
        self.sighting = [self fetchSightingByUUID:self.sightingUUID];
        
        if (self.sighting)
            [self updateSightingData];
        
        self.photoPageViewController = (IOPhotoPageViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"PhotoControllerSBID"];
        self.photoPageViewController.sightingUUID = self.sightingUUID;
        
        CGRect frame = self.photoPageViewController.view.frame;
        frame.origin = CGPointZero;
        self.photoPageViewController.view.frame = frame;
        
        [self addChildViewController:self.photoPageViewController];
        [self.view insertSubview:self.photoPageViewController.view atIndex:0];
        
        /*
        if (![self.sighting.published boolValue])
            [self removeSharingButtonFromToobarAnimated:NO];
         */
        
        self.validatedOverlay.hidden = [self.sighting.validSighting boolValue];
    }
    /*
    else
        [self removeSharingButtonFromToobarAnimated:NO];
     */
    
#if IOPhotoWrapperViewControllerAutoHideOverlay
    [self setupHideTimerAfterTimeInterval:kInitialHideTimeInterval];
#endif
}

////////////////////////////////////////////////////////////////////////////////
- (void)didReceiveMemoryWarning
{
    logmethod();
    [super didReceiveMemoryWarning];
}

////////////////////////////////////////////////////////////////////////////////
#if TRACK
- (void)viewWillAppear:(BOOL)animated
{
    logmethod();
    [super viewWillAppear:animated];
    
    [GoogleAnalytics sendView:@"Personal - Photo browser"];
}
#endif

////////////////////////////////////////////////////////////////////////////////
- (void)setSightingUUID:(NSString *)sightingUUID
{
    logmethod();
    _sightingUUID = [sightingUUID copy];
    
    if (self.photoPageViewController)
        self.photoPageViewController.sightingUUID = _sightingUUID;
}

////////////////////////////////////////////////////////////////////////////////
- (void)setOverlayHidden:(BOOL)overlayHidden
{
    logmethod();
    if (_overlayHidden != overlayHidden)
    {
#if IOPhotoWrapperViewControllerAutoHideOverlay
        if (!overlayHidden)
            [self setupHideTimerAfterTimeInterval:kHideTimeInterval];
        else if (_hideTimer != nil)
            [_hideTimer invalidate];
#endif
        
        _overlayHidden = overlayHidden;
        
        [self.navigationController setNavigationBarHidden:overlayHidden animated:YES];
        
        __weak IOPhotoWrapperViewController *weakSelf = self;
        [UIView animateWithDuration:.25 animations:^{
            weakSelf.bottomConstraint.constant = overlayHidden ? weakSelf.view.frame.size.height : 0;
            //weakSelf.overlayToolbar.alpha = [[NSNumber numberWithBool:!_overlayHidden] floatValue];
            [weakSelf.view layoutIfNeeded];
        }];
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Gesture Recognizers

- (void)tapRecognized:(UIGestureRecognizer *)recognizer
{
    logmethod();
    self.overlayHidden = !self.overlayHidden;
}

////////////////////////////////////////////////////////////////////////////////
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    logmethod();
    //if (touch.view == self.overlayToolbar || touch.view.superview == self.overlayToolbar)
    //    return NO;
    
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Custom methods

#if IOPhotoWrapperViewControllerAutoHideOverlay
- (void)setupHideTimerAfterTimeInterval:(NSTimeInterval)interval
{
    if (_hideTimer != nil)
        [_hideTimer invalidate];
    
    _hideTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                  target:self
                                                selector:@selector(hideTheOverlay)
                                                userInfo:nil
                                                 repeats:NO];
}
#endif

////////////////////////////////////////////////////////////////////////////////
- (void)hideTheOverlay
{
    logmethod();
    self.overlayHidden = YES;
}

////////////////////////////////////////////////////////////////////////////////
- (Sighting *)fetchSightingByUUID:(NSString *)uuid
{
    logmethod();
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSManagedObjectContext *context = [[IOCoreDataHelper sharedInstance] context];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Sighting" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    [fetchRequest setFetchBatchSize:20];
    
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(uuid == %@)", uuid]];
    
    NSError *error = nil;
    NSArray *listOfSightings = [context executeFetchRequest:fetchRequest error:&error];
    
    if (listOfSightings.count > 0)
        return (Sighting *)[listOfSightings lastObject];
    
    return nil;
}

////////////////////////////////////////////////////////////////////////////////
- (void)updateSightingData
{
    logmethod();
    Species *species = self.sighting.species;
    if (species != nil)
    {
        self.titleLabel.text = species.commonName;
        self.subTitleLabel.text = species.speciesName;
    }
    else if ([self.sighting.otherSpecies boolValue])
    {
        self.titleLabel.text = self.sighting.otherSpeciesCommonName;
        self.subTitleLabel.text = self.sighting.otherSpeciesName;
    }
    else
    {
        self.titleLabel.text = @"Error";
        self.subTitleLabel.text = nil;
    }
    
    self.spottedOnLabel.text = [NSDateFormatter localizedStringFromDate:self.sighting.dateSpotted
                                                              dateStyle:NSDateFormatterShortStyle
                                                              timeStyle:NSDateFormatterShortStyle];
    
    CLLocationCoordinate2D sightingLocation = CLLocationCoordinate2DMake([self.sighting.locationLat floatValue], [self.sighting.locationLng floatValue]);
    
    // Australia's map coordinates
    CLLocationCoordinate2D nw, se;
    nw = CLLocationCoordinate2DMake(-7.410849283839832, 112.41210912499992);
    se = CLLocationCoordinate2DMake(-44.248667520681586, 154.07226537499992);
    
    MKMapPoint topLeftPoint = MKMapPointForCoordinate(nw);
    MKMapPoint bottomRightPoint = MKMapPointForCoordinate(se);
    MKMapRect mapRect = MKMapRectMake(topLeftPoint.x, topLeftPoint.y, bottomRightPoint.x - topLeftPoint.x, bottomRightPoint.y - topLeftPoint.y);
    MKMapPoint targetPoint = MKMapPointForCoordinate(sightingLocation);
    
    BOOL isInside = MKMapRectContainsPoint(mapRect, targetPoint);
    
    if (isInside)
    {
        double left = (targetPoint.x - topLeftPoint.x) / (bottomRightPoint.x - topLeftPoint.x);
        double top = (targetPoint.y - topLeftPoint.y) / (bottomRightPoint.y - topLeftPoint.y);
        
        CGFloat diameter = 10;
        CGFloat radius = diameter / 2;
        CGRect frame = CGRectMake(left * 100 - radius, top * 100 - radius, diameter, diameter);
        UIView *circle = [[UIView alloc] initWithFrame:frame];
        circle.alpha = 0.5;
        circle.layer.cornerRadius = radius;
        circle.backgroundColor = [UIColor IORedColor];
        
        [self.mapImageView addSubview:circle];
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - IB Actions

- (IBAction)shareButtonAction:(id)sender
{
    logmethod();
    if (!self.sighting || !self.sighting.published)
        return;
    
    __weak IOPhotoWrapperViewController *weakSelf = self;
    IOPhotoCollection *photos = [[IOPhotoCollection alloc] init];
    [photos reSetTheUUID:self.sighting.uuid retainingPhotos:YES withCallback:^(NSError *error) {
        NSMutableArray *dataToShare = [NSMutableArray arrayWithCapacity:3];
        
        if ([self.sighting.validSighting boolValue])
        {
            NSString *shareURL = [NSString stringWithFormat:@"%@sightings/%d/", REDMAP_URL, [self.sighting.sightingID intValue]];
            NSURL *url = [NSURL URLWithString:shareURL];
            [dataToShare addObject:url];
        }
        else
        {
            [dataToShare addObject:@"This sighting is not yet verified by a Redmap scientist."];
        }
        
        if (!error && photos.count > 0)
            [dataToShare addObject:[photos photoAtIndex:0]];
        
        if (dataToShare.count > 0)
        {
            UIActivityViewController* activityViewController =
            [[UIActivityViewController alloc] initWithActivityItems:dataToShare
                                              applicationActivities:nil];
            
            [weakSelf presentViewController:activityViewController animated:YES completion:nil];
        }
    }];
}

@end
