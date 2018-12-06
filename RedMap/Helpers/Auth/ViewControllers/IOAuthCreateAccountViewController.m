//
//  IOAuthCreateAccountViewController.m
//  RedMap
//
//  Created by Evo Stamatov on 23/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOAuthCreateAccountViewController.h"
#import "IOCommonListingTVC.h"
#import "AppDelegate.h"
#import "IOOfflineViewController.h"
#import "UIColor+IOColor.h"
#import "IOAuthLoginViewController.h"
#import "IOAuth.h"
#import "IOSightingAttributesController.h"
#import "IOBaseCellController.h"
#import "IORegionCellController.h"
#import "Sighting-typedefs.h"
#import "Region.h"
#import "IOCoreDataHelper.h"
#import "IOAlertView.h"

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

#define kCellTitleLabelTag 100


@interface IOAuthCreateAccountViewController () <UITextFieldDelegate, IOBaseCellControllerDelegate>

@property (nonatomic) BOOL inProgress;
@property (nonatomic) BOOL success;

@property (nonatomic, strong) NSMutableDictionary *highlightStore;

@property (strong, nonatomic) IBOutlet UIView *keyboardCandidateBar;

@property (weak, nonatomic) IBOutlet UITextField *userName;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UITextField *firstName;
@property (weak, nonatomic) IBOutlet UITextField *lastName;
@property (weak, nonatomic) IBOutlet UITextField *eMail;
@property (weak, nonatomic) IBOutlet UISwitch *joinMailingListSwitch;

@property (weak, nonatomic) IBOutlet UISegmentedControl *prevNextSegment;
- (IBAction)prevNextSegmentSelected:(UISegmentedControl *)sender;

- (IBAction)createTheAccount:(id)sender;

@property (nonatomic, strong) IORegionCellController *regionCellController;
@property (nonatomic, strong) Region *region;

@end


@implementation IOAuthCreateAccountViewController
{
    UITextField *_currentTextField;
    NSUInteger _currentTextFieldTag;
    BOOL _keyboardWillShow;
    BOOL _keyboardWillHide;
    BOOL _keyboardIsVisible;
    BOOL _viewDidLoad;
    NSIndexPath *_usernameIndexPath, *_passwordIndexPath, *_emailIndexPath, *_regionIndexPath;
}

- (void)dealloc
{
    logmethod();
    [[IOOfflineViewController sharedController] detachAnimated:NO];
}

- (void)viewDidLoad
{
    logmethod();
    DDLogVerbose(@"%@: View did load", self.class);
    
    [super viewDidLoad];
    
    _currentTextField = nil;
    self.userName.delegate = self;
    self.password.delegate = self;
    self.firstName.delegate = self;
    self.lastName.delegate = self;
    self.eMail.delegate = self;
    
    self.highlightStore = [NSMutableDictionary dictionary];
    _usernameIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    _passwordIndexPath = [NSIndexPath indexPathForRow:1 inSection:0];
    _emailIndexPath = [NSIndexPath indexPathForRow:2 inSection:1];
    _regionIndexPath = [NSIndexPath indexPathForRow:4 inSection:1];
    
    _viewDidLoad = YES;
    
    NSDictionary *settings = @{
                               kIOLVCManagedObjectKey: kIOSightingPropertyRegion,
                               kIOLVCPlistDataSource: kIOSightingCategoryRegion,
                               };
    
    self.regionCellController = [[IORegionCellController alloc] initWithSettings:settings delegate:self managedObjectContext:[[IOCoreDataHelper sharedInstance] context]];
}



- (void)didReceiveMemoryWarning
{
    logmethod();
    DDLogVerbose(@"%@: Did receive memory warning", self.class);
    [super didReceiveMemoryWarning];
}



