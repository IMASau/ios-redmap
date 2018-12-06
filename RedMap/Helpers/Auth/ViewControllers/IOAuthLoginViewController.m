//
//  IOAuthLoginViewController.m
//  RedMap
//
//  Created by Evo Stamatov on 23/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

@class User;                                                                    // no need to import the class, since we are not using any of it, but just to pass some objects

#import "IOAuthLoginViewController.h"
#import "IOAuth.h"                                                              // provides access to currentUser and methods to login/create users
#import "AppDelegate.h"                                                         // allows access to the managedObjectContext
#import "Reachability.h"                                                        // monitors the internet status
#import "IOAuthCreateAccountViewController.h"                                   // shows the create account view
#import "IOOfflineViewController.h"                                             // shows the offline view
#import <CoreText/CoreText.h>                                                   // used for the "facebook" font
#import "IORedMapThemeManager.h"                                                // styles the navigationBar and buttons
#import "IOAlertView.h"

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

@interface IOAuthLoginViewController () <UITextFieldDelegate, IOAuthCreateAccountViewControllerDelegate>

@property (nonatomic) BOOL inProgress;
@property (nonatomic) BOOL success;

@property (weak, nonatomic) IBOutlet UITextField *userName;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UIButton *signInWithFacebookButton;
@property (weak, nonatomic) IBOutlet UIButton *createAccountButton;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;

- (IBAction)signIn:(id)sender;
- (IBAction)signInWithFacebook:(id)sender;
- (IBAction)cancelLogin:(id)sender;

@end


@implementation IOAuthLoginViewController
{
    UITextField *_currentTextField;
    BOOL _doneWithFBButton;
}

- (void)dealloc
{
    logmethod();
    [[IOOfflineViewController sharedController] detachAnimated:NO];
}

- (void)viewDidLoad
{
    logmethod();
    [super viewDidLoad];
    
    DDLogVerbose(@"%@: View did load", self.class);
    
    _currentTextField = nil;
    self.userName.delegate = self;
    self.password.delegate = self;
    
    self.createAccountButton.backgroundColor = [UIColor clearColor];
    self.loginButton.backgroundColor = [UIColor clearColor];
    self.signInWithFacebookButton.backgroundColor = [UIColor clearColor];
    
    [IORedMapThemeManager styleNormalButton:self.createAccountButton];
    [IORedMapThemeManager styleSpecialButton:self.loginButton];
}



- (void)didReceiveMemoryWarning
{
    logmethod();
    DDLogVerbose(@"%@: Did recieve memory warning", self.class);
    
    [super didReceiveMemoryWarning];
}



- (void)viewWillAppear:(BOOL)animated
{
    logmethod();
    [super viewWillAppear:animated];
    
    DDLogVerbose(@"%@: View will appear", self.class);
    
    if (!RMAPI.isReachable)
        [self addNoteThereIsNoConnection];
    else
        [self removeNoteThereIsNoConnection];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
}



- (void)viewDidLayoutSubviews
{
    logmethod();
    [super viewDidLayoutSubviews];
    
    if (self.signInWithFacebookButton)
    {
        __weak UIButton *fbButton = self.signInWithFacebookButton;
        if (!_doneWithFBButton)
        {
            _doneWithFBButton = YES;
            DDLogVerbose(@"%@: Update Facebook button", self.class);
            
            UIColor *facebookBackgroundColor = [UIColor colorWithRed:0x3b / 255.0 green:0x59 / 255.0 blue:0x97 / 255.0 alpha:1.0];
            
            // fix for iOS7, since the text colour is rendered black
            NSString *titleLabel = @"Sign in with facebook";
            NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:titleLabel];
            NSRange range = [titleLabel rangeOfString:@"facebook"];
            UIFont *font = [UIFont fontWithName:@"SocialFont" size:17.0f];
            
            [string setAttributes:@{
                                    (NSString *)kCTFontAttributeName:font,
                                    (NSString *)kCTLigatureAttributeName:[NSNumber numberWithInt:2],
                                    }
                            range:range];
            
            [string addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, string.length)];
            [fbButton setAttributedTitle:string forState:UIControlStateNormal];
            
            //[IORedMapThemeManager styleSpecialButton:self.signInWithFacebookButton];
            [IORedMapThemeManager styleButton:fbButton withCustomColor:facebookBackgroundColor];
        };
    }
}



- (void)viewDidAppear:(BOOL)animated
{
    logmethod();
    [super viewDidAppear:animated];
    
    DDLogVerbose(@"%@: View did appear", self.class);
    
    [self.userName becomeFirstResponder];
}



- (void)viewWillDisappear:(BOOL)animated
{
    logmethod();
    DDLogVerbose(@"%@: View will disappear", self.class);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    [super viewWillDisappear:animated];
}



#pragma mark - Reachability notification

- (void)reachabilityChanged:(NSNotification *)note
{
    logmethod();
    Reachability *r = (Reachability *)[note object];
    
    DDLogInfo(@"%@: Reachability changed: %@", self.class, [r currentReachabilityString]);
    
    if ([r currentReachabilityStatus] == NotReachable)
        [self addNoteThereIsNoConnection];
    else
        [self removeNoteThereIsNoConnection];
}





