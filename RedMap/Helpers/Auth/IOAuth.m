//
//  IOAuth.m
//  RedMap
//
//  Created by Evo Stamatov on 25/06/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOAuth.h"
#import "AppDelegate.h"
#import "IOOperations.h"
#import "IOPhotoCollection.h"
#import "IOSightingAttributesController.h"
#import "Sighting-typedefs.h"
#import "Sighting.h"
#import "Species.h"
#import "User-typedefs.h"
#import "User.h"
#import <Accounts/Accounts.h>                                                   // allows for iOS accounts comms
#import "IOCoreDataHelper.h"
//#import <Social/Social.h>                                                       // allows for social accounts comms
#import "IOAlertView.h"
#import "IOSightingsController.h"

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

NSString *const IOAuthErrorDomain = @"au.org.redmap.ioauth.errors";
NSString *const IOSightingValidationErrorUserInfoLocalizedErrorsKey = @"localizedErrorsArray";

NSString *const IOAuthRemoveUserNotification = @"IOAuthRemoveUserNotification";

NSString *const IOAuthExceptionMissingValue = @"IOAuthExceptionMissingValue";
NSString *const IOAuthExceptionValueLengthTooShort = @"IOAuthExceptionValueLengthTooShort";
NSString *const IOAuthExceptionValueLengthTooLong = @"IOAuthExceptionValueLengthTooLong";

CGFloat const maxDepth = 10923.0f; // metres
CGFloat const maxSpeciesLength = 3500.0f; // centimetres
CGFloat const maxSpeciesWeight = 190000.0f; // kilograms
CGFloat const maxWaterTemperature = 120.0f; // degrees Celsius

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface IOAuth ()

@property (nonatomic, strong, readwrite) User *currentUser;

// Facebook specific properties
@property (nonatomic, strong) ACAccountStore *accountStore;

@property (nonatomic, strong) IOOperations *pendingOperations;

@property (nonatomic, assign) BOOL triedFacebookCredentialsRenewal;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation IOAuth

+ (IOAuth *)sharedInstance
{
    static IOAuth *instance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}

////////////////////////////////////////////////////////////////////////////////
- (IOOperations *)pendingOperations
{
    logmethod();
    
    if (!_pendingOperations)
        _pendingOperations = [IOOperations new];
    
    return _pendingOperations;
}

////////////////////////////////////////////////////////////////////////////////
- (User *)currentUser
{
    logmethod();
    if (_currentUser == nil) {
        NSManagedObjectContext *context = [[IOCoreDataHelper sharedInstance] context];
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"User"];
        fetchRequest.fetchLimit = 1;
        
        __block NSArray *entries = nil;
        [context performBlockAndWait:^{
            entries = [context executeFetchRequest:fetchRequest error:nil];
        }];
        _currentUser = [entries lastObject];
    }
    
    return _currentUser;
}

////////////////////////////////////////////////////////////////////////////////
- (BOOL)hasCurrentUser
{
    logmethod();
    return self.currentUser != nil;
}

////////////////////////////////////////////////////////////////////////////////
- (BOOL)isCurrentUserAuthenticated
{
    logmethod();
    BOOL authenticated = [self.currentUser.status intValue] >= IOAuthUserStatusServerAuthenticated;
    if (authenticated)
        [self checkForPengingSightingsToUpload];
    
    return authenticated;
}

////////////////////////////////////////////////////////////////////////////////
- (void)removeCurrentUser
{
    logmethod();
    [self.pendingOperations.updateCurrentUserAttributesOperation cancel];
    [self removeAnyExistingUsersFromStore];
    _currentUser = nil;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Validations

+ (BOOL)validateUsername:(NSString *)string andSkipMinumunLengthCheck:(BOOL)skipMinimumLengthCheck error:(NSError *__autoreleasing *)error
{
    logmethod();
    if (!string)
    {
        if (error != NULL)
            *error = [NSError errorWithDomain:@"validateUsername" code:1 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"No username provided.", @"When username variable is nil")}];
        return NO;
    }
    
    // min 3 characters
    if (!skipMinimumLengthCheck && [string length] < 3)
    {
        if (error != NULL)
            *error = [NSError errorWithDomain:@"validateUsername" code:2 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Username must be at least three (3) characters in length.", @"When username is too short")}];
        return NO;
    }
    
    // max 30 characters
    if ([string length] > 30)
    {
        if (error != NULL)
            *error = [NSError errorWithDomain:@"validateUsername" code:3 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Username cannot be more than 30 characters in length.", @"When username is too long")}];
        return NO;
    }
    
    // regex [a-zA-Z0-9@.+-_]+
    NSError *regexpError = nil;
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:@"[a-zA-Z0-9@.+_-]+" options:kNilOptions error:&regexpError];
    NSString *maybeEmptyString = [regexp stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, [string length]) withTemplate:@""];
    if ([maybeEmptyString isEqual:@""])
        return YES;
    
    if (error != NULL)
        *error = [NSError errorWithDomain:@"validateUsername" code:4 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"The username includes disallowed characters.", @"When username includes bad characters")}];
    return NO;
}

////////////////////////////////////////////////////////////////////////////////
+ (BOOL)validatePassword:(NSString *)string error:(NSError *__autoreleasing *)error
{
    logmethod();
    if (!string)
    {
        if (error != NULL)
            *error = [NSError errorWithDomain:@"validatePassword" code:1 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"No password provided.", @"When password variable is nil")}];
        return NO;
    }
    
    // min 6 characters
    if ([string length] >= 6)
        return YES;
    
    if (error != NULL)
        *error = [NSError errorWithDomain:@"validatePassword" code:2 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"The password must be at least six (6) characters.", @"When password is too short")}];
    return NO;
}

