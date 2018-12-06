//
//  IOHomeTableViewController.m
//  RedMap
//
//  Created by Evo Stamatov on 26/03/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOHomeTableViewController.h"
#import "AppDefines.h"
#import "IOMainTabBarViewController.h"
#import "IOAuth.h"
#import "User.h"
#import "IORedMapThemeManager.h"
#import <QuartzCore/QuartzCore.h>
#import "IOLogger.h"
#import "IOAlertView.h"

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

static NSString * const SpotCellSegue = @"SpotCellSegue";
static NSString * const LogCellSegue = @"LogCellSegue";
static NSString * const PersonalCellSegue = @"PersonalCellSegue";

////////////////////////////////////////////////////////////////////////////////
@interface IOHomeTableViewController () <UIAlertViewDelegate, IOAuthControllerDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *visitRedMapWebsiteButton;
@property (strong, nonatomic) IBOutlet UIView *loginBar;
@property (strong, nonatomic) IBOutlet UIButton *loginOrLogoutButton;

@property (strong, nonatomic) IBOutlet UITableViewCell *spotCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *logCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *mapCell;
@property (strong, nonatomic) IBOutlet UIImageView *lockImageView;
@property (strong, nonatomic) IBOutlet UITableViewCell *helpCell;

@end

////////////////////////////////////////////////////////////////////////////////
@implementation IOHomeTableViewController
{
    NSIndexPath *_howAreYouHelping;
    
    // iOS7
    UIAlertView *_genericAlertView;
    UIAlertView *_logoutAlertView;
    //UIAlertView *_unsuccessfulAuthenticationAlertView;
    
    BOOL _showSendLogsButton;
    BOOL _isVisible;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    DDLogWarn(@"%@: Deallocating", self.class);
}

