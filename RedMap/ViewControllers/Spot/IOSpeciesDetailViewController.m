//
//  SpeciesDetailViewController.m
//  RedMap
//
//  Created by Evo Stamatov on 27/03/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOSpeciesDetailViewController.h"
#import "AppDelegate.h"
#import <CoreLocation/CoreLocation.h>
#import "IOSpotKeys.h"
#import <GRMustache.h>
#import "Species.h"
#import "IOCategory.h"
#import "IOGRMustacheFilterNl2Br.h"

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

@interface SpeciesDetailViewController ()

@property (nonatomic) BOOL viewVisible;

@property (weak, nonatomic) IBOutlet UILabel *theTitle;
@property (weak, nonatomic) IBOutlet UILabel *subTitle;
@property (weak, nonatomic) IBOutlet UIImageView *picture;
@property (weak, nonatomic) IBOutlet UIWebView *desc;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *pictureActivityIndicator;
//@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIImageView *mapOverlay;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *descriptionHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *pictureHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mapOverlayTopSpaceConstraint;

- (IBAction)logASpeciesSighting:(id)sender;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end


@implementation SpeciesDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
#if TRACK
    [GoogleAnalytics sendEventWithCategory:@"checkpoint" withAction:@"viewDidLoad" withLabel:@"SpeciesDetailViewController" withValue:@1];
#endif
    
    self.theTitle.text = self.speciesDetails.commonName;
    self.subTitle.text = self.speciesDetails.speciesName;
    
    self.pictureActivityIndicator.hidesWhenStopped = YES;
    [self.pictureActivityIndicator startAnimating];
    
    [self loadThePicture];
    
    //self.mapView.delegate = self;
    [self loadTheDistributionOverlayAndMap];
    
    [self loadTheDescription];
    
    if (self.awokenFromLogging)
        self.navigationItem.rightBarButtonItem.title = @"Done";
}



- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.viewVisible = YES;
    
#if TRACK
    [GoogleAnalytics sendView:@"Species description"];
#endif
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}



#pragma mark - Custom methods

- (void)loadThePicture
{
    NSString *imageURL = self.speciesDetails.pictureUrl;
    if (imageURL && ![imageURL isEqualToString:@""])
    {
        NSDate *start = [NSDate date];
        [ApplicationDelegate.imageEngine loadImageFromURL:imageURL successBlock:^(UIImage *image) {
            NSTimeInterval timeInterval = fabs([start timeIntervalSinceNow]);
            [self.pictureActivityIndicator stopAnimating];
            self.picture.backgroundColor = [UIColor whiteColor];
            self.picture.image = image;
            if (timeInterval > 0.4)
            {
                self.picture.alpha = 0;
                __weak SpeciesDetailViewController *weakSelf = self;
                [UIView animateWithDuration:2 animations:^{
                    weakSelf.picture.alpha = 1;
                }];
            }
        } errorBlock:^(NSError *error, NSInteger statusCode) {
            [self.pictureActivityIndicator stopAnimating];
            DDLogError(@"%@: ERROR loading species image. StatusCode: %d. [%d]: %@", self.class, statusCode, error.code, error.localizedDescription);
        }];
    }
    else
    {
        self.pictureHeightConstraint.constant = 0.0f;
        self.picture.hidden = YES;
        [self.pictureActivityIndicator stopAnimating];
    }
}