////////////////////////////////////////////////////////////////////////////////
+ (BOOL)validateEmail:(NSString *)string andSkipMinumunLengthCheck:(BOOL)skipMinimumLengthCheck error:(NSError *__autoreleasing *)error
{
    logmethod();
    if (!string)
    {
        if (error != NULL)
            *error = [NSError errorWithDomain:@"validateEmail" code:1 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"No email provided.", @"When email variable is nil")}];
        return NO;
    }
    
    // min 5 characters
    if (!skipMinimumLengthCheck && [string length] < 5)
    {
        if (error != NULL)
            *error = [NSError errorWithDomain:@"validateEmail" code:2 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Email must be at least five (5) characters in length.", @"When email is too short")}];
        return NO;
    }
    
    if (skipMinimumLengthCheck)
    {
        // make sure first two characters are not @ symbol
        __block NSUInteger count = 0;
        __block BOOL clearToGo = YES;
        [string enumerateSubstringsInRange:NSMakeRange(0, string.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
            if ([substring isEqualToString:@"@"])
            {
                clearToGo = NO;
                *stop = YES;
            }
            
            count++;
            if (count > 1)
                *stop = YES;
        }];
        
        return clearToGo;
    }
    else
    {
        // regex ^[^@]{2,}@[^@]{2,}$
        NSError *regexpError = nil;
        NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:@"^[^@]{2,}@[^@]{2,}$" options:kNilOptions error:&regexpError];
        NSString *maybeEmptyString = [regexp stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, [string length]) withTemplate:@""];
        if ([maybeEmptyString isEqual:@""])
            return YES;
    }
    
    if (error != NULL)
        *error = [NSError errorWithDomain:@"validateEmail" code:3 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"The email is invalid.", @"When the email does not include an @ character")}];
    return NO;
}

////////////////////////////////////////////////////////////////////////////////
+ (BOOL)validateRegion:(NSString *)string error:(NSError *__autoreleasing *)error
{
    logmethod();
    // TODO: validate, based on available regions
    if (!string)
    {
        if (error != NULL)
            *error = [NSError errorWithDomain:@"validateRegion" code:1 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"No region provided.", @"When region variable is nil")}];
        return NO;
    }
    
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
+ (BOOL)validateSightingObjectForSubmission:(NSManagedObjectID *)sightingID context:(NSManagedObjectContext *)context error:(NSError **)error
{
    logmethod();
    Sighting *sighting = (Sighting *)[context objectWithID:sightingID];
    
    BOOL wasFault = sighting.isFault;
    
    BOOL isValid = [self validateSightingForSubmission:sighting error:error];
    
    if (wasFault)
        [IOCoreDataHelper faultObjectWithID:sightingID inContext:context];
    
    return isValid;
}

////////////////////////////////////////////////////////////////////////////////
+ (BOOL)validateSightingForSubmission:(Sighting *)sighting error:(NSError **)error
{
    logmethod();
    if (!sighting)
    {
        if (error != NULL)
        {
            NSString *descriptionIntro = NSLocalizedStringWithDefaultValue(@"ioauth.sighting.error.validation.intro", nil, [NSBundle mainBundle], @"There are some validation errors: %@", @"Validation error intro text");
            NSString *noSighting = NSLocalizedStringWithDefaultValue(@"ioauth.sighting.error.validation.no-sighting", nil, [NSBundle mainBundle], @"No sighting", @"Validation error description");
            NSString *description = [NSString stringWithFormat:descriptionIntro, noSighting];
            NSDictionary *userInfo = @{
                                       NSLocalizedDescriptionKey: description,
                                       IOSightingValidationErrorUserInfoLocalizedErrorsKey: @[noSighting],
                                       };
            *error = [NSError errorWithDomain:IOAuthErrorDomain code:IOSightingValidationFieldErrorNoSighting userInfo:userInfo];
        }
        return NO;
    }
    
    NSMutableArray *errors = [NSMutableArray array];

    IOSightingValidationFieldError validationErrors = IOSightingValidationFieldErrorNoError;

    // No Region
    if (sighting.region == nil)
    {
        validationErrors |= IOSightingValidationFieldErrorRegionNotSet;
        if (error != NULL)
        {
            NSString *description = NSLocalizedStringWithDefaultValue(@"ioauth.sighting.error.validation.no-region", nil, [NSBundle mainBundle], @"No region", @"Validation error description");
            [errors addObject:description];
        }
    }
    
    // No Species and no Other species
    if (sighting.species == nil && [sighting.otherSpecies boolValue] == NO)
    {
        validationErrors |= IOSightingValidationFieldErrorSpeciesNotSet;
        if (error != NULL)
        {
            NSString *description = NSLocalizedStringWithDefaultValue(@"ioauth.sighting.error.validation.no-species", nil, [NSBundle mainBundle], @"No species", @"Validation error description");
            [errors addObject:description];
        }
    }
    
    // No Date
    if (sighting.dateSpotted == nil)
    {
        validationErrors |= IOSightingValidationFieldErrorDateSpottedNotSet;
        if (error != NULL)
        {
            NSString *description = NSLocalizedStringWithDefaultValue(@"ioauth.sighting.error.validation.no-date", nil, [NSBundle mainBundle], @"No date", @"Validation error description");
            [errors addObject:description];
        }
    }
    
    // No Time
    if (sighting.time == nil)
    {
        validationErrors |= IOSightingValidationFieldErrorTimeSpottedNotSet;
        if (error != NULL)
        {
            NSString *description = NSLocalizedStringWithDefaultValue(@"ioauth.sighting.error.validation.no-time", nil, [NSBundle mainBundle], @"No time", @"Validation error description");
            [errors addObject:description];
        }
    }
    
    // No Location
    if ([sighting.locationStatus integerValue] == IOSightingLocationStatusNotSet)
    {
        validationErrors |= IOSightingValidationFieldErrorLocationNotSet;
        if (error != NULL)
        {
            NSString *description = NSLocalizedStringWithDefaultValue(@"ioauth.sighting.error.validation.no-location", nil, [NSBundle mainBundle], @"No location", @"Validation error description");
            [errors addObject:description];
        }
    }
    
    // No Activity
    if (sighting.activity == nil)
    {
        validationErrors |= IOSightingValidationFieldErrorActivityNotSet;
        if (error != NULL)
        {
            NSString *description = NSLocalizedStringWithDefaultValue(@"ioauth.sighting.error.validation.no-activity", nil, [NSBundle mainBundle], @"No activity", @"Validation error description");
            [errors addObject:description];
        }
    }
    
    // No Species Count
    if (sighting.speciesCount == nil)
    {
        validationErrors |= IOSightingValidationFieldErrorSpeciesCountNotSet;
        if (error != NULL)
        {
            NSString *description = NSLocalizedStringWithDefaultValue(@"ioauth.sighting.error.validation.no-species-count", nil, [NSBundle mainBundle], @"No species count", @"Validation error description");
            [errors addObject:description];
        }
    }
    
    // No Gender
    if (sighting.speciesSex == nil)
    {
        validationErrors |= IOSightingValidationFieldErrorSpeciesSexNotSet;
        if (error != NULL)
        {
            NSString *description = NSLocalizedStringWithDefaultValue(@"ioauth.sighting.error.validation.no-species-gender", nil, [NSBundle mainBundle], @"No species gender", @"Validation error description");
            [errors addObject:description];
        }
    }

    // No photos
    if ([sighting.photosCount integerValue] <= 0)
    {
        validationErrors |= IOSightingValidationFieldErrorPhotosCountTooLow;
        if (error != NULL)
        {
            NSString *description = NSLocalizedStringWithDefaultValue(@"ioauth.sighting.error.validation.no-photos", nil, [NSBundle mainBundle], @"No photos attached", @"Validation error description");
            [errors addObject:description];
        }
    }
    
    // Depth off range
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    formatter.locale = [NSLocale currentLocale];
    formatter.usesSignificantDigits = NO;
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];

    NSNumber *maxDepthN = @(maxDepth);
    if ([sighting.depth floatValue] > [maxDepthN floatValue])
    {
        validationErrors |= IOSightingValidationFieldErrorDepthTooHigh;
        if (error != NULL)
        {
            NSString *description = NSLocalizedStringWithDefaultValue(@"ioauth.sighting.error.validation.depth-too-high", nil, [NSBundle mainBundle], @"Depth must be under %@ metres", @"Validation error description");
            [errors addObject:[NSString stringWithFormat:description, maxDepthN]];
        }
    }

    // Species Length off range
    NSNumber *maxSpeciesLengthN = @(maxSpeciesLength);
    if ([sighting.speciesLength floatValue] > [maxSpeciesLengthN floatValue])
    {
        validationErrors |= IOSightingValidationFieldErrorSpeciesLengthTooHigh;
        if (error != NULL)
        {
            NSString *description = NSLocalizedStringWithDefaultValue(@"ioauth.sighting.error.validation.species-length-too-high", nil, [NSBundle mainBundle], @"Species size must be under %@ centimetres", @"Validation error description");
            [errors addObject:[NSString stringWithFormat:description, maxSpeciesLengthN]];
        }
    }
    
    // Species Weight off range
    NSNumber *maxSpeciesWeightN = @(maxSpeciesWeight);
    if ([sighting.speciesWeight floatValue] > [maxSpeciesWeightN floatValue])
    {
        validationErrors |= IOSightingValidationFieldErrorSpeciesWeightTooHigh;
        if (error != NULL)
        {
            NSString *description = NSLocalizedStringWithDefaultValue(@"ioauth.sighting.error.validation.species-weight-too-high", nil, [NSBundle mainBundle], @"Species weight must be under %@ kilograms", @"Validation error description");
            [errors addObject:[NSString stringWithFormat:description, maxSpeciesWeightN]];
        }
    }
    
    // Water Temperature off range
    NSNumber *maxWaterTemperatureN = @(maxWaterTemperature);
    if ([sighting.waterTemperature floatValue] > [maxWaterTemperatureN floatValue])
    {
        validationErrors |= IOSightingValidationFieldErrorWaterTemperatureTooHigh;
        if (error != NULL)
        {
            NSString *description = NSLocalizedStringWithDefaultValue(@"ioauth.sighting.error.validation.water-temperature-too-high", nil, [NSBundle mainBundle], @"Water temperature must be under %@ degrees Celsius", @"Validation error description");
            [errors addObject:[NSString stringWithFormat:description, maxWaterTemperatureN]];
        }
    }
    
    if (error != NULL)
    {
        NSString *descriptionIntro = NSLocalizedStringWithDefaultValue(@"ioauth.sighting.error.validation.intro", nil, [NSBundle mainBundle], @"There are some validation errors: %@", @"Validation error intro text");
        NSString *separator = NSLocalizedStringWithDefaultValue(@"ioauth.sighting.error.validation.separator", nil, [NSBundle mainBundle], @", ", @"Validation errors separator");
        NSString *description = [NSString stringWithFormat:descriptionIntro, [errors componentsJoinedByString:separator]];
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey: description,
                                   IOSightingValidationErrorUserInfoLocalizedErrorsKey: errors,
                                   };
        *error = [NSError errorWithDomain:IOAuthErrorDomain code:validationErrors userInfo:userInfo];
    }

    return validationErrors == IOSightingValidationFieldErrorNoError;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Login and Registration + CoreData User control