////////////////////////////////////////////////////////////////////////////////
- (void)viewDidLoad
{
    [super viewDidLoad];
    
#if TRACK
    [GoogleAnalytics sendEventWithCategory:@"checkpoint" withAction:@"viewDidLoad" withLabel:@"IOHomeTableViewController" withValue:@1];
#endif
    
    
    // Style the table view
    [IORedMapThemeManager styleTableView:self.tableView as:IOTableViewStylePlain];
    
    
    // Set some important table view indexes
    _howAreYouHelping = [NSIndexPath indexPathForRow:3 inSection:0];
    
    
    // Page refresh control
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to refresh all remote data"];
    [refreshControl addTarget:self action:@selector(updateRemoteData:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    
    
    // Update remote data
    __weak __typeof(self)weakSelf = self;
    [[IOAuth sharedInstance] updateRemoteData:^(BOOL success, NSError *error) {
        //IOLog(@"%@ remote data", success ? @"Updated" : @"Failed to update");
        [weakSelf updateRefreshControlMessage:weakSelf.refreshControl showingError:(error != nil)];
    } forcedFetch:NO];
    
    NSDictionary *attributes = @{
                                 NSFontAttributeName: [UIFont systemFontOfSize:13.f],
                                 NSForegroundColorAttributeName: [UIColor whiteColor]
                                 };
    [self.visitRedMapWebsiteButton setTitleTextAttributes:attributes forState:UIControlStateNormal];
    
    UIEdgeInsets tableViewInsets = UIEdgeInsetsMake(0, 0, 78.f, 0); // adjust bottom to accommodate the login bar
    self.tableView.contentInset = tableViewInsets;
    
    self.lockImageView.hidden = [[IOAuth sharedInstance] hasCurrentUser];
    
    [self checkLogging];

    [self.tableView addSubview:self.loginBar];
    
#if DEBUG_FUN
    IOAlertView *loading = [IOAlertView alertViewWithProgressBarAndTitle:@"Loading remote data..."];
    [loading setProgress:0.0f animated:NO];
    [loading show];
    
    NSTimer *timer = [NSTimer timerWithTimeInterval:0.25f target:self selector:@selector(tick:) userInfo:loading repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
#endif
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat ph = CGRectGetHeight(scrollView.frame);

    CGFloat w = CGRectGetWidth(scrollView.frame);
    CGFloat h = CGRectGetHeight(self.loginBar.frame);
    CGFloat x = 0.0;
    CGFloat y = scrollView.contentOffset.y + ph - h;
    
    self.loginBar.frame = CGRectMake(x, y, w, h);
}

- (void)viewDidLayoutSubviews
{
    [self.tableView bringSubviewToFront:self.loginBar];

    [super viewDidLayoutSubviews];
}

#if DEBUG_FUN
- (void)tick:(NSTimer *)timer
{
    static float progress = 0.f;
    IOAlertView *loading = (IOAlertView *)timer.userInfo;
    progress += 0.1f;
    [loading setProgress:progress animated:YES];
    if (progress >= 1.0f)
    {
        [loading dismissAnimated:YES];
        [timer invalidate];
    }
}
#endif

- (IBAction)loginOrLogout:(id)sender
{
    if ([[IOAuth sharedInstance] hasCurrentUser])
    {
        _logoutAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure you want to logout?", @"")
                                                      message:nil
                                                     delegate:self
                                            cancelButtonTitle:NSLocalizedString(@"No", @"")
                                            otherButtonTitles:NSLocalizedString(@"Yes", @""), nil];
        [_logoutAlertView show];
    }
    else
        [self loginAndReLogin];
}

- (void)loginAndReLogin
{
    if (![[IOAuth sharedInstance] hasCurrentUser])
    {
        IOAuthController *authVC = [IOAuthController authController];
        authVC.userData = @"button";
        authVC.responseDelegate = self;
        [self presentViewController:authVC animated:YES completion:NULL];
    }
    /*
    else
    {
        if (![[IOAuth sharedInstance] isCurrentUserAuthenticated])
        {
            __weak __typeof(self)weakSelf = self;
            [[IOAuth sharedInstance] reAuthenticateCurrentUserWithCompletionBlock:^(BOOL success, NSError *error) {
                [weakSelf updateLoginStatus];
                if (success)
                {
                    DDLogInfo(@"%@: Successful reAuthentication", self.class);
                }
                else
                {
                    DDLogError(@"%@: Unsuccessful reAuthentication", self.class);
                    
                    if (error.code == 402) // wrong credentials
                    {
                        NSString *message = @"The saved credentials didn't succeed in logging you in. Would you like to try logging in again?";
                        dispatch_async(dispatch_get_main_queue(), ^{
                            _unsuccessfulAuthenticationAlertView = [[UIAlertView alloc] initWithTitle:@"Oopsie"
                                                                                              message:message
                                                                                             delegate:weakSelf
                                                                                    cancelButtonTitle:@"No"
                                                                                    otherButtonTitles:@"Yes", nil];
                            [_unsuccessfulAuthenticationAlertView show];
                        });
                    }
                    else
                    {
                        DDLogError(@"%@: Silently failed attempt to reAuthenticate [%d]: %@", self.class, error.code, error.localizedDescription);
                    }
                }
            }];
        }
    }
     */
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    /*
    if (alertView == _unsuccessfulAuthenticationAlertView)
    {
        if (buttonIndex != alertView.cancelButtonIndex) // Re-login
            [self loginAndReLogin];
        else
        {
            _genericAlertView = [[UIAlertView alloc] initWithTitle:@"Oopsie"
                                                            message:@"You will stay with the unverified account, but all your sightings will stay local."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [_genericAlertView show];
        }
        _unsuccessfulAuthenticationAlertView.delegate = nil;
        _unsuccessfulAuthenticationAlertView = nil;
    }
    else 
     */
    if (alertView == _logoutAlertView)
    {
        if (buttonIndex != alertView.cancelButtonIndex) // Log out
            [self logoutCurrentUser];
        
        _logoutAlertView.delegate = nil;
        _logoutAlertView = nil;
    }
}

- (void)logoutCurrentUser
{
    DDLogInfo(@"%@: Logging out the user", self.class);
    
    [[IOAuth sharedInstance] removeCurrentUser];
    
    DDLogInfo(@"%@: Logged out the user", self.class);
    
    [self updateLoginStatus];
}

- (void)updateLoginStatus
{
#if TRACK
    [GoogleAnalytics sendEventWithCategory:@"uiAction" withAction:@"buttonPress" withLabel:@"loginOrLogoutButton" withValue:@([[IOAuth sharedInstance] hasCurrentUser])];
#endif
    
    BOOL hasCurrentUser = [[IOAuth sharedInstance] hasCurrentUser];
    if (hasCurrentUser)
    {
        NSString *logOutText = NSLocalizedString(@"Log out", @"Log out button title");
        [self.loginOrLogoutButton setTitle:logOutText forState:UIControlStateNormal];
    }
    else
    {
        NSString *logInText = NSLocalizedString(@"Log in or create an account", @"Log in button title");
        [self.loginOrLogoutButton setTitle:logInText forState:UIControlStateNormal];
    }
    
    self.lockImageView.hidden = hasCurrentUser;
}

- (void)checkLogging
{
    DDLogVerbose(@"%@: Checking logging", self.class);
    
    if (!_isVisible)
    {
        DDLogVerbose(@"%@: View is not visible - skipping", self.class);
        return;
    }
    
    BOOL shouldReloadTableViewData = NO;
    BOOL loggingEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:kIOUserDefaultsLoggingEnabledKey];
    if (!loggingEnabled && [[IOLogger sharedInstance] hasLogs])
    {
        if (_showSendLogsButton == NO)
            shouldReloadTableViewData = YES;
        _showSendLogsButton = YES;
    }
    else
    {
        if (_showSendLogsButton == YES)
            shouldReloadTableViewData = YES;
        _showSendLogsButton = NO;
    }
    
    if (shouldReloadTableViewData)
    {
        if (_showSendLogsButton)
        {
            DDLogVerbose(@"%@: Adding Send service logs button", self.class);
            UIView *sendLogsView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320.f, 60.f)];
            
            UIButton *sendLogsButton = [UIButton buttonWithType:UIButtonTypeCustom];
            sendLogsButton.frame = CGRectMake(20.f, 8.f, 320.f - 40.f, 44.f);
            [sendLogsButton setTitle:@"Send service logs" forState:UIControlStateNormal];
            [IORedMapThemeManager styleButton:sendLogsButton asButtonType:IOButtonTypeSpecial withBaseColor:nil];
            [sendLogsButton addTarget:self action:@selector(sendServiceLogs) forControlEvents:UIControlEventTouchUpInside];
            
            [sendLogsView addSubview:sendLogsButton];
            self.tableView.tableFooterView = sendLogsView;
            //self.tableView.contentSize = CGSizeMake(320, 477);
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkLogging) name:IOLoggerDidRemoveErrorLogsNotification object:nil];
        }
        else
        {
            DDLogVerbose(@"%@: Removing Send service logs button", self.class);
            self.tableView.tableFooterView = nil;
            
            [[NSNotificationCenter defaultCenter] removeObserver:self name:IOLoggerDidRemoveErrorLogsNotification object:nil];
        }
    }
}

