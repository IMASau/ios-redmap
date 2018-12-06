//
//  IONPersonalViewController.m
//  RedMap
//
//  Created by Evo Stamatov on 2/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOPersonalViewController.h"
#import "AppDelegate.h"
#import "IOAuth.h"
#import "IOPersonalFetchDelegate.h"
#import "IOPersonalViewControllerProtocol.h"
#import "Sighting-typedefs.h"
#import "Sighting.h"
#import "IOCoreDataHelper.h"
#import "IOPersonalMapViewController.h"

#define INITIALLY_SELECTED_TAB 0

NSString *const kIOPersonalViewControllerCacheName = @"Personal";

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

//static NSString *noSightingsVC = @"NoSightingsSBID";

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface IOPersonalViewController () <UIAlertViewDelegate, NSFetchedResultsControllerDelegate, IOAuthControllerDelegate>

- (IBAction)selectTab:(UISegmentedControl *)segment;
- (IBAction)goHome:(id)sender;

@property (weak, nonatomic) IBOutlet UISegmentedControl *navBarSegment;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSMutableDictionary *viewControllers;
@property (weak, nonatomic) UIViewController *topViewController;

@property (nonatomic, strong) NSManagedObjectContext *context;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation IOPersonalViewController
{
    BOOL _cancellingAuthController;
}

- (void)viewDidLoad
{
    logmethod();
    [super viewDidLoad];
    
#if TRACK
    [GoogleAnalytics sendEventWithCategory:@"checkpoint" withAction:@"viewDidLoad" withLabel:@"IOPersonalViewController" withValue:@1];
#endif
    
    self.navBarSegment.selectedSegmentIndex = INITIALLY_SELECTED_TAB;
    [self selectTabAtIndex:INITIALLY_SELECTED_TAB];
    
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removedUser) name:IOAuthRemoveUserNotification object:nil];
}

- (void)dealloc
{
    DDLogWarn(@"%@: Deallocating", self.class);
    
    //[[NSNotificationCenter defaultCenter] removeObserver:self];
    
    _fetchedResultsController = nil;
    _context = nil;
    _viewControllers = nil;
}

////////////////////////////////////////////////////////////////////////////////
- (void)didReceiveMemoryWarning
{
    logmethod();
    [super didReceiveMemoryWarning];
}

////////////////////////////////////////////////////////////////////////////////
- (void)viewWillAppear:(BOOL)animated
{
    logmethod();
    [super viewWillAppear:animated];
    
#if TRACK
    [GoogleAnalytics sendView:@"Personal view"];
#endif
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideNoSightingsView) name:@"plotASpeciesSighting" object:nil];
    
    //[[IOAuth sharedInstance] checkForNewSightings];
}