#pragma mark - UITextField delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    logmethod();
    DDLogVerbose(@"%@: Textfield did begin editing", self.class);
    _currentTextField = textField;
}



- (void)textFieldDidEndEditing:(UITextField *)textField
{
    logmethod();
    DDLogVerbose(@"%@: Textfield did end editing", self.class);
    _currentTextField = nil;
}



- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    logmethod();
    DDLogVerbose(@"%@: Textfield should return", self.class);
    
    if (textField == self.userName)
        [self.password becomeFirstResponder];
    else
        [self signIn:textField];
    
    return YES;
}



- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    logmethod();
    // NOTE: no need to log
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    static NSString *emptyString = @"";
    
    if ([newString isEqualToString:emptyString])
    {
        DDLogVerbose(@"%@: Empty string is OK", self.class);
        return YES;
    }

    NSError *usernameError = nil;
    if (textField == self.userName && ![IOAuth validateUsername:newString andSkipMinumunLengthCheck:YES error:&usernameError])
    {
        DDLogError(@"%@: ERROR. Unsupported content. [%d]: %@", self.class, [usernameError code], [usernameError localizedDescription]);
        return NO;
    }
    
    // TODO: validate password for unicode characters and other unallowed ones
    
    return YES;
}



#pragma mark - IB Actions

