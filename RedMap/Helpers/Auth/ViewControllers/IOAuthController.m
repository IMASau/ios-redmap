//
//  IOAuthController.m
//  RedMap
//
//  Created by Evo Stamatov on 28/06/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOAuthController.h"
#import "IOAuth.h"
#import "IOAuthLoginViewController.h"

NSString *const IOAuthControllerDomain = @"IOAuthControllerDomain";
NSInteger const IOAuthControllerErrorCodeNoInternet = 106;

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

NSString *const kAuthControllerStoryboardID = @"AuthLoginSBID";


@interface IOAuthController () <IOAuthLoginViewControllerDelegate>
@end


@implementation IOAuthController

+ (IOAuthController *)authController
{
    logmethod();
    // load the storyboard view, not a blank one
    // NSString *storyboardName = iOS_7_OR_LATER() ? @"IOAuth" : @"IOAuth-ios6";
    NSString *storyboardName = @"IOAuth";
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:nil];
    return [storyboard instantiateViewControllerWithIdentifier:kAuthControllerStoryboardID];
}

- (void)dealloc
{
    logmethod();
    DDLogWarn(@"%@: Deallocating the auth view controller", self.class);
    _userData = nil;
}

- (void)viewDidLoad
{
    logmethod();
    DDLogVerbose(@"%@: Loading the auth view controller", self.class);
    IOAuthLoginViewController *vc = (IOAuthLoginViewController *)[self topViewController];
    vc.responseDelegate = self;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    logmethod();
    if (iOS_7_OR_LATER())
        return UIStatusBarStyleLightContent;
    else
        return UIStatusBarStyleDefault;
}

- (void)didReceiveMemoryWarning
{
    logmethod();
    DDLogError(@"%@: ERROR. Got a did recieve memory warning", self.class);
    [super didReceiveMemoryWarning];
}

- (void)authLoginViewControllerDidSucceed:(IOAuthLoginViewController *)authLoginViewController
{
    logmethod();
    [self.responseDelegate authControllerDidSucceed:self];
}

- (void)authLoginViewControllerDidFail:(IOAuthLoginViewController *)authLoginViewController error:(NSError *)error
{
    logmethod();
    if (error.code == 106) // no internet connection
    {
        NSString *message = NSLocalizedString(@"Cannot connect to the server, but the details will be re-tried once interent connection is available.", @"Shows when there is no internet connection but the user is allowed to continue");
        
        NSError *offlineError = [NSError errorWithDomain:IOAuthControllerDomain
                                                    code:IOAuthControllerErrorCodeNoInternet
                                                userInfo:@{ NSLocalizedDescriptionKey: message }];
        
        [self displayAlertForError:offlineError];
        [self.responseDelegate authControllerDidFail:self error:offlineError];
    }
    else
    {
        [[IOAuth sharedInstance] removeCurrentUser];
        
        [self displayAlertForError:error];
        [self.responseDelegate authControllerDidFail:self error:error];
    }
}

- (void)authLoginViewControllerDidCancel:(IOAuthLoginViewController *)authLoginViewController
{
    logmethod();
    if ([self.responseDelegate respondsToSelector:@selector(authControllerDidCancel:)])
        [self.responseDelegate authControllerDidCancel:self];
    else
        [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)displayAlertForError:(NSError *)error
{
    logmethod();
    DDLogVerbose(@"%@: Displaying error", self.class);
    
    NSString *errorTitle = NSLocalizedString(@"Oopsie", @"");
    NSString *dismissButtonTitle = NSLocalizedString(@"Dismiss", @"");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:errorTitle
                                                        message:error.localizedDescription
                                                       delegate:nil
                                              cancelButtonTitle:dismissButtonTitle
                                              otherButtonTitles:nil];
        [alert show];
    });
}

@end