/*
- (void)removePreviousUserWithCompletionBlock:(void (^)())completionBlock errorBlock:(void (^)(NSError *error))errorBlock andWait:(BOOL)andWait
{
    NSManagedObjectContext *context = self.managedObjectContext;
    
    void (^block)() = ^{
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:context];
        [fetchRequest setEntity:entity];
        [fetchRequest setFetchBatchSize:20];
        NSError *fetchError = nil;
        NSArray *users = [context executeFetchRequest:fetchRequest error:&fetchError];
        
        if (fetchError)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:IOAuthRemovedAllUsersNotificationName object:@{@"error":fetchError}];
            if (errorBlock)
                errorBlock(fetchError);
        }
        else
        {
            NSError *saveError = nil;
            
            // remove all user entries
            if (users.count)
            {
                for (User *user in users)
                {
                    / *
                    // Make sure to remove all photos
                    for (Sighting *sighting in user.sightings)
                    {
                        NSError *deletePhotosDirError = nil;
                        [IOPhoto removeDirectoryForUUID:sighting.uuid error:&deletePhotosDirError];
                        // TODO: report delete errors
                    }
                     * /
                    
                    [context deleteObject:user];
                }
                
#warning TODO: use IOPhoto removeDirectoryForUUID above
                NSFileManager *fm = [NSFileManager defaultManager];
                NSURL *libraryDirectory = [[fm URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
                NSURL *sightingsDirURL = [libraryDirectory URLByAppendingPathComponent:@"Sightings" isDirectory:YES];
                if (sightingsDirURL && [sightingsDirURL checkResourceIsReachableAndReturnError:NULL] == YES)
                    [[NSFileManager defaultManager] removeItemAtURL:sightingsDirURL error:NULL];
                
                
                @try {
                    if (![context save:&saveError])
                    {
                        [[NSNotificationCenter defaultCenter] postNotificationName:IOAuthRemovedAllUsersNotificationName object:@{@"error":saveError}];
                        if (errorBlock)
                            errorBlock(saveError);
                    }
                }
                @catch (NSException *exception) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:IOAuthRemovedAllUsersNotificationName object:@{@"exception":exception}];
                    if (errorBlock)
                        errorBlock([NSError errorWithDomain:@"blankOutUserTable" code:1 userInfo:@{NSLocalizedDescriptionKey: @"An error while removing previous user"}]);
                }
            }
            
            if (!saveError)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:IOAuthRemovedAllUsersNotificationName object:nil];
                if (completionBlock)
                    completionBlock();
            }
        }
    };
    
    // Shield ourselves to a safe thread
    if (andWait)
        [context performBlockAndWait:block];
    else
        [context performBlock:block];
}
*/