- (void)viewWillAppear:(BOOL)animated
{
    logmethod();
    DDLogVerbose(@"%@: View will appear", self.class);
    
    [super viewWillAppear:animated];
    
    if (!iOS_7_OR_LATER())
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:)        name:UIKeyboardWillShowNotification        object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:)        name:UIKeyboardWillHideNotification        object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    }
    
    if (!RMAPI.isReachable)
        [self addNoteThereIsNoConnection];
    else
        [self removeNoteThereIsNoConnection];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:)     name:kReachabilityChangedNotification      object:nil];
    
    if (self.presetLoginUsername)
    {
        self.userName.text = self.presetLoginUsername;
        self.presetLoginUsername = nil;
    }
    
    if (self.presetLoginPassword)
    {
        self.password.text = self.presetLoginPassword;
        self.presetLoginPassword = nil;
    }
}



- (void)viewDidAppear:(BOOL)animated
{
    logmethod();
    DDLogVerbose(@"%@: View did appear", self.class);
    
    [super viewDidAppear:animated];
    
    if (_viewDidLoad)
    {
        _viewDidLoad = NO;
        
        if (self.password.text.length > 0)
            [self.password becomeFirstResponder];
        else
            [self.userName becomeFirstResponder];
    }
}



- (void)viewWillDisappear:(BOOL)animated
{
    logmethod();
    [_currentTextField resignFirstResponder];
    
    [super viewWillDisappear:animated];
}


- (void)viewDidDisappear:(BOOL)animated
{
    logmethod();
    DDLogVerbose(@"%@: View did disappear", self.class);
    
    if (!iOS_7_OR_LATER())
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification        object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification        object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification      object:nil];
    
    [super viewDidDisappear:animated];
}



#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    logmethod();
    [self updateTextColorForCellAtIndexPath:indexPath highlight:[self isCellAtIndexPathHighlighted:indexPath]];
    
    // Target the region cell
    if (indexPath.section == _regionIndexPath.section && indexPath.row == _regionIndexPath.row)
    {
        IOBaseCell *aCell = (IOBaseCell *)cell;
        [self.regionCellController configureTableViewCell:aCell];
    }
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    logmethod();
    // Target the region cell
    if (indexPath.section == _regionIndexPath.section && indexPath.row == _regionIndexPath.row)
    {
        IOBaseCell *cell = (IOBaseCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
        [self.regionCellController didSelectTableViewCell:cell];
        
        DDLogVerbose(@"%@: Showing the regions listing", self.class);
        
        // Manually create the segue, since we don't have an actual storyboard segue
        // It all boils down to calling [prepareForSegue:sender] on the cell controller
        IOCommonListingTVC *vc = [self.presentingViewController.storyboard instantiateViewControllerWithIdentifier:@"commonListingSBID"];
        UIStoryboardSegue *segue = [[UIStoryboardSegue alloc] initWithIdentifier:@"doesntmatter" source:self destination:vc];
        [self.regionCellController prepareForSegue:segue sender:cell];
        
        [self.navigationController pushViewController:vc animated:YES];
    }
}



#pragma mark - Keyboard notifications