- (void)loadTheDistributionOverlayAndMap
{
    NSString *imageURL = self.speciesDetails.distributionUrl;
    if (imageURL && ![imageURL isEqualToString:@""])
    {
        [ApplicationDelegate.imageEngine loadImageFromURL:imageURL successBlock:^(UIImage *image) {
            self.mapOverlay.backgroundColor = [UIColor clearColor];
            self.mapOverlay.image = image;
            self.mapOverlay.alpha = 0;
            __weak SpeciesDetailViewController *weakSelf = self;
            [UIView animateWithDuration:0.4 animations:^{
                weakSelf.mapOverlay.alpha = 1;
            }];
        } errorBlock:^(NSError *error, NSInteger statusCode) {
            DDLogError(@"%@: ERROR loading distribution overlay map image. StatusCode: %d. [%d]: %@", self.class, statusCode, error.code, error.localizedDescription);
        }];
    }
    else
    {
        self.mapOverlay.hidden = YES;
    }
    
    /*
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(?:&bbox=|%2C)([-\\d.E]+)"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    NSArray *matchesArray = [regex matchesInString:distributionOverlayURL
                                           options:0
                                             range:NSMakeRange(0, [distributionOverlayURL length])];
    NSMutableArray *bboxArray = [NSMutableArray array];
    [matchesArray enumerateObjectsUsingBlock:^(NSTextCheckingResult *result, NSUInteger idx, BOOL *stop) {
        for (int i=0; i<[result numberOfRanges];i++)
        {
            [bboxArray addObject:[distributionOverlayURL substringWithRange:[result rangeAtIndex:i]]];
        }
    }];
    //    IOLog(@"%@", bboxArray);
     */
}



- (void)loadTheDescription
{
    NSString *templateFilePath = [[NSBundle mainBundle] pathForResource:@"species_description_template" ofType:@"html"];
    
    NSError *fileReadError = nil;
    NSString *templateContent = [NSString stringWithContentsOfFile:templateFilePath
                                                            encoding:NSUTF8StringEncoding
                                                               error:&fileReadError];
    if (!fileReadError)
    {
        self.desc.delegate = self;

        NSString *rendering = [GRMustacheTemplate renderObject:@{
                               @"species": self.speciesDetails,
                               @"nl2br": [[IOGRMustacheFilterNl2Br alloc] init]
                               } fromString:templateContent error:NULL];
        [self.desc loadHTMLString:rendering baseURL:nil];
        
        [self.desc setBackgroundColor:[UIColor clearColor]];
        [self.desc setOpaque:NO];
    }
}



/*
- (void)loadMapWithOverlay
{
    //   N
    // W + E
    //   S
    CLLocationCoordinate2D NWPoint, SEPoint, NEPoint, SWPoint;
    SWPoint = [self convertToLatLongFromMetersX:1.237199884670033E7 andMetersY:-5516608.554242996];
    NEPoint = [self convertToLatLongFromMetersX:1.7218876832381703E7 andMetersY:-892319.0468662267];
    SEPoint = CLLocationCoordinate2DMake(SWPoint.latitude, NEPoint.longitude);
    NWPoint = CLLocationCoordinate2DMake(NEPoint.latitude, SWPoint.longitude);
//    IOLog(@"SW: %f, %f", SWPoint.latitude, SWPoint.longitude);
//    IOLog(@"NE: %f, %f", NEPoint.latitude, NEPoint.longitude);
//    IOLog(@"SE: %f, %f", SEPoint.latitude, SEPoint.longitude);
//    IOLog(@"NW: %f, %f", NWPoint.latitude, NWPoint.longitude);

    MKMapPoint upperLeft = MKMapPointForCoordinate(NWPoint);
    MKMapPoint lowerRight = MKMapPointForCoordinate(SEPoint);
    double width = lowerRight.x - upperLeft.x;
    double height = lowerRight.y - upperLeft.y;
//    IOLog(@"Width: %f, Height: %f", width, height);
    
    MKMapRect visibleMapRect = MKMapRectMake(upperLeft.x, upperLeft.y, width, height);
    [mapView setVisibleMapRect:visibleMapRect animated:NO];
    
//    [mapView setCenterCoordinate:SWPoint animated:YES];
}
 */