////////////////////////////////////////////////////////////////////////////////
- (void)reAuthenticateCurrentUserWithCompletionBlock:(void (^)(BOOL success, NSError *error))completionBlock
{
    logmethod();
    DDLogVerbose(@"%@: Attempting remote user authentication", self.class);
    
    if (![self hasCurrentUser])
    {
        DDLogError(@"%@: ERROR. There is no stored user", self.class);
        
        completionBlock(NO, [NSError errorWithDomain:@"reAuthenticateCurrentUser" code:400 userInfo:@{NSLocalizedDescriptionKey: @"There is no logged in user."}]);
        return;
    }
    
    IOAuthUserStatus status = [self.currentUser.status intValue];
    if (status == IOAuthUserStatusUnknown)
    {
        DDLogError(@"%@: ERROR. The user record is in inconsistency state! PANIC!", self.class);
#if DEBUG
        DDLogError(@"UserID: %@, User: %@", self.currentUser.userID, self.currentUser);
#endif
        
        completionBlock(NO, [NSError errorWithDomain:@"reAuthenticateCurrentUser" code:401 userInfo:@{NSLocalizedDescriptionKey: @"The user is in inconsitency state. PANIC!"}]);
        return;
    }
    
    // Facebook login works only when there is internet connection and shouldn't
    // be considered for reAuthentication
    
    if (status == IOAuthUserStatusLocalLogin || status == IOAuthUserStatusLocalRegistration)
    {
        User *user = self.currentUser;
        
        NSString *username = user.username;
        NSString *password = user.password;
        
        NSManagedObjectContext *context = [[IOCoreDataHelper sharedInstance] context];
        __weak __typeof(self)weakSelf = self;
        
        void (^aCompletionBlock)(NSString *, NSError *) = ^(NSString *authToken, NSError *error) {
            if (!authToken || authToken.length == 0 || error)
            {
                DDLogError(@"%@: ERROR. No or malformed auth token. [%d] %@", weakSelf.class, error.code, error.localizedDescription);
                if (completionBlock)
                    completionBlock(NO, error);
            }
            else
            {
                DDLogVerbose(@"%@: User authenticated successfully", weakSelf.class);
                
                user.authToken = authToken;
                
                [IOCoreDataHelper faultObjectWithID:user.objectID inContext:context];
                
                //[weakSelf attachStraySightingsToCurrentUser];
                [weakSelf updateCurrentUserAttributes];
                
                if (completionBlock)
                    completionBlock(YES, nil);
            }
        };
        
        void (^anErrorBlock)(NSError *, NSInteger) = ^(NSError *error, NSInteger statusCode) {
            DDLogError(@"%@: ERROR with user authentication. StatusCode: %d. [%d]: %@", weakSelf.class, statusCode, error.code, error.localizedDescription);
            
            if (completionBlock)
                completionBlock(NO, error);
        };
        
        if (status == IOAuthUserStatusLocalRegistration)
        {
            DDLogVerbose(@"%@: Registering a new user", self.class);
            NSString *firstName = user.firstName;
            NSString *lastName = user.lastName;
            NSString *email = user.email;
            BOOL joinMailingList = [user.joinMailingList boolValue];
            NSString *regionName = user.region;
            
            [RMAPI registerUser:username
                       password:password
                      firstName:firstName
                       lastName:lastName
                          email:email
                joinMailingList:joinMailingList
                     regionName:regionName
                completionBlock:aCompletionBlock
                     errorBlock:anErrorBlock];
        }
        else
        {
            DDLogVerbose(@"%@: Logging in a new user", self.class);
            [RMAPI logInUser:username
                    password:password
             completionBlock:aCompletionBlock
                  errorBlock:anErrorBlock];
        }
    }
    else if (completionBlock)
    {
        DDLogVerbose(@"%@: SKIPPED. User already authenticated", self.class);
        
        completionBlock(YES, nil);
    }
}

////////////////////////////////////////////////////////////////////////////////
- (void)createUserWithUsername:(NSString *)username
                      password:(NSString *)password
                     firstName:(NSString *)firstName
                      lastName:(NSString *)lastName
                         email:(NSString *)email
               joinMailingList:(BOOL)joinMailingList
                    regionName:(NSString *)regionName
           registerationStatus:(BOOL)registrationStatus
               completionBlock:(void (^)(BOOL success, NSError* error))completionBlock
{
    logmethod();
    DDLogVerbose(@"%@: Creating a new user record", self.class);
    
    [self removeAnyExistingUsersFromStore];
    
    NSManagedObjectContext *context = [[IOCoreDataHelper sharedInstance] context];
    
    User *user = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:context];
    user.username = username;
    user.password = password;
    
    user.firstName = firstName;
    user.lastName = lastName;
    user.email = email;
    user.joinMailingList = @(joinMailingList);
    user.region = regionName;
    
    NSDate *now = [NSDate date];
    user.dateCreated = now;
    user.dateModified = now;
    
    if (registrationStatus)
        user.status = @(IOAuthUserStatusLocalRegistration);
    else
        user.status = @(IOAuthUserStatusLocalLogin);
    
    NSError *validateError = nil;
    if ([user validateForInsert:&validateError])
    {
        [IOCoreDataHelper faultObjectWithID:user.objectID inContext:context];
        DDLogInfo(@"%@: Successfully created user record", self.class);
        
        self.currentUser = user;
        [self reAuthenticateCurrentUserWithCompletionBlock:completionBlock];
    }
    else
    {
        NSString *description = nil;
        NSInteger code = 0;
        switch ([validateError code]) {
            case NSValidationStringTooShortError:
                {
                    description = @"The username, password or email is too short.";
                    code = 1;
                }
                break;
            case NSValidationStringTooLongError:
                {
                    description = @"The username, password or email is too long.";
                    code = 2;
                }
                break;
            case NSValidationStringPatternMatchingError:
                {
                    description = @"The provided username contains unacceptable characters.";
                    code = 3;
                }
                break;
            default:
                {
                    description = @"An unknown error occured.";
                    code = 4;
                }
                break;
        }
#if TRACK
        [GoogleAnalytics sendEventWithCategory:@"admin-notification" withAction:@"create-user-validate" withLabel:[validateError localizedDescription] withValue:@1];
#endif
        DDLogError(@"%@: ERROR validating user record. [%d]: %@. MyMessage: %@", self.class, validateError.code, validateError.localizedDescription, description);
        
        DDLogInfo(@"%@: DELETING temporary user record", self.class);
        [context deleteObject:user];
        [IOCoreDataHelper faultObjectWithID:user.objectID inContext:context];
        
        if (description && completionBlock)
            completionBlock(NO, [NSError errorWithDomain:@"createUserWithUsernameAndPassword" code:code userInfo:@{NSLocalizedDescriptionKey: description}]);
    }
    
    
}