- (void)adjustCandidateBarToKeyboard:(NSDictionary *)info animated:(BOOL)animated
{
    logmethod();
    CGRect beginFrame = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect endFrame = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    UIViewAnimationCurve curve = [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    
    if (_keyboardWillShow)
    {
        self.keyboardCandidateBar.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"uitoolbar-background"]];
        [self.tableView.superview addSubview:self.keyboardCandidateBar];
        _keyboardWillShow = NO;
        _keyboardIsVisible = YES;
    }
    
    BOOL isLandscape = UIInterfaceOrientationIsLandscape(self.view.window.rootViewController.interfaceOrientation);
    
    CGRect beginFrameLocal = [self.tableView convertRect:beginFrame fromView:nil];
    CGRect candidateBarBeginFrame = self.keyboardCandidateBar.frame;
    candidateBarBeginFrame.size.width = self.tableView.frame.size.width;
    candidateBarBeginFrame.size.height = isLandscape ? 36.0 : 44.0;
    candidateBarBeginFrame.origin.x = beginFrameLocal.origin.x;
    candidateBarBeginFrame.origin.y = beginFrameLocal.origin.y - candidateBarBeginFrame.size.height;
    self.keyboardCandidateBar.frame = candidateBarBeginFrame;
    
    CGRect endFrameLocal = [self.tableView convertRect:endFrame fromView:nil];
    CGRect candidateBarEndFrame = self.keyboardCandidateBar.frame;
    candidateBarEndFrame.origin.x = endFrameLocal.origin.x;
    candidateBarEndFrame.origin.y = endFrameLocal.origin.y - candidateBarEndFrame.size.height;
    candidateBarEndFrame.size.width = self.tableView.frame.size.width;
    candidateBarEndFrame.size.height = isLandscape ? 36.0 : 44.0;
    
    /*
    // WIP: Constraints - Nightmare !!!
     
    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.keyboardCandidateBar.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSLayoutConstraint *leftCns = [NSLayoutConstraint constraintWithItem:self.keyboardCandidateBar attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0.0];
    NSLayoutConstraint *rightCns = [NSLayoutConstraint constraintWithItem:self.keyboardCandidateBar attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0.0];
    NSLayoutConstraint *bottomCns = [NSLayoutConstraint constraintWithItem:self.keyboardCandidateBar attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    NSLayoutConstraint *heightCns = [NSLayoutConstraint constraintWithItem:self.keyboardCandidateBar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.keyboardCandidateBar attribute:NSLayoutAttributeHeight multiplier:0.0 constant:44.0];
    
    //[self.view addConstraints:@[leftCns, rightCns]];
    [self.view layoutIfNeeded];
     */
    
    __weak IOAuthCreateAccountViewController *weakSelf = self;
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionBeginFromCurrentState | curve animations:^{
        weakSelf.keyboardCandidateBar.frame = candidateBarEndFrame;
        //[weakSelf.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (_keyboardWillHide)
        {
            [weakSelf.keyboardCandidateBar removeFromSuperview];
            _keyboardWillHide = NO;
        }
    }];
}



- (void)keyboardWillChangeFrame:(NSNotification *)note
{
    logmethod();
    if (_keyboardIsVisible)
    {
        NSDictionary *info = [note userInfo];
        [self adjustCandidateBarToKeyboard:info animated:NO];
    }
}



- (void)keyboardWillShow:(NSNotification *)note
{
    logmethod();
    _keyboardWillShow = YES;
    NSDictionary *info = [note userInfo];
    [self adjustCandidateBarToKeyboard:info animated:YES];
}



- (void)keyboardWillHide:(NSNotification *)note
{
    logmethod();
    _keyboardWillHide = YES;
    NSDictionary *info = [note userInfo];
    [self adjustCandidateBarToKeyboard:info animated:YES];
}



#pragma mark - UITextField delegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    logmethod();
    if (textField == self.userName)
        [self highlightCellAtIndexPath:_usernameIndexPath highlight:NO];
    else if (textField == self.password)
        [self highlightCellAtIndexPath:_passwordIndexPath highlight:NO];
    else if (textField == self.eMail)
        [self highlightCellAtIndexPath:_emailIndexPath highlight:NO];
    
    return YES;
}



- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    logmethod();
    _currentTextField = textField;
    _currentTextFieldTag = textField.tag;
    [self updateSegment];
}



- (void)textFieldDidEndEditing:(UITextField *)textField
{
    logmethod();
    _currentTextField = nil;
    _currentTextFieldTag = 0;
}



- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    logmethod();
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
    
    NSError *emailError = nil;
    if (textField == self.eMail && ![IOAuth validateEmail:newString andSkipMinumunLengthCheck:YES error:&emailError])
    {
        DDLogError(@"%@: ERROR. Unsupported content. [%d]: %@", self.class, [emailError code], [emailError localizedDescription]);
        return NO;
    }
    
    return YES;
}



- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    logmethod();
    if (textField == self.eMail)
        [self goToTextFieldByTag:1];
    else
        [self goToTextFieldByTag:textField.tag + 1];
    
    return YES;
}