- (void)sendServiceLogs
{
    DDLogVerbose(@"%@: Send service logs", self.class);
    [[IOLogger sharedInstance] emailAndRemoveLogFilesIfNeededFromViewController:self];
}

////////////////////////////////////////////////////////////////////////////////
- (void)didReceiveMemoryWarning
{
    DDLogVerbose(@"%@: Did receive memory warning", self.class);
    [super didReceiveMemoryWarning];
}

////////////////////////////////////////////////////////////////////////////////
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    DDLogVerbose(@"%@: View will appear", self.class);
    
#if TRACK
    [GoogleAnalytics sendView:@"Home screen"];
#endif
    
    _isVisible = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self checkLogging];
    
    DDLogVerbose(@"%@: View did appear", self.class);
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    DDLogVerbose(@"%@: View did disappear", self.class);
    _isVisible = NO;
}

- (void)applicationWillEnterForeground
{
    DDLogVerbose(@"%@: Application will enter foreground", self.class);
    
    [self checkLogging];
}

- (void)applicationDidEnterBackground
{
    DDLogVerbose(@"%@: Application did enter background", self.class);
    
    if (_logoutAlertView)
    {
        [_logoutAlertView dismissWithClickedButtonIndex:_logoutAlertView.cancelButtonIndex animated:NO];
        _logoutAlertView.delegate = nil;
        _logoutAlertView = nil;
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - IOHomeTableViewControllerProtocol

- (void)goHome
{
    [self.navigationController popViewControllerAnimated:YES];
    
    DDLogVerbose(@"%@: Go home", self.class);
    //[self checkLogging];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Segues

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    // Check if there is currently a logged in user, but still - allow if the user is not authenticated
    if ([identifier isEqualToString:PersonalCellSegue] && ![[IOAuth sharedInstance] hasCurrentUser])
    {
        IOAuthController *authVC = [IOAuthController authController];
        authVC.userData = @"segue";
        authVC.responseDelegate = self;
        [self presentViewController:authVC animated:YES completion:NULL];
        return NO;
    }
    
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    DDLogVerbose(@"%@: Prepare for segue", self.class);
    
    // If loading the MainTabBarVC, then change its tab, automatically, based on the selected cell in the current VC
    if ([[segue destinationViewController] isKindOfClass:[IOMainTabBarViewController class]]) {
        NSUInteger index = 0;
        if ([segue.identifier isEqualToString:SpotCellSegue])
            index = SPOT_TAB_INDEX;
        else if ([segue.identifier isEqualToString:LogCellSegue])
            index = LOG_TAB_INDEX;
        else if ([segue.identifier isEqualToString:PersonalCellSegue])
            index = PERSONAL_TAB_INDEX;
        
        IOMainTabBarViewController *vc = (IOMainTabBarViewController *)[segue destinationViewController];
        vc.homeViewController = self; // allow the tabBar to pop the topmost view controller, eg. itself
        [vc setSelectedIndex:index];
        
        self.hideNavBarWhenDisappearing = YES;
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark Unwind segue

- (IBAction)goToHome:(UIStoryboardSegue *)segue
{
    DDLogVerbose(@"%@: goToHome unwind segue", self.class);
#warning TODO: adjust login status?
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - IB actions

- (IBAction)openRedMapWebsiteInExternalBrowser:(id)sender
{
#if TRACK
    [GoogleAnalytics sendEventWithCategory:@"uiAction" withAction:@"buttonPress" withLabel:@"openRedmapWebsite" withValue:@1];
#endif
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:REDMAP_URL]];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Unwind segues

- (IBAction)done:(UIStoryboardSegue *)segue
{
    DDLogVerbose(@"%@: done unwind segue", self.class);
    [self dismissViewControllerAnimated:YES completion:NULL];
}

////////////////////////////////////////////////////////////////////////////////
- (IBAction)cancel:(UIStoryboardSegue *)segue
{
    DDLogVerbose(@"%@: cancel unwind segue", self.class);
    [self dismissViewControllerAnimated:YES completion:NULL];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - TableView delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Style the cell
    [IORedMapThemeManager styleTableViewCell:cell atIndexPath:indexPath as:IOTableViewStylePlain];
    
    // Set the font for How You Are Helping cell
    if (cell == self.helpCell)
    {
        UILabel *label = (UILabel *)[cell viewWithTag:1];
        label.font = [IORedMapThemeManager scribblyFont];
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIRefreshConrol action

- (void)updateRemoteData:(UIRefreshControl *)refreshControl
{
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"Refreshing remote data..."];

    __weak __typeof(self)weakSelf = self;
    [[IOAuth sharedInstance] updateRemoteData:^(BOOL success, NSError *error) {
        DDLogInfo(@"%@: %@ remote data", self.class, success ? @"Updated" : @"Failed to update");
        
        [weakSelf updateRefreshControlMessage:refreshControl showingError:(error != nil)];
        [refreshControl endRefreshing];
        
        if (!success)
        {
            _genericAlertView = [[UIAlertView alloc] initWithTitle:@"Ooopsie"
                                                           message:error.localizedDescription
                                                          delegate:nil
                                                 cancelButtonTitle:@"Dismiss"
                                                 otherButtonTitles:nil];
            [_genericAlertView show];
        }
    } forcedFetch:YES];
}

////////////////////////////////////////////////////////////////////////////////
- (void)updateRefreshControlMessage:(UIRefreshControl *)refreshControl showingError:(BOOL)showingError
{
    NSString *updateLabel;
    if (showingError)
        updateLabel = NSLocalizedString(@"Last updated on %@ with an error", @"When refreshing all remote data with an error");
    else
        updateLabel = NSLocalizedString(@"Last updated on %@", @"When refreshing all remote data");
    
    NSString *localizedDate = [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle];
    NSString *lastUpdated = [NSString stringWithFormat:updateLabel, localizedDate];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:lastUpdated];
}

#pragma mark - IOAuthControllerDelegate
- (void)authControllerDidSucceed:(IOAuthController *)authController
{
    NSString *userData = [authController.userData copy];
    authController.userData = nil;
    authController.responseDelegate = nil;
    
    [self updateLoginStatus];
    
    __weak __typeof(self)weakSelf = self;
    [self dismissViewControllerAnimated:YES completion:^{
        if ([userData isEqualToString:@"segue"])
            [weakSelf performSegueWithIdentifier:PersonalCellSegue sender:weakSelf.mapCell];
    }];
}

- (void)authControllerDidFail:(IOAuthController *)authController error:(NSError *)error
{
    NSString *userData = [authController.userData copy];
    authController.userData = nil;
    authController.responseDelegate = nil;
    
    [self updateLoginStatus];
    
    if ([error.domain isEqualToString:IOAuthControllerDomain]) // no internet connection
    {
        __weak __typeof(self)weakSelf = self;
        [self dismissViewControllerAnimated:YES completion:^{
            if ([userData isEqualToString:@"segue"])
                [weakSelf performSegueWithIdentifier:PersonalCellSegue sender:weakSelf.mapCell];
        }];
    }
}

@end