////////////////////////////////////////////////////////////////////////////////
- (void)registerUserWithUsername:(NSString *)username
                        password:(NSString *)password
                       firstName:(NSString *)firstName
                        lastName:(NSString *)lastName
                           email:(NSString *)email
                 joinMailingList:(BOOL)joinMailingList
                      regionName:(NSString *)regionName
                 completionBlock:(void (^)(BOOL success, NSError* error))completionBlock
{
    logmethod();
    [self createUserWithUsername:username
                        password:password
                       firstName:firstName
                        lastName:lastName
                           email:email
                 joinMailingList:joinMailingList
                      regionName:regionName
             registerationStatus:YES
                 completionBlock:completionBlock];
}

////////////////////////////////////////////////////////////////////////////////
- (void)loginUserWithUsername:(NSString *)username
                     password:(NSString *)password
              completionBlock:(void (^)(BOOL success, NSError* error))completionBlock
{
    logmethod();
    [self createUserWithUsername:username
                        password:password
                       firstName:nil
                        lastName:nil
                           email:nil
                 joinMailingList:YES // it is default value for the User model
                      regionName:nil
             registerationStatus:NO
                 completionBlock:completionBlock];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark Facebook

- (void)registerUserFromFacebookWithCompletionBlock:(void (^)(BOOL success, NSError* error))completionBlock
{
    logmethod();
    DDLogVerbose(@"%@: Registering a user with Facebook", self.class);
    
    __weak __typeof(self)weakSelf = self;
    [self requestFacebookAccsessTokenAndGetServerAuthTokenWithCompletionBlock:^(NSString *authToken, NSError *error) {
        if (error)
        {
            DDLogError(@"%@: ERROR getting Facebook auth token", self.class);
            completionBlock(NO, error);
        }
        else
        {
            if (authToken.length == 0)
            {
                DDLogError(@"%@: ERROR. Zero length auth token", weakSelf.class);
                
                NSString *description = NSLocalizedString(@"Received a malformed auth token", @"");
                NSError *noAuthTokenError = [NSError errorWithDomain:@"registerUserFromFacebook" code:400 userInfo:@{ NSLocalizedDescriptionKey: description }];
                completionBlock(NO, noAuthTokenError);
            }
            else
                [weakSelf createCoreDataUserWithAuthToken:authToken completion:completionBlock];
        }
    }];
}

- (void)removeAnyExistingUsersFromStore
{
    logmethod();
    NSManagedObjectContext *context = [[IOCoreDataHelper sharedInstance] context];
    
    DDLogVerbose(@"%@: Fetching existing user(s) for removal", self.class);
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"User"];
    NSError *error = nil;
    NSArray *fetchedItems = [context executeFetchRequest:fetchRequest error:&error];
    if (error || !fetchedItems)
    {
        DDLogError(@"%@: ERROR fetching users. [%d]: %@", self.class, error.code, error.localizedDescription);
        return;
    }
    
    if (fetchedItems.count > 0)
    {
        DDLogVerbose(@"%@: Removing existing user(s)", self.class);
        for (User *user in fetchedItems)
        {
            DDLogVerbose(@"%@: Removing user's sightings images", self.class);
            BOOL hadErrors = NO;
            NSMutableSet *draftSightings = [NSMutableSet set];
            for (Sighting *sighting in user.sightings)
            {
                NSError *deletePhotosDirError = nil;
                if ([sighting.status integerValue] == IOSightingStatusDraft)
                {
                    [draftSightings addObject:sighting];
                }
                else
                {
                    if (![IOPhoto removeDirectoryForUUID:sighting.uuid error:&deletePhotosDirError])
                    {
                        DDLogError(@"%@: ERROR deleting user's sighting images. [%d]: %@", self.class, deletePhotosDirError.code, deletePhotosDirError.localizedDescription);
#if DEBUG
                        DDLogError(@"%@", sighting);
#endif
                        hadErrors = YES;
                    }
                    //[IOCoreDataHelper faultObjectWithID:sighting.objectID inContext:context];
                }
            }
            
            if (hadErrors)
                DDLogError(@"%@: ERRORS removing user's sightings images", self.class);
            else
                DDLogVerbose(@"%@: Done removing user's sightings images", self.class);
            
            if (draftSightings.count > 0)
            {
                __weak __typeof(self)weakSelf = self;
                [draftSightings enumerateObjectsUsingBlock:^(Sighting *obj, BOOL *stop) {
                    DDLogError(@"%@: ERROR. Found a draft sighting, belonging to the user. Releasing it from the user.", weakSelf.class);
                    obj.user = nil;
                }];
            }
            
            [context deleteObject:user];
            [IOCoreDataHelper saveContextHierarchy:context];
            //[IOCoreDataHelper faultObjectWithID:user.objectID inContext:context];
            
            NSDictionary *userInfo = nil;
            [[NSNotificationCenter defaultCenter] postNotificationName:IOAuthRemoveUserNotification object:nil userInfo:userInfo];
            
            [NSFetchedResultsController deleteCacheWithName:nil];
            
            // BRUTE FORCE :)
            /*
            NSFileManager *fm = [NSFileManager defaultManager];
            NSURL *libraryDirectory = [[fm URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
            NSURL *sightingsDirURL = [libraryDirectory URLByAppendingPathComponent:@"Sightings" isDirectory:YES];
            if (sightingsDirURL && [sightingsDirURL checkResourceIsReachableAndReturnError:NULL] == YES)
                [[NSFileManager defaultManager] removeItemAtURL:sightingsDirURL error:NULL];
             */
        }
        DDLogVerbose(@"%@: Removed all users", self.class);
    }
}