#pragma mark - IB Actions

- (IBAction)prevNextSegmentSelected:(UISegmentedControl *)segment
{
    logmethod();
    if (!_currentTextField)
        return;
    
    NSUInteger tag = _currentTextFieldTag;
    if (segment.selectedSegmentIndex == 1)
        tag++;
    else
        tag--;
    
    [self goToTextFieldByTag:tag];
}



- (IBAction)createTheAccount:(id)sender
{
    logmethod();
    DDLogInfo(@"%@: Create the account", self.class);
    
    if (![self validateFields])
    {
        NSError *error = [NSError errorWithDomain:@"validateFields" code:0 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"The highlighted fields are required or got wrong data.", @"Error alert message")}];
        [self displayAlertForError:error];
    }
    else
        [self attemptRegistration];
}



#pragma mark - Custom methods

- (void)displayAlertForError:(NSError *)error
{
    logmethod();
    static NSString *errorTitle = @"Oopsie";
    static NSString *dismissButtonTitle = @"Dismiss";
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:errorTitle message:error.localizedDescription delegate:nil cancelButtonTitle:dismissButtonTitle otherButtonTitles:nil];
        [alert show];
    });
}



#pragma mark Registration

- (void)attemptRegistration
{
    logmethod();
    DDLogInfo(@"%@: Attempt registration", self.class);
    
    if (self.inProgress)
    {
        DDLogVerbose(@"%@: Registration request already in progress", self.class);
        return;
    }
    
    NSString *username = self.userName.text;
    NSString *password = self.password.text;
    NSString *firstName = self.firstName.text;
    NSString *lastName = self.lastName.text;
    NSString *email = self.eMail.text;
    BOOL joinMailingList = [self.joinMailingListSwitch isOn];
    NSString *regionName = self.region.desc;
    
    self.inProgress = YES;
    
    IOAlertView *loading = [IOAlertView alertViewWithSpinnerAndTitle:@"Creating an account"];
    [loading show];
    
    __weak IOAuthCreateAccountViewController *weakSelf = self;
    [[IOAuth sharedInstance] registerUserWithUsername:username
                                             password:password
                                            firstName:firstName
                                             lastName:lastName
                                                email:email
                                      joinMailingList:joinMailingList
                                           regionName:regionName
                                      completionBlock:^(BOOL success, NSError *error)
    {
        [loading dismissAnimated:!success];
        
        weakSelf.inProgress = NO;
        
        // TODO: remove activity indicator
                                          
        if (success)
        {
            DDLogInfo(@"%@: Registration Success", weakSelf.class);
            [weakSelf handleSuccessfulRegistration];
        }
        else
        {
            DDLogError(@"%@: ERROR with user registration. [%d]: %@", weakSelf.class, error.code, error.localizedDescription);
            [weakSelf handleUnsuccessfulRegistration:error];
        }
    }];
}



- (void)handleSuccessfulRegistration
{
    logmethod();
    DDLogVerbose(@"%@: Handle successful registration", self.class);
    
    [self.responseDelegate authCreateAccountViewControllerDidSucceed:self];
}



- (void)handleUnsuccessfulRegistration:(NSError *)error
{
    logmethod();
    DDLogVerbose(@"%@: Handle unsuccessful registration", self.class);
    
    [self.responseDelegate authCreateAccountViewControllerDidFail:self error:error];
}



#pragma mark TableView controls

- (BOOL)isCellAtIndexPathHighlighted:(NSIndexPath *)indexPath
{
    logmethod();
    NSString *key = [NSString stringWithFormat:@"%d:%d", indexPath.section, indexPath.row];
    return [[self.highlightStore objectForKey:key] boolValue];
}



- (void)highlightCellAtIndexPath:(NSIndexPath *)indexPath highlight:(BOOL)highlight
{
    logmethod();
    NSString *key = [NSString stringWithFormat:@"%d:%d", indexPath.section, indexPath.row];
    [self.highlightStore setObject:@(highlight) forKey:key];
    [self updateTextColorForCellAtIndexPath:indexPath highlight:highlight];
}



