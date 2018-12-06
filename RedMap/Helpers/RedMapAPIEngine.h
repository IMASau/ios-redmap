//
//  RedMapAPIEngine.h
//  RedMap
//
//  Created by Evo Stamatov on 26/03/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "MKNetworkKit.h"

typedef void (^chunkBlock) (NSArray *chunk, BOOL hasMore, NSInteger total, BOOL cached);
typedef void (^errorBlock) (NSError *error, NSInteger statusCode);
typedef void (^authBlock) (NSString *authToken, NSError *error);

extern NSString *const RMAPIErrorDomain;

typedef enum {
    RMAPIErrorCodeUnknownErrorSuccess,
    RMAPIErrorCodeUnknownErrorFail,
    RMAPIErrorCodeUnknownHTTPStatusCode,
    RMAPIErrorCodeMismatchedFacebookAccessToken,
    RMAPIErrorCodeMissingAuthToken,
    RMAPIErrorCodeBrokenAuthToken,
    RMAPIErrorCodeFacebookSessionExpired,
    RMAPIErrorCodeFacebookEmailNotVerified,
} RMAPIErrorCode;

extern NSString *const RMAPIErrorUserInfoOriginalErrorKey;
extern NSString *const RMAPIErrorUserInfoOriginalExceptionKey;
extern NSString *const RMAPIErrorUserInfoRemoteOperationKey;

extern NSString *const RMAPIExceptionMissingValue;
extern NSString *const RMAPIExceptionBadResponse;

#define RMAPI ([RedMapAPIEngine sharedInstance])

@interface RedMapAPIEngine : MKNetworkEngine

// Make sure to init before using the sharedInstance or RMAPI macro!
- (id)initWithServerBase:(NSString *)serverBaseOrNil apiPath:(NSString *)apiPathOrNil andPort:(NSNumber *)portOrNil;
+ (RedMapAPIEngine *)sharedInstance;
//+ (NSString *)serverURLWithPath:(NSString *)path;

// Data requests
- (NSOperation *)requestSightingAttributes:(void (^)(NSDictionary *attributes))completionBlock errorBlock:(errorBlock)errorBlock;
- (NSOperation *)requestCategories:(chunkBlock)completionBlock errorBlock:(errorBlock)errorBlock;
//- (void)requestSpeciesForCategoryUrl:(NSString *)url completionBlock:(chunkBlock)completionBlock errorBlock:(errorBlock)errorBlock;
- (NSOperation *)requestSpecies:(chunkBlock)completionBlock errorBlock:(errorBlock)errorBlock;
- (NSOperation *)requestRegions:(chunkBlock)completionBlock errorBlock:(errorBlock)errorBlock;
- (NSOperation *)requestUserSightingByID:(NSInteger)sightingID authToken:(NSString *)authToken completionBlock:(void (^)(NSDictionary *sighting))completionBlock errorBlock:(errorBlock)errorBlock;

// Login
- (void)logInUser:(NSString *)username
         password:(NSString *)password
  completionBlock:(authBlock)completionBlock
       errorBlock:(errorBlock)errorBlock;

- (void)logInFacebookWithAccessToken:(NSString *)facebookAccessToken
                     completionBlock:(authBlock)completionBlock
                          errorBlock:(errorBlock)errorBlock;

// Register
- (void)registerUser:(NSString *)username
            password:(NSString *)password
           firstName:(NSString *)firstName
            lastName:(NSString *)lastName
               email:(NSString *)email
     joinMailingList:(BOOL)joinMailingList
          regionName:(NSString *)regionName
     completionBlock:(authBlock)completionBlock
          errorBlock:(errorBlock)errorBlock;

// User details
- (NSOperation *)getUserDetailsUsingAuthToken:(NSString *)authToken completionBlock:(void (^)(NSDictionary *details, NSError *error))completionBlock;

// Sightings
- (NSOperation *)sendASightingUsingAuthToken:(NSString *)authToken
                                    accuracy:(NSDictionary *)accuracy
                                    activity:(NSDictionary *)activity
                                       count:(NSDictionary *)count
                                       depth:(NSInteger)depth
                                     habitat:(NSDictionary *)habitat
                                    latitude:(double)latitude
                                   longitude:(double)longitude
                                       notes:(NSString *)notes
                       otherSpeciesLatinName:(NSString *)otherSpeciesLatinName
                      otherSpeciesCommonName:(NSString *)otherSpeciesCommonName
                                photoCaption:(NSString *)photoCaption
                                    photoURL:(NSURL *)photoURL
                                         sex:(NSDictionary *)sex
                                sightingDate:(NSDate *)sightingDate
                                        size:(NSInteger)size
                                  sizeMethod:(NSDictionary *)sizeMethod
                                     species:(NSDictionary *)species
                                        time:(NSDictionary *)time
                            waterTemperature:(NSInteger)waterTemperature
                                      weight:(CGFloat)weight
                                weightMethod:(NSDictionary *)weightMethod
                            onUploadProgress:(void (^)(double progress))onUploadProgress
                             completionBlock:(void (^)(NSDictionary *sightingObj, NSError *error))completionBlock;

@end