// When authenticating through Facebook
// Assumes authToken.lenght > 0
- (void)createCoreDataUserWithAuthToken:(NSString *)authToken completion:(IOAuthSuccessBlock)completionBlock
{
    logmethod();
    DDLogVerbose(@"%@: Creating user record, using auth token", self.class);
    
    [self removeAnyExistingUsersFromStore];
    
    NSManagedObjectContext *context = [[IOCoreDataHelper sharedInstance] context];
    
    User *user = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:context];
    user.authToken = authToken;
    
    NSError *validateError = nil;
    if ([user validateForInsert:&validateError])
    {
        [IOCoreDataHelper faultObjectWithID:user.objectID inContext:context];
        DDLogVerbose(@"%@: SUCCES saving user record", self.class);
        
        self.currentUser = user;
        
        //[self attachStraySightingsToCurrentUser];
        [self updateCurrentUserAttributes];
        
        if (completionBlock)
            completionBlock(YES, nil);
    }
    else
    {
        DDLogError(@"%@: ERROR validating user record. [%d]: %@", self.class, validateError.code, validateError.localizedDescription);
        
        //DDLogInfo(@"%@: DELETING temporary user record", self.class);
        //[context deleteObject:user];
        
        [IOCoreDataHelper faultObjectWithID:user.objectID inContext:context];
        
        if (completionBlock)
            completionBlock(NO, validateError);
    }
    
    //[[IOCoreDataHelper sharedInstance] backgroundSaveContext];
}

/*
- (void)OLDregisterUserFromFacebookWithCompletionBlock:(void (^)(BOOL success, NSError* error))completionBlock
                                         errorBlock:(void (^)(NSError *error))errorBlock
{
    @throw [NSException exceptionWithName:@"OLDregisterUserFromFacebookWithCompletionBlock:errorBlock:" reason:@"DEPRECATED" userInfo:nil];
    return;
    
    __weak NSManagedObjectContext *context = self.managedObjectContext;
    __weak IOAuth *weakSelf = self;
    
    [self removePreviousUserWithCompletionBlock:^{
        // This block is called from within the context thread, so no need to wrap it into [context performBlock:]
        User *user = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:context];
        //user.username = @"user";
        user.status = @(IOAuthUserStatusFacebookLogin);
        
        NSDate *now = [NSDate date]; // date properties are not handled by core data
        user.dateCreated = now;
        user.dateModified = now;
        
        NSError *validateError = nil;
        if (![user validateForInsert:&validateError])
        {
            NSString *description = nil;
            NSInteger code = 0;
            switch ([validateError code]) {
                default:
                    {
                        description = @"An unknown error occured.";
                        code = 4;
                    }
                    break;
            }
#if TRACK
            [GoogleAnalytics sendEventWithCategory:@"admin-notification" withAction:@"create-user-facebook-validate" withLabel:[validateError localizedDescription] withValue:@1];
#endif
            
            if (description && errorBlock)
                errorBlock([NSError errorWithDomain:@"createUserFromFacebook" code:code userInfo:@{NSLocalizedDescriptionKey: description}]);
        }
        else
        {
            NSError *saveError = nil;
            if (![context save:&saveError])
            {
                // TODO: this should never happen, because of the validation above
#if TRACK
            [GoogleAnalytics sendEventWithCategory:@"admin-notification" withAction:@"create-user-facebook-save-db" withLabel:[saveError localizedDescription] withValue:@1];
#endif
                abort();
            }
            else
                [weakSelf requestFacebookAccsessTokenAndGetServerAuthTokenWithCompletionBlock:^(NSString *authToken, NSError *error) {
                    if (error)
                        errorBlock(error);
                    else
                    {
                        user.authToken = authToken;
                        
                        NSError *validateError = nil;
                        if ([user validateForUpdate:&validateError])
                        {
                            [context performBlock:^{
                                NSError *saveError = nil;
                                if ([context save:&saveError])
                                {
                                    [weakSelf.pendingOperations updateCurrentUserAttributesForced:YES];
                                    if (completionBlock)
                                        completionBlock(YES, nil);
                                }
                                else
                                {
                                    // TODO: save error
                                }
                            }];
                        }
                        else
                        {
                            // TODO: validate error
                        }
                    }
                } errorBlock:errorBlock];
        }
    } errorBlock:^(NSError *error) {
        if (errorBlock)
            errorBlock(error);
    } andWait:NO];
}
 */