- (IBAction)signIn:(id)sender
{
    logmethod();
    DDLogInfo(@"%@: Sign in", self.class);
    // TODO: show an indicator
    
    NSError *error = nil;
    IOAuthValidation validationResult = [self validateFields:&error];
    if (error)
    {
        DDLogError(@"%@: ERROR validating. [%d]: %@", self.class, error.code, error.localizedDescription);
        [self displayAlertForError:error];
    }
    else
    {
        if ((validationResult & IOAuthValidationUsernameAndPasswordOK) != 0)
            [self attemptLogin];
        else
        {
            NSError *error = [NSError errorWithDomain:@"signInError" code:1 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Unknown sign-in error. Please, try again later.", @"Unknown validation error when attempting to sign in")}];
            DDLogError(@"%@: ERROR with validation while signing in. [%d]: %@", self.class, error.code, error.localizedDescription);
            [self displayAlertForError:error];
        }
        
    }
}



- (IBAction)signInWithFacebook:(id)sender
{
    logmethod();
    DDLogInfo(@"%@: Sign in with Facebook", self.class);
    // TODO: show an indicator
    [self attemptLoginWithFacebook];
}

- (IBAction)cancelLogin:(id)sender
{
    logmethod();
    [self handleCancel];
}



#pragma mark - Custom methods
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



#pragma mark Validations

- (IOAuthValidation)validateFields:(NSError *__autoreleasing *)error
{
    logmethod();
    DDLogVerbose(@"%@: Validating fields", self.class);
    
    int result = IOAuthValidationFailed;
    
    NSError *usernameError = nil;
    BOOL validUsername = [IOAuth validateUsername:self.userName.text andSkipMinumunLengthCheck:NO error:&usernameError];
    if (!validUsername)
        result |= IOAuthValidationUsernameFail;
    else
        result |= IOAuthValidationUsernameOK;
    
    NSError *passwordError = nil;
    BOOL validPassword = [IOAuth validatePassword:self.password.text error:&passwordError];
    if (!validPassword)
        result |= IOAuthValidationPasswordFail;
    else
        result |= IOAuthValidationPasswordOK;
    
    if (!validUsername && !validPassword)
        result |= IOAuthValidationUsernameAndPasswordFail;
    else
        result |= IOAuthValidationUsernameAndPasswordOK;
    
    if (!validUsername && !validPassword && error != NULL)
        *error = [NSError errorWithDomain:@"validateFields" code:1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%@ %@", [usernameError localizedDescription], [passwordError localizedDescription]]}];
    else if (!validUsername && error != NULL)
        *error = usernameError;
    else if (!validPassword && error != NULL)
        *error = passwordError;
    
    return result;
}



#pragma mark Login

- (void)attemptLogin
{
    logmethod();
    DDLogInfo(@"%@: Attempt login", self.class);
    
    [_userName resignFirstResponder];
    [_password resignFirstResponder];
    
    NSString *username = self.userName.text;
    NSString *password = self.password.text;
    
    self.inProgress = YES;
    __weak __typeof(self)weakSelf = self;
    
    IOAlertView *loading = [IOAlertView alertViewWithSpinnerAndTitle:@"Logging in"];
    [loading show];
    
    [[IOAuth sharedInstance] loginUserWithUsername:username password:password completionBlock:^(BOOL success, NSError *error) {
        [loading dismissAnimated:!success];
        
        weakSelf.inProgress = NO;
        
        if (success)
        {
            DDLogInfo(@"%@: Login Success", weakSelf.class);
            [weakSelf handleSuccessfulLogin];
        }
        else
        {
            DDLogError(@"%@: ERROR with user login. [%d]: %@", weakSelf.class, error.code, error.localizedDescription);
            [weakSelf handleUnsuccessfulLogin:error];
        }
    }];
}


#pragma mark - Handle cancel/success/failure
- (void)handleCancel
{
    logmethod();
    DDLogInfo(@"%@: Handle cancelled login", self.class);
    
    [self.responseDelegate authLoginViewControllerDidCancel:self];
}

- (void)handleSuccessfulLogin
{
    logmethod();
    DDLogVerbose(@"%@: Handle successful login/registration", self.class);
    
    [self.responseDelegate authLoginViewControllerDidSucceed:self];
}

- (void)handleUnsuccessfulLogin:(NSError *)error
{
    logmethod();
    DDLogVerbose(@"%@: Handle unsuccessful login/registration", self.class);
    
    if ([error.domain isEqualToString:RMAPIErrorDomain])
    {
        NSString *description;
        switch (error.code) {
            case RMAPIErrorCodeFacebookEmailNotVerified:
                description = NSLocalizedString(@"Your Facebook email address has not been verified with Facebook. Please do so and retry.", @"When a user tries to log-in with unverified Facebook account");
                break;
                
            case RMAPIErrorCodeFacebookSessionExpired:
                description = NSLocalizedString(@"Your Facebook session has expired. Please re-try.", @"When a user logs through Facebook, but then the access token has expired");
                break;
                
            default:
                description = NSLocalizedString(@"We are experiencing some technical difficulties at the moment. Please, try again later", @"Server Registration fails");
                break;
        }
    }
    
    [self.responseDelegate authLoginViewControllerDidFail:self error:error];
}



#pragma mark Facebook login

- (void)attemptLoginWithFacebook
{
    logmethod();
    DDLogVerbose(@"%@: Attempt login with Facebook", self.class);
    
    [_userName resignFirstResponder];
    [_password resignFirstResponder];
    
    self.inProgress = YES;
    __weak __typeof(self)weakSelf = self;
    
    IOAlertView *loading = [IOAlertView alertViewWithSpinnerAndTitle:@"Logging in with Facebook"];
    [loading show];
    
    [[IOAuth sharedInstance] registerUserFromFacebookWithCompletionBlock:^(BOOL success, NSError *error) {
        [loading dismissAnimated:!success];
        
        weakSelf.inProgress = NO;
        
        if (success)
        {
            DDLogInfo(@"%@: Facebook login Success", weakSelf.class);
            [weakSelf handleSuccessfulLogin];
        }
        else
        {
            DDLogError(@"%@: ERROR. Facebook login. [%d]: %@", weakSelf.class, error.code, error.localizedDescription);
            [weakSelf handleUnsuccessfulLogin:error];
        }
    }];
}



#pragma mark Connection notifications

- (void)addNoteThereIsNoConnection
{
    logmethod();
    DDLogVerbose(@"%@: Add note there is no connection", self.class);
    
    //self.navigationItem.prompt = @"Unable to connect to our server";
    
    [[IOOfflineViewController sharedController] attachToTableView:self.tableView animated:YES];
    
    UIButton *fbButton = self.signInWithFacebookButton;
    fbButton.enabled = NO;
}



- (void)removeNoteThereIsNoConnection
{
    logmethod();
    DDLogVerbose(@"%@: Remove note there is no connection", self.class);
    
    //self.navigationItem.prompt = nil;
    
    [[IOOfflineViewController sharedController] detachAnimated:YES];
    
    __block UIButton *fbButton = self.signInWithFacebookButton;
    fbButton.enabled = YES;
}



#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    logmethod();
    DDLogVerbose(@"%@: Prepare for segue", self.class);
    
    if ([segue.destinationViewController isKindOfClass:[IOAuthCreateAccountViewController class]])
    {
        [_userName resignFirstResponder];
        [_password resignFirstResponder];
        
        IOAuthCreateAccountViewController *vc = (IOAuthCreateAccountViewController *)segue.destinationViewController;
        vc.responseDelegate = self;
        vc.presetLoginUsername = self.userName.text;
        vc.presetLoginPassword = self.password.text;
    }
}

#pragma mark - UITableViewDelegate
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    logmethod();
    // NOTE: no need to log
    
    if (indexPath.row == 0)
        [_userName becomeFirstResponder];
    else if (indexPath.row == 1)
        [_password becomeFirstResponder];
    
    return nil;
}

- (void)authCreateAccountViewControllerDidFail:(IOAuthCreateAccountViewController *)authCreateAccountViewController error:(NSError *)error
{
    logmethod();
    [self handleUnsuccessfulLogin:error];
}

- (void)authCreateAccountViewControllerDidSucceed:(IOAuthCreateAccountViewController *)authCreateAccountViewController
{
    logmethod();
    [self handleSuccessfulLogin];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    logmethod();
    [_userName resignFirstResponder];
    [_password resignFirstResponder];
}

@end