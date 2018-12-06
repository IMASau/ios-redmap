//
//  IOAuth.h
//  RedMap
//
//  Created by Evo Stamatov on 25/06/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IOAuth-defines.h"
#import "IOAuthController.h"                                                    // includes the View Controller stack, so no need to import it as well - simply instantiate it [[IOAuthController alloc] initFromStoryboard];

extern NSString *const IOAuthErrorDomain;

extern NSString *const IOAuthRemoveUserNotification;

extern NSString *const IOAuthExceptionMissingValue;
extern NSString *const IOAuthExceptionValueLengthTooShort;
extern NSString *const IOAuthExceptionValueLengthTooLong;

typedef void (^IOAuthSuccessBlock) (BOOL success, NSError *error);
typedef void (^IOAuthErrorBlock) (NSError *error);

typedef enum {
    IOAuthErrorCodeUnknownError,
    IOAuthErrorCodeEmptyFacebookAccessToken,
    IOAuthErrorCodeFacebookSessionExpired,
} IOAuthErrorCode;

extern NSString *const IOSightingValidationErrorUserInfoLocalizedErrorsKey;
typedef enum {
    IOSightingValidationFieldErrorNoError                   = (0x1 << 0),
    IOSightingValidationFieldErrorNoSighting                = (0x1 << 1),
    // Nil or no values
    IOSightingValidationFieldErrorRegionNotSet              = (0x1 << 2),
    IOSightingValidationFieldErrorSpeciesNotSet             = (0x1 << 3),
    IOSightingValidationFieldErrorDateSpottedNotSet         = (0x1 << 4),
    IOSightingValidationFieldErrorTimeSpottedNotSet         = (0x1 << 5),
    IOSightingValidationFieldErrorLocationNotSet            = (0x1 << 6),
    IOSightingValidationFieldErrorActivityNotSet            = (0x1 << 7),
    IOSightingValidationFieldErrorSpeciesCountNotSet        = (0x1 << 8),
    IOSightingValidationFieldErrorSpeciesSexNotSet          = (0x1 << 9),
    // Off Ranges
    IOSightingValidationFieldErrorPhotosCountTooLow         = (0x1 << 10),
    IOSightingValidationFieldErrorDepthTooHigh              = (0x1 << 11),
    IOSightingValidationFieldErrorSpeciesLengthTooHigh      = (0x1 << 12),
    IOSightingValidationFieldErrorSpeciesWeightTooHigh      = (0x1 << 13),
    IOSightingValidationFieldErrorWaterTemperatureTooHigh   = (0x1 << 14),
//    IOSightingValidationFieldErrorXXX                       = (0x1 << 15),
} IOSightingValidationFieldError;

extern CGFloat const maxDepth;// = 10923.0f; // metres
extern CGFloat const maxSpeciesLength;// = 3500.0f; // centimetres
extern CGFloat const maxSpeciesWeight;// = 190000.0f; // kilograms
extern CGFloat const maxWaterTemperature;// = 120.0f; // degrees Celsius

@class User;
@class Sighting;


@interface IOAuth : NSObject

// CLASS METHODS
// -------------
+ (IOAuth *)sharedInstance;                                                     // a singular instance of the Class

// Validations
+ (BOOL)validateUsername:(NSString *)string andSkipMinumunLengthCheck:(BOOL)skipMinimumLengthCheck error:(NSError **)error; // validates a username to conform to the rules with an option to skip the minimum length check
+ (BOOL)validatePassword:(NSString *)string error:(NSError **)error;            // validates a password to conform the rules
+ (BOOL)validateEmail:(NSString *)string andSkipMinumunLengthCheck:(BOOL)skipMinimumLengthCheck error:(NSError **)error; // validates an email to conform to the rules with an option to skip the minimum length check
+ (BOOL)validateRegion:(NSString *)string error:(NSError **)error;              // validates a region name to conform the rules

/*!
 * Validates a sighting to conform the RedmapAPI rules.
 *
 * Returns YES if the sighting is valid for RedmapAPI submission.
 *
 * If NO and error ref is set, then error.userInfo will contain a localized
 * description under the NSLocalizedDescriptionKey key and localized
 * descriptions for all errors found, under the 
 * IOSightingValidationErrorUserInfoLocalizedErrorsKey key.
 */
+ (BOOL)validateSightingForSubmission:(Sighting *)sighting error:(NSError **)error;
+ (BOOL)validateSightingObjectForSubmission:(NSManagedObjectID *)sightingID context:(NSManagedObjectContext *)context error:(NSError **)error;

// INSTANCE METHODS AND PROPERTIES (can use [IOAuth sharedInstance] to access them)
// -------------------------------

// Current User
@property (nonatomic, strong, readonly) User *currentUser;                      // lazily fetches the last record in the Users table (should be only one)
- (BOOL)hasCurrentUser;                                                         // simply checks if currentUser is nil
- (BOOL)isCurrentUserAuthenticated;                                             // checks if the current user status is authenticated with the server
- (void)removeCurrentUser;                                                      // remove the current user's record

// Authentication and Registration
- (void)reAuthenticateCurrentUserWithCompletionBlock:(IOAuthSuccessBlock)completionBlock;

// Internally used methods by IOAuthLoginViewController
- (void)registerUserWithUsername:(NSString *)username
                        password:(NSString *)password
                       firstName:(NSString *)firstName
                        lastName:(NSString *)lastName
                           email:(NSString *)email
                 joinMailingList:(BOOL)joinMailingList
                      regionName:(NSString *)regionName
                 completionBlock:(IOAuthSuccessBlock)completionBlock;           // sets -currentUser to this new user

- (void)loginUserWithUsername:(NSString *)username
                     password:(NSString *)password
              completionBlock:(IOAuthSuccessBlock)completionBlock;              // sets -currentUser to this new user

- (void)registerUserFromFacebookWithCompletionBlock:(IOAuthSuccessBlock)completionBlock;

// TODO: move to separate class
- (void)updateRemoteData:(IOAuthSuccessBlock)completionBlock forcedFetch:(BOOL)forcedFetch;

// TODO: move to separate class
- (void)publishSighting:(NSManagedObjectID *)sightingID;

@end