////////////////////////////////////////////////////////////////////////////////
- (void)requestFacebookAccsessTokenAndGetServerAuthTokenWithCompletionBlock:(void (^)(NSString *authToken, NSError* error))completionBlock
{
    logmethod();
    DDLogVerbose(@"%@: Request Facebook access token", self.class);
    if (self.accountStore == nil)
        self.accountStore = [[ACAccountStore alloc] init];
    
    ACAccountType *facebookAccountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    NSDictionary *options = @{
                              ACFacebookAppIdKey: FACEBOOK_APP_API_KEY,
                              ACFacebookPermissionsKey: @[@"email"],
                              //ACFacebookAudienceKey: ACFacebookAudienceFriends
                              };
    
    __weak __typeof(self)weakSelf = self;
    [self.accountStore requestAccessToAccountsWithType:facebookAccountType options:options completion:^(BOOL granted, NSError *error) {
        if (granted)
        {
            DDLogVerbose(@"%@: Facebook access was granted", weakSelf.class);
            NSArray *accounts = [weakSelf.accountStore accountsWithAccountType:facebookAccountType];
            ACAccount *facebookAccount = [accounts lastObject];
            // TODO: should we save the account?
            //- (void)saveAccount:(ACAccount *)account withCompletionHandler:(ACAccountStoreSaveCompletionHandler)completionHandler;
            // [weakSelf.accountStore saveAccount:facebookAccount withCompletionHandler...]
            ACAccountCredential *facebookCredential = [facebookAccount credential];
            NSString *facebookAccessToken = [[facebookCredential oauthToken] copy];
#if DEBUG
            DDLogInfo(@"%@: Facebook Access Token: %@", weakSelf.class, facebookAccessToken);
#endif
            if (!facebookAccessToken)
            {
                NSString *description = NSLocalizedString(@"Unable to get a proper Facebook access token", @"");
                NSDictionary *userInfo = @{
                                           NSLocalizedDescriptionKey: description,
                                           };
                NSError *returnError = [NSError errorWithDomain:IOAuthErrorDomain code:IOAuthErrorCodeEmptyFacebookAccessToken userInfo:userInfo];
                DDLogError(@"%@: ERROR obtaining Facebook access token. [%d]: %@", weakSelf.class, returnError.code, returnError.localizedDescription);
                completionBlock(nil, returnError);
            }
            else
            {
                DDLogVerbose(@"%@: Request RMAPI Facebook auth token", weakSelf.class);
                
                [RMAPI logInFacebookWithAccessToken:facebookAccessToken completionBlock:^(NSString *authToken, NSError *error) {
                    DDLogVerbose(@"%@: Recieved RMAPI Facebook auth token response", weakSelf.class);
                    
                    completionBlock(authToken, error);
                } errorBlock:^(NSError *error, NSInteger statusCode) {
                    
                    DDLogError(@"%@: ERROR from RMAPI Facebook auth token request. StatusCode: %d. [%d]: %@", weakSelf.class, statusCode, error.code, error.localizedDescription);
                    
                    // Try to re-new the stored credentials
                    if (!weakSelf.triedFacebookCredentialsRenewal && [error.domain isEqualToString:RMAPIErrorDomain] && error.code == RMAPIErrorCodeFacebookSessionExpired)
                    {
                        [weakSelf.accountStore renewCredentialsForAccount:facebookAccount completion:^(ACAccountCredentialRenewResult renewResult, NSError *err) {
                            weakSelf.triedFacebookCredentialsRenewal = YES;
                            /*
                             ACAccountCredentialRenewResultRenewed,  // A new credential was obtained and is now associated with the account.
                             ACAccountCredentialRenewResultRejected, // Renewal failed because of a user-initiated action.
                             ACAccountCredentialRenewResultFailed,   // A non-user-initiated cancel of the prompt.
                             */
                            if (renewResult == ACAccountCredentialRenewResultRenewed)
                            {
                                [weakSelf requestFacebookAccsessTokenAndGetServerAuthTokenWithCompletionBlock:completionBlock];
                            }
                            else if (error)
                                completionBlock(nil, err);
                            else
                                completionBlock(nil, error);
                        }];
                    }
                    else
                        completionBlock(nil, error);
                }];
            }
        }
        else
        {
            NSString *message;
            /*
                typedef enum ACErrorCode {
                    ACErrorUnknown = 1,
                    ACErrorAccountMissingRequiredProperty,  // Account wasn't saved because it is missing a required property.
                    ACErrorAccountAuthenticationFailed,     // Account wasn't saved because authentication of the supplied credential failed.
                    ACErrorAccountTypeInvalid,              // Account wasn't saved because the account type is invalid.
                    ACErrorAccountAlreadyExists,            // Account wasn't added because it already exists.
                    ACErrorAccountNotFound,                 // Account wasn't deleted because it could not be found.
                    ACErrorPermissionDenied,                // The operation didn't complete because the user denied permission.
                    ACErrorAccessInfoInvalid                // The client's access info dictionary has incorrect or missing values.
                } ACErrorCode;
             */
            switch (error.code) {
                case ACErrorAccountNotFound:
                        message = NSLocalizedString(@"You haven't installed a Facebook Account to your device", @"Shows when the user tries to log in with Facebook, but the device doesn't have a Facebook account setup to use");
                    break;
                    
                case ACErrorPermissionDenied:
                        message = NSLocalizedString(@"You didn't provide access to your Facebook Account. Please, go to your Settings app and allow access from the Privacy section", @"Shows when the user tries to log in with Facebook, but the app is disallowed access to the account");
                    break;
                    
                // TODO: handle ACErrorAccountAuthenticationFailed and ACErrorAccountTypeInvalid
                    
                default:
                        message = NSLocalizedString(@"Something went wrong trying to connect to Facebook. Please, try again later", @"Shows when something unknown happened when the user tries to connect through Facebook");
                    break;
            }
     
            DDLogError(@"%@: ERROR while authenticating with Facebook [%d]: %@", weakSelf.class, error.code, error.localizedDescription);
            NSError *returnError = [NSError errorWithDomain:@"requestFacebookAccessToken" code:error.code userInfo:@{ NSLocalizedDescriptionKey: message }];
            completionBlock(nil, returnError);
        }
    }];
}

/*
- (void)requestFacebookAccsessTokenAndGetServerAuthTokenWithCompletionBlock:(void (^)(NSString *authToken, NSError* error))completionBlock
                                                                 errorBlock:(void (^)(NSError *error))errorBlock
{
    @throw [NSException exceptionWithName:@"requestFacebookAccsessTokenAndGetServerAuthTokenWithCompletionBlock:errorBlock:" reason:@"DEPRECATED" userInfo:nil];
    return;
    
    self.accountStore = [[ACAccountStore alloc] init];
    
    ACAccountType *facebookAccountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    NSDictionary *options = @{
                              ACFacebookAppIdKey: FACEBOOK_APP_API_KEY,
                              ACFacebookPermissionsKey: @[@"email"],
                              //ACFacebookAudienceKey: ACFacebookAudienceFriends
                              };
    
    __weak IOAuth *weakSelf = self;
    [self.accountStore requestAccessToAccountsWithType:facebookAccountType options:options completion:^(BOOL granted, NSError *error) {
        if (granted)
        {
            NSArray *accounts = [weakSelf.accountStore accountsWithAccountType:facebookAccountType];
            ACAccount *facebookAccount = [accounts lastObject];
            ACAccountCredential *facebookCredential = [facebookAccount credential];
            NSString *facebookAccessToken = [[facebookCredential oauthToken] copy];
            if (!facebookAccessToken)
            {
                errorBlock([NSError errorWithDomain:@"requestFacebookAccessToken" code:400 userInfo:@{NSLocalizedDescriptionKey: @"Unable to get a proper Facebook access token"}]);
            }
            else
            {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                    [RMAPI logInFacebookWithAccessToken:facebookAccessToken completionBlock:completionBlock errorBlock:^(NSError *error, NSInteger statusCode) {
                        errorBlock(error);
                    }];
                });
            }
        }
        else
        {
            NSString *message;
            / *
typedef enum ACErrorCode {
    ACErrorUnknown = 1,
    ACErrorAccountMissingRequiredProperty,  // Account wasn't saved because it is missing a required property.
    ACErrorAccountAuthenticationFailed,     // Account wasn't saved because authentication of the supplied credential failed.
    ACErrorAccountTypeInvalid,              // Account wasn't saved because the account type is invalid.
    ACErrorAccountAlreadyExists,            // Account wasn't added because it already exists.
    ACErrorAccountNotFound,                 // Account wasn't deleted because it could not be found.
    ACErrorPermissionDenied,                // The operation didn't complete because the user denied permission.
    ACErrorAccessInfoInvalid                // The client's access info dictionary has incorrect or missing values.
} ACErrorCode;
             * /
            switch (error.code) {
                case ACErrorAccountNotFound:
                        message = NSLocalizedString(@"You haven't installed a Facebook Account to your device", @"Shows when the user tries to log in with Facebook, but the device doesn't have a Facebook account setup to use");
                    break;
                    
                case ACErrorPermissionDenied:
                        message = NSLocalizedString(@"You didn't provide access to your Facebook Account. Please, go to your Settings app and allow it from the Privacy tab", @"Shows when the user tries to log in with Facebook, but the app is disallowed access to the account");
                    break;
                    
                default:
                        message = NSLocalizedString(@"Something went wrong trying to connect to Facebook. Please, try again later", @"Shows when something unknown happened when the user tries to connect through Facebook");
                    break;
            }
     
            DDLogError(@"%@: ERROR while authenticating with Facebook [%d]: %@", self.class, error.code, error.localizedDescription);
            errorBlock([NSError errorWithDomain:@"requestFacebookAccessToken" code:error.code userInfo:@{NSLocalizedDescriptionKey: message}]);
        }
    }];
}
*/

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Remote data