#pragma mark - Delegates
#pragma mark UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    UIScrollView *scrollView = (UIScrollView *)[self.view.subviews objectAtIndex:0];
    
    // reset the webview height to its maximum
    self.descriptionHeightConstraint.constant = 10.0f;
    [scrollView layoutIfNeeded];
    
    NSString *stringHeight = [webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('content').offsetHeight;"];
    CGFloat height = [stringHeight floatValue];
    
    //IOLog(@"Description height: %f", height);
    self.descriptionHeightConstraint.constant = height;
    
    NSString *stringMapOverlayTop = [webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('map-overlay-padder').offsetTop;"];
    CGFloat mapOverlayTopOffset = [stringMapOverlayTop floatValue];
    
    //IOLog(@"Map top offset: %f", mapOverlayTopOffset);
    self.mapOverlayTopSpaceConstraint.constant = mapOverlayTopOffset + 8.0f;
    
    // re-calc the constraints
    //IOLog(@"ScrollViewHeight: %f", scrollView.contentSize.height);
    [scrollView layoutIfNeeded];
    
    // disable scrolling of th webview
    self.desc.scrollView.scrollEnabled = NO;
    self.desc.scrollView.bounces = NO;
}



#pragma mark MKMapView delegate

/*
- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView
{
//    IOLog(@"Finished loading the map");
    [self loadMapWithOverlay];
}
 */



#pragma mark - Map Coords conversion

/*
// Converts XY point from Spherical Mercator EPSG:900913 (SRID=900913) to lat/lon in WGS 84 Datum (SRID=4326)
// Online tester: http://cs2cs.mygeodata.eu/
- (CLLocationCoordinate2D)convertToLatLongFromMetersX:(CGFloat)mx andMetersY:(CGFloat)my
{
    CGFloat originShift = 2 * M_PI * 6378137 / 2.0;
    CGFloat lon = (mx / originShift) * 180.0;
    CGFloat lat = (my / originShift) * 180.0;

    lat = 180 / M_PI * (2 * atan( exp( lat * M_PI / 180.0)) - M_PI / 2.0);
    
    return CLLocationCoordinate2DMake(lat, lon);
}
 */

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - IBActions

- (IBAction)logASpeciesSighting:(id)sender
{
#if TRACK
    [GoogleAnalytics sendEventWithCategory:@"uiAction" withAction:@"buttonPress" withLabel:@"logASighting" withValue:self.speciesDetails.id];
#endif
    
    [self.delegate speciesDetailViewController:self category:self.categoryDetails species:self.speciesDetails];
    [self unwindToLoggingRoot:sender];
}

////////////////////////////////////////////////////////////////////////////////
- (void)unwindToLoggingRoot:(id)sender
{
    // TODO: handle the unwind only if called by the Logging screen
    
    // Trigger for unwind seque programmatically
    SEL theUnwindSelector = @selector(goToLoggingRoot:);
    NSString *unwindSegueIdentifier = @"unwindToLoggingRoot";
    
    UINavigationController *nc = [self navigationController];
    
    // Find the view controller that has this unwindAction selector
    // (may not be one in the nav stack)
    UIViewController *viewControllerToCallUnwindSelectorOn = [nc viewControllerForUnwindSegueAction:theUnwindSelector fromViewController:self withSender:sender];
    
    if (viewControllerToCallUnwindSelectorOn)
    {
        // Can the controller that we found perform the unwind segue?
        // (This is decided by that controllers implementation of
        // canPerformSeque: method
        BOOL cps = [viewControllerToCallUnwindSelectorOn canPerformUnwindSegueAction:theUnwindSelector fromViewController:self withSender:sender];
        
        // If we have permision to perform the seque on the controller
        // where the unwindAction is implmented then get the segue
        // object and perform it.
        if (cps)
        {
            UIStoryboardSegue *unwindSegue = [nc segueForUnwindingToViewController:viewControllerToCallUnwindSelectorOn fromViewController:self identifier:unwindSegueIdentifier];
            
            [viewControllerToCallUnwindSelectorOn prepareForSegue:unwindSegue sender:self];
            [unwindSegue perform];

            [viewControllerToCallUnwindSelectorOn performSelector:@selector(goToLoggingRoot:) withObject:unwindSegue];
        }
    }
//    else
//        IOLog(@"No controller found to unwind too");
}

@end