- (void)viewDidAppear:(BOOL)animated
{
    logmethod();
    [super viewDidAppear:animated];
    
    if (_cancellingAuthController)
        return;
    
    if (![[IOAuth sharedInstance] hasCurrentUser])
    {
        IOAuthController *authVC = [IOAuthController authController];
        authVC.responseDelegate = self;
        [self presentViewController:authVC animated:YES completion:NULL];
    }
    else
    {
        if (![[IOAuth sharedInstance] isCurrentUserAuthenticated])
        {
            __weak __typeof(self)weakSelf = self;
            [[IOAuth sharedInstance] reAuthenticateCurrentUserWithCompletionBlock:^(BOOL success, NSError *error) {
                if (success)
                {
                    DDLogInfo(@"%@: Successful reAuthentication", self.class);
                }
                else
                {
                    DDLogError(@"%@: Unsuccessful reAuthentication", self.class);
                    
                    if (error.code == 402) // wrong credentials
                    {
                        [weakSelf attemptReLogin];
                    }
                    else
                    {
                        DDLogError(@"%@: Silently failed attempt to reAuthenticate [%d]: %@", self.class, error.code, error.localizedDescription);
                    }
                }
            }];
        }
        else
        {
            // TODO: move the below code to a timer of some kind
            /*
            for (Sighting *sighting in [self.fetchedResultsController fetchedObjects])
            {
                IOSightingStatus status = [sighting.status intValue];
                if (status == IOSightingStatusSynced || status == IOSightingStatusSyncing)
                    continue;
                
                [[IOAuth sharedInstance] publishSighting:sighting];
                break; // publish only one at a time
            }
             */
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    logmethod();
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"plotASpeciesSighting" object:nil];
    
    [super viewDidDisappear:animated];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Getters and Setters
- (NSMutableDictionary *)viewControllers
{
    logmethod();
    if (_viewControllers == nil)
        _viewControllers = [NSMutableDictionary dictionary];
    return _viewControllers;
}

////////////////////////////////////////////////////////////////////////////////
- (NSManagedObjectContext *)context
{
    logmethod();
    if (_context == nil)
        _context = [[IOCoreDataHelper sharedInstance] context];
    return _context;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - IBActions

- (IBAction)selectTab:(UISegmentedControl *)segment
{
    logmethod();
    [self selectTabAtIndex:[segment selectedSegmentIndex]];
}

////////////////////////////////////////////////////////////////////////////////
- (IBAction)goHome:(id)sender
{
    logmethod();
    [self.homeViewController goHome];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Custom methods

- (void)selectTabAtIndex:(NSUInteger)index
{
    logmethod();
    static NSArray *tabsNames;
    if (tabsNames == nil)
    {
        tabsNames = @[
                      @"PersonalMapSBID",
                      @"PersonalPhotosSBID",
                      ];
    }
    
    NSString *storyboardVCIdentifier = [tabsNames objectAtIndex:index];
    [self setCurrentViewControllerByIdentifier:storyboardVCIdentifier];
}

////////////////////////////////////////////////////////////////////////////////
- (void)setCurrentViewControllerByIdentifier:(NSString *)identifier
{
    logmethod();
    UIViewController *vc = [self.viewControllers objectForKey:identifier];
    if (vc == nil)
    {
        vc = [self.storyboard instantiateViewControllerWithIdentifier:identifier];
        [self.viewControllers setObject:vc forKey:identifier];
        
        [vc willMoveToParentViewController:self];
        [self addChildViewController:vc];
        [self.view addSubview:vc.view];
#warning CHECK does vc.view resize correctly if self.view.bounds change?
        [vc didMoveToParentViewController:self];
        
        vc.view.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addConstraints:
         [NSLayoutConstraint
          constraintsWithVisualFormat:@"|[vc]|"
          options:0 metrics:nil views:@{@"vc":vc.view}]];
        [self.view addConstraints:
         [NSLayoutConstraint
          constraintsWithVisualFormat:@"V:|[vc]|"
          options:0 metrics:nil views:@{@"vc":vc.view}]];
        
        if ([vc conformsToProtocol:@protocol(IOPersonalFetchDelegate)])
            [(id <IOPersonalFetchDelegate>)vc setFetchedResultsController:self.fetchedResultsController];
    }
    else
    {
        [self.view bringSubviewToFront:vc.view];
        
        if ([vc respondsToSelector:@selector(viewDidBecomeTopmost)])
            [(id <IOPersonalViewControllerProtocol>)vc viewDidBecomeTopmost];
    }
    
    self.topViewController = vc;
    
    if ([vc isKindOfClass:[IOPersonalMapViewController class]] && self.justPublishedSightingID)
    {
        IOPersonalMapViewController *mvc = (IOPersonalMapViewController *)vc;
        mvc.context = self.context;
        mvc.justPublishedSightingID = self.justPublishedSightingID;
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    logmethod();
    static BOOL fetchError = NO;
    
    if (_fetchedResultsController != nil)
        return _fetchedResultsController;
    
    if (fetchError)
        return nil;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:kIOSightingEntityName inManagedObjectContext:self.context];
    [fetchRequest setEntity:entity];
    
    [fetchRequest setFetchBatchSize:20];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:kIOSightingPropertyDateSpotted ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // kIOSightingPropertyStatus should not be Draft
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(status > %i)", IOSightingStatusDraft]];
    
    NSFetchedResultsController *aFetchedResultsController;
    aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                    managedObjectContext:self.context
                                                                      sectionNameKeyPath:nil
                                                                               cacheName:nil]; //kIOPersonalViewControllerCacheName];
    aFetchedResultsController.delegate = self;
    _fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![_fetchedResultsController performFetch:&error])
    {
	    DDLogError(@"%@: ERROR fetching sightings. [%d]: %@. UserInfo: %@", self.class, error.code, error.localizedDescription, error.userInfo);
        
        fetchError = YES;
        return nil;
	}
    
    return _fetchedResultsController;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSFetchedResultsControllerDelegate Protocol

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    logmethod();
    DDLogVerbose(@"%@: Fetch results will change", self.class);
    UIViewController *vc = self.topViewController;
    if ([vc respondsToSelector:@selector(fetchedResultsWillChange)])
        [(id <IOPersonalFetchDelegate>)vc fetchedResultsWillChange];
}

////////////////////////////////////////////////////////////////////////////////
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    logmethod();
    DDLogVerbose(@"%@: Fetch results did change", self.class);
    UIViewController *vc = self.topViewController;
    if ([vc respondsToSelector:@selector(fetchedResultsDidChange)])
        [(id <IOPersonalFetchDelegate>)vc fetchedResultsDidChange];
}