- (void)updateTextColorForCellAtIndexPath:(NSIndexPath *)indexPath highlight:(BOOL)highlight
{
    logmethod();
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    UILabel *textLabel = (UILabel *)[cell viewWithTag:kCellTitleLabelTag];
    if (highlight)
        textLabel.textColor = [UIColor IORedColor];
    else
        textLabel.textColor = [UIColor blackColor];
}



#pragma mark Validations

- (BOOL)validateFields
{
    logmethod();
    NSError *usernameError = nil;
    BOOL validUsername = [IOAuth validateUsername:self.userName.text andSkipMinumunLengthCheck:NO error:&usernameError];
    [self highlightCellAtIndexPath:_usernameIndexPath highlight:!validUsername];
    
    NSError *passwordError = nil;
    BOOL validPassword = [IOAuth validatePassword:self.password.text error:&passwordError];
    [self highlightCellAtIndexPath:_passwordIndexPath highlight:!validPassword];
    
    NSError *emailError = nil;
    BOOL validEmail = [IOAuth validateEmail:self.eMail.text andSkipMinumunLengthCheck:NO error:&emailError];
    [self highlightCellAtIndexPath:_emailIndexPath highlight:!validEmail];
    
    NSError *regionError = nil;
    BOOL validRegion = [IOAuth validateRegion:self.region.desc error:&regionError];
    [self highlightCellAtIndexPath:_regionIndexPath highlight:!validRegion];
    
    return validUsername && validPassword && validEmail && validRegion;
}



#pragma mark Segment controls

- (void)updateSegment
{
    logmethod();
    [self.prevNextSegment setEnabled:(_currentTextFieldTag > 1) forSegmentAtIndex:0];
    [self.prevNextSegment setEnabled:(_currentTextFieldTag < 5 && _currentTextFieldTag > 0) forSegmentAtIndex:1];
}



- (void)goToTextFieldByTag:(NSInteger)tag
{
    logmethod();
    NSInteger index = tag - 1;
    if (index > 1)
        index -= 2;
    NSInteger section = tag > 2;
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:section];
    
    __weak UITableView *tableView = self.tableView;
    [UIView animateWithDuration:0.2 animations:^{
        [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO]; // no animation is crucial
    } completion:^(BOOL finished){
        UITextField *textField = (UITextField *)[tableView viewWithTag:tag];
        [textField becomeFirstResponder];
    }];
}



#pragma mark - Unwind segues for the region viewController

- (IBAction)done:(UIStoryboardSegue *)segue
{
    logmethod();
    DDLogVerbose(@"%@: Accepted region selection", self.class);
    // Should be blank so the Region viewController unwinds to this
}



- (IBAction)cancel:(UIStoryboardSegue *)segue
{
    logmethod();
    DDLogVerbose(@"%@: Cancelled region selection", self.class);
    // Should be blank so the Region viewController unwinds to this
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



#pragma mark Connection notifications

- (void)addNoteThereIsNoConnection
{
    logmethod();
    DDLogVerbose(@"%@: Add note there is no connection", self.class);
    
    //self.navigationItem.prompt = @"Unable to connect to our server";
    
    [[IOOfflineViewController sharedController] attachToTableView:self.tableView animated:YES];
}



- (void)removeNoteThereIsNoConnection
{
    logmethod();
    DDLogVerbose(@"%@: Remove note there is no connection", self.class);
    
    //self.navigationItem.prompt = nil;
    
    [[IOOfflineViewController sharedController] detachAnimated:YES];
}



#pragma mark - IOBaseCellControllerDelegate Protocol

- (id)getManagedObjectDataForKey:(NSString *)key
{
    logmethod();
    return self.region;
}



- (void)setManagedObjectDataForKey:(NSString *)key withObject:(id)object
{
    logmethod();
    DDLogVerbose(@"%@: Set region", self.class);
    self.region = (Region *)object;
}

@end