- (void)updateRemoteData:(IOAuthSuccessBlock)completionBlock forcedFetch:(BOOL)forcedFetch
{
    logmethod();
    __weak __typeof(self)weakSelf = self;
    NSBlockOperation *doneOperation = [NSBlockOperation blockOperationWithBlock:^{
        DDLogVerbose(@"%@: All remote data is updated.", weakSelf.class);
        
        DDLogVerbose(@"%@: Doing persistent store save.", weakSelf.class);
        [[IOCoreDataHelper sharedInstance] backgroundSaveContext];
        
        [weakSelf isCurrentUserAuthenticated];
        
        completionBlock(YES, nil);
    }];
    
    NSOperationQueue *queue = self.pendingOperations.queue;
    
    /*
     * NOTE:
     * We could simply enqueue the updateCurrentUserAttributesForced: operation,
     * but that will enqueue the dependent operations with forcedFetch flag of
     * NO. So, we are enqueueing them all here, to be able to set the
     * forcedFetch flag.
     */
    NSOperation *updateSightingAttributesOperation = [self.pendingOperations updateSightingAttributesForced:forcedFetch];
    [doneOperation addDependency:updateSightingAttributesOperation];
    
    NSOperation *updateCategoriesOperation = [self.pendingOperations updateCategoriesForced:forcedFetch];
    [doneOperation addDependency:updateCategoriesOperation];
    
    NSOperation *updateRegionsOperation = [self.pendingOperations updateRegionsForced:forcedFetch];
    [doneOperation addDependency:updateRegionsOperation];
    
    NSOperation *updateSpeciesOperation = [self.pendingOperations updateSpeciesForced:forcedFetch];
    [doneOperation addDependency:updateSpeciesOperation];
    
    NSOperation *updateCurrentUserAttributesOperation = [self.pendingOperations updateCurrentUserAttributesForced:forcedFetch];
    [doneOperation addDependency:updateCurrentUserAttributesOperation];
    
    // Finally add the done operation
    [queue addOperation:doneOperation];
    
#warning NOTE TO SELF: below code is just a reminder to handle error code 3 for the sighting attributes
    /*
    [weakSelf updateRemoteSightingAttributes:^(BOOL success, NSError *error) {
        if (!success && error.code != 3)
        {
            if (completionBlock)
                completionBlock(NO, error);
            return;
        }
     */
}

////////////////////////////////////////////////////////////////////////////////
- (void)publishSighting:(NSManagedObjectID *)sightingID
{
    logmethod();
    DDLogVerbose(@"%@: Publishing a sighting", self.class);
    
    if (!self.currentUser || !self.currentUser.authToken)
    {
        DDLogError(@"%@: ERROR. No current user or valid auth token.", self.class);
        return;
    }
    
    [self.pendingOperations checkAndUploadAPendingSightingWihtID:sightingID showingUploadProgress:YES];
}

////////////////////////////////////////////////////////////////////////////////
- (void)checkForPengingSightingsToUpload
{
    logmethod();
    DDLogVerbose(@"%@: Checking for pending sightings to upload", self.class);
    
    [self.pendingOperations checkAndUploadAPendingSightingWihtID:nil showingUploadProgress:NO];
}

/*
 NOTE: this method is not used anymore, since we are attaching a sighting to a user just before it gets sent to the server
- (void)attachStraySightingsToCurrentUser
{
    DDLogVerbose(@"%@: Attaching stray sightings to user", self.class);
    
    NSManagedObjectContext *context = [[IOCoreDataHelper sharedInstance] context];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Sighting"];
    
    NSPredicate *statePredicate = [NSPredicate predicateWithFormat:@"(status == %@)", @(IOSightingStatusSaved)];
    NSPredicate *userPredicate = [NSPredicate predicateWithFormat:@"(user.userID == %@)", 0];
    NSPredicate *filterPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[statePredicate, userPredicate]];
    fetchRequest.predicate = filterPredicate;
    
    NSError *fetchError = nil;
    NSArray *result = [context executeFetchRequest:fetchRequest error:&fetchError];
    if (fetchError)
    {
        DDLogError(@"%@: ERROR fetching sightings. [%d]: %@", self.class, fetchError.code, fetchError.localizedDescription);
        return;
    }
    
    if (result.count > 0)
    {
        DDLogVerbose(@"%@: Found %d stray sightings", self.class, result.count);
        
        for (Sighting *sighting in result)
        {
            sighting.user = self.currentUser;
            [IOCoreDataHelper faultObjectWithID:sighting.objectID inContext:context];
        }
        
        [self.pendingOperations checkAndUploadAPendingSightingWihtID:nil showingUploadProgress:NO];
    }
}
 */

- (void)updateCurrentUserAttributes
{
    logmethod();
    //[self.pendingOperations.updateCurrentUserAttributesOperation cancel];
    if (!self.pendingOperations.updateCurrentUserAttributesOperation.isExecuting)
        [self.pendingOperations updateCurrentUserAttributesForced:YES];
}

@end
