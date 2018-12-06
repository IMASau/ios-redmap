//
//  IOMainTabBarViewController.m
//  RedMap
//
//  Created by Evo Stamatov on 25/03/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOMainTabBarViewController.h"
#import "AppDelegate.h"
#import "IOLoggingViewController.h"
#import "Sighting.h"
#import "IORedMapThemeManager.h"
#import "IOSpotTableViewController.h"
#import "IOAuth.h"
#import "IOPersonalViewController.h"
#import "IOLoggingViewController.h"

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface IOMainTabBarViewController () <IOSpotTableViewControllerDelegate, IOLoggingViewControllerDelegate, UITabBarControllerDelegate, IOAuthControllerDelegate>

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation IOMainTabBarViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.delegate = self;
    
#if TRACK
    [GoogleAnalytics sendEventWithCategory:@"checkpoint" withAction:@"viewDidLoad" withLabel:@"IOMainTabBarViewController" withValue:@1];
#endif
    
    [IORedMapThemeManager styleTabBar:self.tabBar];
}

////////////////////////////////////////////////////////////////////////////////
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
#if TRACK
    [GoogleAnalytics sendView:@"Tab bar view"];
#endif
}

////////////////////////////////////////////////////////////////////////////////
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Overrides

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    [super setSelectedIndex:selectedIndex];

    if ([self.selectedViewController isKindOfClass:[UINavigationController class]])
    {
        UINavigationController *nc = (UINavigationController *)[self selectedViewController];
        [self setupTabsNavigationController:nc];
    }
}

- (void)setSelectedViewController:(UIViewController *)selectedViewController
{
    [super setSelectedViewController:selectedViewController];
    
    if ([selectedViewController isKindOfClass:[UINavigationController class]])
    {
        UINavigationController *nc = (UINavigationController *)selectedViewController;
        [self setupTabsNavigationController:nc];
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Custom methods

- (void)setupTabsNavigationController:(UINavigationController *)nc
{
    UIViewController *vc = (UIViewController *)[nc topViewController];
    
    if ([vc respondsToSelector:@selector(setHomeViewController:)])
        [vc setValue:self.homeViewController forKey:@"homeViewController"];
    
    if ([vc isKindOfClass:[IOSpotTableViewController class]])
    {
        IOSpotTableViewController *spotVC = (IOSpotTableViewController *)vc;
        spotVC.delegate = self;
    } else if  ([vc isKindOfClass:[IOLoggingViewController class]])
    {
        IOLoggingViewController *logVC = (IOLoggingViewController *)vc;
        logVC.delegate = self;
    }
}

////////////////////////////////////////////////////////////////////////////////
- (void)selectLogTabAndSetCategory:(IOCategory *)category andSpecies:(Species *)species
{
    [self setSelectedIndex:LOG_TAB_INDEX];
    //IOLog(@"Selected View Controoler: %@", [self selectedViewController]);
    
    UINavigationController *nc = (UINavigationController *)[self selectedViewController];
    IOLoggingViewController *vc = (IOLoggingViewController *)[nc topViewController];
    //IOLog(@"Logging View Controoler: %@", vc);
    
    [vc setCategory:category andSpecies:species];
}

////////////////////////////////////////////////////////////////////////////////
- (void)selectPersonalTabAndPlotASightingID:(NSManagedObjectID *)sightingID
{
    DDLogVerbose(@"%@: Selecting Personal Tab", self.class);
    
    [self setSelectedIndex:PERSONAL_TAB_INDEX];
    
#if DEBUG
    DDLogVerbose(@"%@: Selected view controller: %@", self.class, self.selectedViewController);
#endif
    
    UINavigationController *nc = (UINavigationController *)[self selectedViewController];
    IOPersonalViewController *vc = (IOPersonalViewController *)[nc topViewController];
    
#if DEBUG
    DDLogVerbose(@"%@: Personal View Controoler: %@", self.class, vc);
#endif
    
    vc.justPublishedSightingID = sightingID;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - IOSpotTableViewControllerDelegate Protocol

- (void)spotTableViewController:(UIViewController *)viewController category:(IOCategory *)category species:(Species *)species
{
    [self selectLogTabAndSetCategory:category andSpecies:species];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - IOTabBarProtocol

- (void)loggingViewController:(UIViewController *)viewController publishedSightingWithID:(NSManagedObjectID *)sightingID
{
    DDLogVerbose(@"%@: Logging view controller published sighting", self.class);
    
    [self selectPersonalTabAndPlotASightingID:sightingID];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - IOTabBarProtocol

- (void)popTheTopmostController
{
    [self.homeViewController goHome];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - UITabBarControllerDelegate Protocol

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    // Check if the selected viewController is the Personal Tab
    // And then if there is currently a logged in user, but still allow to switch to the tab if the user hasn't authenticated
    if ([viewController isKindOfClass:[IOPersonalViewController class]] && ![[IOAuth sharedInstance] hasCurrentUser])
    {
        IOAuthController *authVC = [IOAuthController authController];
        authVC.responseDelegate = self;
        authVC.userData = viewController;
        [self presentViewController:authVC animated:YES completion:NULL];
        return NO;
    }
    
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    if ([viewController isKindOfClass:[UINavigationController class]])
    {
        UINavigationController *nc = (UINavigationController *)viewController;
        [self setupTabsNavigationController:nc];
    }
}

////////////////////////////////////////////////////////////////////////////////
- (void)authControllerDidFail:(IOAuthController *)authController error:(NSError *)error
{
    DDLogError(@"%@: ERROR. Log-in failed", self.class);
    [self dismissViewControllerAnimated:YES completion:nil];
}

////////////////////////////////////////////////////////////////////////////////
- (void)authControllerDidSucceed:(IOAuthController *)authController
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    if (authController.userData == nil)
        DDLogError(@"%@: ERROR. Somehow I've lost hold on the view controller", self.class);
    else
    {
        DDLogVerbose(@"%@: Logged in", self.class);
        self.selectedViewController = (UIViewController *)authController.userData;
        authController.userData = nil;
    }
}

@end