////////////////////////////////////////////////////////////////////////////////
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    logmethod();
    UIViewController *vc = self.topViewController;
    if (!vc)
        return;
    
    switch (type) {
        case NSFetchedResultsChangeInsert:
        {
            DDLogVerbose(@"%@: Fetch results insertion", self.class);
            if ([vc respondsToSelector:@selector(fetchedResultsInsertedObject:newIndexPath:)])
                [(id <IOPersonalFetchDelegate>)vc fetchedResultsInsertedObject:anObject newIndexPath:newIndexPath];
        }
            break;
            
        case NSFetchedResultsChangeDelete:
        {
            DDLogVerbose(@"%@: Fetch results deletion", self.class);
            if ([vc respondsToSelector:@selector(fetchedResultsDeletedObject:atIndexPath:)])
                [(id <IOPersonalFetchDelegate>)vc fetchedResultsDeletedObject:anObject atIndexPath:indexPath];
        }
            break;
            
        case NSFetchedResultsChangeUpdate:
        {
            DDLogVerbose(@"%@: Fetch results update", self.class);
            if ([vc respondsToSelector:@selector(fetchedResultsUpdateObject:atIndexPath:)])
                [(id <IOPersonalFetchDelegate>)vc fetchedResultsUpdateObject:anObject atIndexPath:indexPath];
        }
            break;
            
        case NSFetchedResultsChangeMove:
        {
            DDLogVerbose(@"%@: Fetch results move", self.class);
            if ([vc respondsToSelector:@selector(fetchedResultsMovedObject:fromIndexPath:toIndexPath:)])
                [(id <IOPersonalFetchDelegate>)vc fetchedResultsMovedObject:anObject fromIndexPath:indexPath toIndexPath:newIndexPath];
        }
            break;
    }
}

////////////////////////////////////////////////////////////////////////////////
- (void)authControllerDidSucceed:(IOAuthController *)authController
{
    logmethod();
    DDLogVerbose(@"%@: Login succeeded", self.class);
    [self dismissViewControllerAnimated:YES completion:nil];
}

////////////////////////////////////////////////////////////////////////////////
- (void)authControllerDidCancel:(IOAuthController *)authController
{
    logmethod();
    DDLogVerbose(@"%@: Login was cancelled", self.class);
    _cancellingAuthController = YES;
    
    [self dismissViewControllerAnimated:YES completion:^{
        _cancellingAuthController = NO;
    }];
}

////////////////////////////////////////////////////////////////////////////////
- (void)authControllerDidFail:(IOAuthController *)authController error:(NSError *)error
{
    logmethod();
    DDLogVerbose(@"%@: Login failed", self.class);
    [self dismissViewControllerAnimated:YES completion:nil];
}

////////////////////////////////////////////////////////////////////////////////
- (void)attemptReLogin
{
    logmethod();
    DDLogVerbose(@"%@: Attempt re-login", self.class);
    NSString *message = NSLocalizedString(@"The saved credentials didn't succeed in logging you in. Would you like to login again?", @"");
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oopsie"
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"No"
                                          otherButtonTitles:@"Yes", nil];
    [alert show];
}

////////////////////////////////////////////////////////////////////////////////
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    logmethod();
    if (buttonIndex != alertView.cancelButtonIndex)
    {
        IOAuthController *authVC = [IOAuthController authController];
        //authVC.userData = @"reauth";
        authVC.responseDelegate = self;
        [self presentViewController:authVC animated:YES completion:NULL];
    }
    else
    {
        NSString *message = NSLocalizedString(@"You will stay with the unverified account, but all your sightings will stay local.", @"");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oopsie"
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"Dismiss"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

/*
////////////////////////////////////////////////////////////////////////////////
- (void)removeUser:(NSNotification *)n
{
    [NSFetchedResultsController deleteCacheWithName:kIOPersonalViewControllerCacheName];
}
 */

@end