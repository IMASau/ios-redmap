//
//  RedMapAPIEngine.m
//  RedMap
//
//  Created by Evo Stamatov on 26/03/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "RedMapAPIEngine.h"
#import "IOSightingAttributesController.h"

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

NSString *const RMAPIErrorDomain = @"au.org.redmap.api.errors";
NSString *const RMAPIErrorUserInfoOriginalErrorKey = @"OriginalError";
NSString *const RMAPIErrorUserInfoOriginalExceptionKey = @"OriginalException";
NSString *const RMAPIErrorUserInfoRemoteOperationKey = @"RemoteOperation";

NSString *const RMAPIExceptionMissingValue = @"RMAPIExceptionMissingValue";
NSString *const RMAPIExceptionBadResponse = @"RMAPIExceptionBadResponse";

@interface RedMapAPIEngine ()

@property (strong, nonatomic) NSMutableDictionary *requestsCache;
@property (nonatomic, strong) NSOperationQueue *localQueue;

@end

@implementation RedMapAPIEngine

__strong static id _instance = nil;

+ (RedMapAPIEngine *)sharedInstance
{
    if (_instance == nil)
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"You should initialize the RedMapAPIEngine with initWithServerBase:apiPath:apiPathOrNil:andPort:" userInfo:nil];
    
    return _instance;
}



- (NSOperationQueue *)localQueue
{
    if (!_localQueue)
    {
    logmethod();
        _localQueue = [[NSOperationQueue alloc] init];
        _localQueue.name = @"Local RedMapAPIEngine queue";
        _localQueue.maxConcurrentOperationCount = 1;
    }
    
    return _localQueue;
}



- (id)initWithServerBase:(NSString *)serverBaseOrNil apiPath:(NSString *)apiPathOrNil andPort:(NSNumber *)portOrNil
{
    if (!serverBaseOrNil)
        serverBaseOrNil = API_BASE;
    
    self = [super initWithHostName:serverBaseOrNil customHeaderFields:@{
            @"x-client-identifier": @"iOS",
            @"Cookie": @""
            }];
    
    if (self)
    {
    logmethod();
        
#ifdef API_PORT
        if (!portOrNil)
            portOrNil = @(API_PORT);
#endif
        if (portOrNil)
            self.portNumber = [portOrNil intValue];
        
#ifdef API_PATH
        if  (!apiPathOrNil)
            apiPathOrNil = API_PATH;
#endif
        if (apiPathOrNil)
            self.apiPath = apiPathOrNil;
        
        _requestsCache = [NSMutableDictionary dictionary];
    }
    
    _instance = self;
    return self;
}


/*
- (MKNetworkOperation *)operationWithPath:(NSString *)path params:(NSDictionary *)body httpMethod:(NSString *)method ssl:(BOOL)useSSL
{
    IOLog(@"Redmap API call for path: %@", path);
    return [super operationWithPath:path params:body httpMethod:method ssl:useSSL];
}
 */


#pragma mark - RedMap API
#pragma mark Private Methods

- (MKNetworkOperation *)requestRemoteJSON:(NSString *)path
                                   params:(NSDictionary *)params
                        completionHandler:(void (^)(NSDictionary *dict))completionBlock
                             errorHandler:(errorBlock)errorBlock
{
    logmethod();
    // Make sure the request format is set to JSON
    NSMutableDictionary *newParams = [NSMutableDictionary dictionaryWithDictionary:params];
    [newParams setObject:@"json" forKey:@"format"];

    MKNetworkOperation *op;
#if defined(USE_SSL) && USE_SSL == 1
    op = [self operationWithPath:path params:newParams httpMethod:@"GET" ssl:YES];
#else
    op = [self operationWithPath:path params:newParams httpMethod:@"GET"];
#endif
    
//    [op setPostDataEncoding:MKNKPostDataEncodingTypeJSON];
    
    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        NSDictionary *result = (NSDictionary *)[completedOperation responseJSON];
        completionBlock(result);
    } errorHandler:^(MKNetworkOperation *errorOperation, NSError *error) {
        NSInteger statusCode = [errorOperation HTTPStatusCode];
        errorBlock(error, statusCode);
    }];

    [self enqueueOperation:op];
    
    return op;
}



- (NSOperation *)requestResultsForPath:(NSString *)path
                       atPage:(NSUInteger)index
              completionBlock:(chunkBlock)completionBlock
                   errorBlock:(errorBlock)errorBlock
{
    logmethod();
    NSString *cacheKey = [NSString stringWithFormat:@"recursive-%@%u", path, index];
    if ([self.requestsCache objectForKey:cacheKey])
    {
        DDLogVerbose(@"%@: Hitting cache for cacheKey %@", self.class, cacheKey);
        
        NSArray *cacheData = [self.requestsCache objectForKey:cacheKey];
        completionBlock([cacheData objectAtIndex:0], [[cacheData objectAtIndex:1] boolValue], [[cacheData objectAtIndex:2] integerValue], YES);
        NSBlockOperation *blockOp = [NSBlockOperation blockOperationWithBlock:^{
            // hitting cache
        }];
        return (NSOperation *)blockOp;
    }
    
    NSDictionary *params = @{
                             @"page": @(index),
                             };

    __weak RedMapAPIEngine *weakSelf = self;
    return (NSOperation *)[self requestRemoteJSON:path params:params completionHandler:^(NSDictionary *dict)
    {
        NSArray *results = (NSArray *)[dict objectForKey:@"results"];
        
        id next = [dict objectForKey:@"next"];
        BOOL hasNext = next != [NSNull null];
        
        NSInteger count = [[dict objectForKey:@"count"] integerValue];
        
        [weakSelf.requestsCache setObject:@[results, @(hasNext), @(count)] forKey:cacheKey];
        
        completionBlock(results, hasNext, count, NO);
    } errorHandler:errorBlock];
}



- (void)requestRecursiveResultsForPath:(NSString *)path
                               forPage:(NSUInteger)page
                       completionBlock:(chunkBlock)completionBlock
                            errorBlock:(errorBlock)errorBlock
{
    logmethod();
    __weak RedMapAPIEngine *weakSelf = self;
    [self requestResultsForPath:path atPage:page completionBlock:^(NSArray *results, BOOL hasNext, NSInteger total, BOOL cached) {
        completionBlock(results, hasNext, total, cached);
        
        if (hasNext)
            [weakSelf requestRecursiveResultsForPath:path forPage:page + 1 completionBlock:completionBlock errorBlock:errorBlock];
    } errorBlock:errorBlock];
}



- (NSOperation *)requestRecursiveResultsForPath:(NSString *)path
                       completionBlock:(chunkBlock)completionBlock
                            errorBlock:(errorBlock)errorBlock
{
    logmethod();
    // Create a operation wrapper
    NSBlockOperation *blockOperation = [NSBlockOperation blockOperationWithBlock:^{
        // http://omegadelta.net/2011/05/10/how-to-wait-for-ios-methods-with-completion-blocks-to-finish/
        
        // Do a synchronous request
        NSConditionLock *requestLock = [[NSConditionLock alloc] initWithCondition:1];
        
        [self requestRecursiveResultsForPath:path forPage:1 completionBlock:^(NSArray *chunk, BOOL hasMore, NSInteger total, BOOL cached) {
            if (completionBlock)
                completionBlock(chunk, hasMore, total, cached);
            
            if (!hasMore)
            {
                [requestLock lock];
                [requestLock unlockWithCondition:0];
            }
        } errorBlock:^(NSError *error, NSInteger statusCode) {
            if (errorBlock)
                errorBlock(error, statusCode);
            
            [requestLock lock];
            [requestLock unlockWithCondition:0];
        }];
        
        [requestLock lockWhenCondition:0];
        [requestLock unlock];
    }];
    
    __weak RedMapAPIEngine *weakSelf = self;
    blockOperation.completionBlock = ^{
        // Release the local queue
        weakSelf.localQueue = nil;
    };
    
    // Load the operation into the local queue
    [self.localQueue addOperation:blockOperation];
    
    return (NSOperation *)blockOperation;
}



#pragma mark Fetch data

- (NSOperation *)requestSightingAttributes:(void (^)(NSDictionary *attributes))completionBlock errorBlock:(errorBlock)errorBlock
{
    logmethod();
    NSString *path = @"sighting/options/";
    
    MKNetworkOperation *op;
#if defined(USE_SSL) && USE_SSL == 1
    op = [self operationWithPath:path params:nil httpMethod:@"GET" ssl:YES];
#else
    op = [self operationWithPath:path params:nil httpMethod:@"GET"];
#endif
    
    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        NSInteger statusCode = [completedOperation HTTPStatusCode];
        NSDictionary *result = (NSDictionary *)[completedOperation responseJSON];
        
        __block NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
        NSDictionary *expectedAttributes = @{
                                       @"count":         @"count",
                                       @"size_method":   @"sizeMethod",
                                       @"habitat":       @"habitat",
                                       @"activity":      @"activity",
                                       @"sex":           @"sex",
                                       @"weight_method": @"weightMethod",
                                       @"time":          @"time",
                                       @"accuracy":      @"accuracy",
                                       };
        __block NSError *error = nil;
        [expectedAttributes enumerateKeysAndObjectsUsingBlock:^(id aKey, id aObj, BOOL *stop) {
            NSString *key = (NSString *)aKey;
            NSString *plistKey = (NSString *)aObj;
            
            @try {
                if (!result[key])
                    @throw [NSException exceptionWithName:RMAPIExceptionMissingValue reason:@"Missing Attribute" userInfo:nil];
                
                NSArray *values = result[key];
                
                __block NSMutableArray *compiledValues = [[NSMutableArray alloc] initWithCapacity:[values count]];
                // dig deeper into the values
                [values enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    NSUInteger pk = [obj[@"pk"] integerValue];
                    // dig even deeper into the values' fields
                    NSDictionary *fields = obj[@"fields"];
                    NSString *desc = fields[@"description"];
                    NSString *code = fields[@"code"];
                    if (code == nil)
                        code = fields[@"slug"];
                    NSDictionary *value = @{
                                            @"id": @(pk),
                                            @"code": code == nil ? [NSNull null] : code,
                                            @"title": desc,
                                            };
                    [compiledValues addObject:value];
                }];
                attributes[plistKey] = compiledValues;
            }
            @catch (NSException *exception) {
                *stop = YES;
                error = [NSError errorWithDomain:@"requestSightingAttributes" code:1 userInfo:@{NSLocalizedDescriptionKey: [exception reason]}];
            }
        }];
        
        if (error)
            errorBlock(error, statusCode);
        else
            completionBlock(attributes);
    } errorHandler:^(MKNetworkOperation *errorOperation, NSError *error) {
#if TRACK
        NSDictionary *result;
        @try {
            result = (NSDictionary *)[errorOperation responseJSON];
        }
        @catch (NSException *exception) {
        }
        @finally {
            [GoogleAnalytics sendEventWithCategory:@"admin-notification"
                                                              withAction:[NSString stringWithCString:__PRETTY_FUNCTION__ encoding:NSASCIIStringEncoding]
                                                               withLabel:[NSString stringWithFormat:@"Error: %@; Result: %@;", error.localizedDescription, [result description]]
                                                               withValue:@(error.code)];
        }
#endif
        NSInteger statusCode = [errorOperation HTTPStatusCode];
        errorBlock(error, statusCode);
    }];

    [self enqueueOperation:op];
    
    return op;
}



- (NSOperation *)requestCategories:(chunkBlock)completionBlock errorBlock:(errorBlock)errorBlock
{
    logmethod();
    NSString *path = @"category/";
    return [self requestRecursiveResultsForPath:path completionBlock:completionBlock errorBlock:errorBlock];
}



/*
- (void)requestSpeciesForCategoryUrl:(NSString *)url completionBlock:(chunkBlock)completionBlock errorBlock:(errorBlock)errorBlock
{
    NSString *path = @"species/";
    NSString *categoryUrl = [url copy];
    
    [self requestRecursiveResultsForPath:path completionBlock:^(NSArray *results, BOOL hasMore, NSInteger total, BOOL cached) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%@ in category_list", categoryUrl];
        NSArray *filteredSpecies = [results filteredArrayUsingPredicate:predicate];
        completionBlock(filteredSpecies, hasMore, total, cached);
    } errorBlock:errorBlock];
}
 */



- (NSOperation *)requestSpecies:(chunkBlock)completionBlock errorBlock:(errorBlock)errorBlock
{
    logmethod();
    NSString *path = @"species/";
    return (NSOperation *)[self requestRecursiveResultsForPath:path completionBlock:completionBlock errorBlock:errorBlock];
}



- (NSOperation *)requestRegions:(chunkBlock)completionBlock errorBlock:(errorBlock)errorBlock
{
    logmethod();
    NSString *path = @"region/";
    return (NSOperation *)[self requestRecursiveResultsForPath:path completionBlock:completionBlock errorBlock:errorBlock];
}



- (NSOperation *)requestUserSightingByID:(NSInteger)sightingID authToken:(NSString *)authToken completionBlock:(void (^)(NSDictionary *sighting))completionBlock errorBlock:(errorBlock)errorBlock
{
    logmethod();
    NSString *path = [NSString stringWithFormat:@"user/sighting/%d", sightingID];
    
    MKNetworkOperation *op;
#if defined(USE_SSL) && USE_SSL == 1
    op = [self operationWithPath:path params:nil httpMethod:@"GET" ssl:YES];
#else
    op = [self operationWithPath:path params:nil httpMethod:@"GET"];
#endif
    
    [op setAuthorizationHeaderValue:[authToken copy] forAuthType:@"Token"];
    
    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        NSInteger statusCode = [completedOperation HTTPStatusCode];
        if (statusCode == 200)
        {
            NSDictionary *result = (NSDictionary *)[completedOperation responseJSON];
            
            @try {
                // NSAssert([result objectForKey:@"id"] != 0, @"Sighting ID is missing");
                // NSAssert([result objectForKey:@"url"] != nil, @"Sighting URL is missing");
                
                if ([result[@"id"] intValue] == 0)
                    @throw [NSException exceptionWithName:RMAPIExceptionMissingValue reason:@"Malformed response. No Sighting ID." userInfo:nil];
                if (result[@"url"] == nil)
                    @throw [NSException exceptionWithName:RMAPIExceptionMissingValue reason:@"Malformed response. No Sighting URL." userInfo:nil];
                
                // TODO: assert for:
                // species
                // other_species
                // is_published
                // region
                // update_time
                // category_list[]
                
                // latitude
                // longitude
                // accuracy ID
                // is_valid_sighting
                // logging_date
                
                completionBlock(result);
            }
            @catch (NSException *exception) {
                NSString *description = [exception reason];
                errorBlock([NSError errorWithDomain:@"getUserSightingDetailsUsingAuthToken" code:2 userInfo:@{NSLocalizedDescriptionKey: description}], statusCode);
            }
        }
        else
        {
            NSString *description = NSLocalizedString(@"Unable to authenticate", @"When fetching a user sighting details with an auth_token");
            NSError *error = [NSError errorWithDomain:@"getUserSightingDetailsUsingAuthToken" code:1 userInfo:@{NSLocalizedDescriptionKey: description}];
            errorBlock(error, statusCode);
        }
    } errorHandler:^(MKNetworkOperation *errorOperation, NSError *error) {
#if TRACK
        NSDictionary *result;
        @try {
            result = (NSDictionary *)[errorOperation responseJSON];
        }
        @catch (NSException *exception) {
        }
        @finally {
            [GoogleAnalytics sendEventWithCategory:@"admin-notification"
                                                              withAction:[NSString stringWithCString:__PRETTY_FUNCTION__ encoding:NSASCIIStringEncoding]
                                                               withLabel:[NSString stringWithFormat:@"Error: %@; Result: %@;", error.localizedDescription, [result description]]
                                                               withValue:@(error.code)];
        }
#endif
        NSInteger statusCode = [errorOperation HTTPStatusCode];
        errorBlock(error, statusCode);
    }];

    [self enqueueOperation:op];
    
    return op;
}



#pragma mark Login

- (void)logInUser:(NSString *)username
         password:(NSString *)password
  completionBlock:(authBlock)completionBlock
       errorBlock:(errorBlock)errorBlock
{
    logmethod();
    NSString *errorDomain = @"logInUser";
    if (!self.isReachable)
    {
        errorBlock([NSError errorWithDomain:errorDomain code:106 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Internet disconnected. Unable to reach the server", @"Authentication fails, because there is no active internet connection")}], 106);
        return;
    }
    
    // Make sure the request format is set to JSON
    NSDictionary *params = @{
                             @"username": username,
                             @"password": password,
                             @"format": @"json"
                             };

    NSString *path = @"user/api-token-auth/";
    
    MKNetworkOperation *op;
#if defined(USE_SSL) && USE_SSL == 1
    op = [self operationWithPath:path params:params httpMethod:@"POST" ssl:YES];
#else
    op = [self operationWithPath:path params:params httpMethod:@"POST"];
#endif
    
//    [op setPostDataEncoding:MKNKPostDataEncodingTypeJSON];
    
    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        NSDictionary *result = (NSDictionary *)[completedOperation responseJSON];
        //NSInteger statusCode = [completedOperation HTTPStatusCode];
        //IOLog(@"Auth token result: %@", result);
        
        @try {
            NSString *authToken = [result objectForKey:@"token"];
            NSAssert(authToken != nil, @"Missing Auth Token value");
            NSAssert([authToken length] == 40, @"Broken Auth Token value");
            
            completionBlock(authToken, nil);
        }
        @catch (NSException *exception) {
            // IOLog(@"EXCEPTION: %@", [exception reason]);
#if TRACK
            [GoogleAnalytics sendEventWithCategory:@"admin-notification" withAction:@"login-user" withLabel:[exception reason] withValue:@1];
#endif
            NSError *properError = [NSError errorWithDomain:errorDomain code:400 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Did not receive valid token.", @"Authentication fails, because there is no valid token sent back from the server")}];
            errorBlock(properError, 200);
        }
    } errorHandler:^(MKNetworkOperation *errorOperation, NSError *error) {
        NSInteger statusCode = [errorOperation HTTPStatusCode];
        NSDictionary *result = (NSDictionary *)[errorOperation responseJSON];
#if TRACK
        //NSDictionary *result;
        @try {
            //result = (NSDictionary *)[errorOperation responseJSON];
        }
        @catch (NSException *exception) {
        }
        @finally {
            [GoogleAnalytics sendEventWithCategory:@"admin-notification"
                                                              withAction:[NSString stringWithCString:__PRETTY_FUNCTION__ encoding:NSASCIIStringEncoding]
                                                               withLabel:[NSString stringWithFormat:@"Error: %@; Result: %@;", error.localizedDescription, [result description]]
                                                               withValue:@(error.code)];
        }
#endif
        if (statusCode == 400)
        {
            id fieldErrors = [result objectForKey:@"non_field_errors"];
            id username = [result objectForKey:@"username"];
            id password = [result objectForKey:@"password"];
            
            NSError *properError;
            if (username || password)
                properError = [NSError errorWithDomain:errorDomain code:401 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Username and password are required to login.", @"Authentication fails, because username and/or password were not provided")}];
            else if (fieldErrors && [fieldErrors isKindOfClass:[NSArray class]])
            {
                NSArray *fieldErrorsArray = (NSArray *)fieldErrors;
                NSString *lastError = (NSString *)[fieldErrorsArray lastObject];
                if ([lastError isEqualToString:@"User account is disabled."])
                    properError = [NSError errorWithDomain:errorDomain code:402 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Your email account haven't been verified. Please open the activation email we've sent you and activate it.", @"Authentication fails, because user credentials were not verified")}];
                else
                    properError = [NSError errorWithDomain:errorDomain code:402 userInfo:@{NSLocalizedDescriptionKey: lastError}];
            }
            else
                properError = [NSError errorWithDomain:errorDomain code:403 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Couldn't log in. Please, try again later", @"Authentication fails, because of unknown error")}];
            errorBlock(properError, 400);
        }
        else {
            errorBlock(error, statusCode);
        }
    }];

    [self enqueueOperation:op];
    //return op;
}



- (void)logInFacebookWithAccessToken:(NSString *)facebookAccessToken
                     completionBlock:(authBlock)completionBlock
                          errorBlock:(errorBlock)errorBlock
{
    logmethod();
    NSDictionary *params = @{
                             @"access_token": facebookAccessToken
                             };
    
    NSString *path = @"user/register-facebook/";
    
    MKNetworkOperation *op;
#if defined(USE_SSL) && USE_SSL == 1
    op = [self operationWithPath:path params:params httpMethod:@"POST" ssl:YES];
#else
    op = [self operationWithPath:path params:params httpMethod:@"POST"];
#endif
    
//    [op setPostDataEncoding:MKNKPostDataEncodingTypeJSON];
    
    __weak __typeof(self)weakSelf = self;
    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        NSInteger statusCode = [completedOperation HTTPStatusCode];
        
        NSInteger errorCode = RMAPIErrorCodeUnknownErrorSuccess;
        if (statusCode == 201 || statusCode == 200) // created new or found old user
        {
            NSDictionary *result = [completedOperation responseJSON];
            NSString *authToken;
            
            @try {
                NSString *sentAccessToken = [result objectForKey:@"access_token"];
                if (![sentAccessToken isEqualToString:facebookAccessToken])
                {
                    errorCode = RMAPIErrorCodeMismatchedFacebookAccessToken;
                    NSString *reason = NSLocalizedString(@"Mismatched Facebook Access Token value", @"");
                    @throw [NSException exceptionWithName:RMAPIExceptionBadResponse reason:reason userInfo:nil];
                }
                
                authToken = [result objectForKey:@"auth_token"];
                if (authToken == nil)
                {
                    errorCode = RMAPIErrorCodeMissingAuthToken;
                    NSString *reason = NSLocalizedString(@"Missing Auth Token value", @"");
                    @throw [NSException exceptionWithName:RMAPIExceptionMissingValue reason:reason userInfo:nil];
                }
                if (authToken.length == 0)
                {
                    errorCode = RMAPIErrorCodeBrokenAuthToken;
                    NSString *reason = NSLocalizedString(@"Broken Auth Token value", @"");
                    @throw [NSException exceptionWithName:RMAPIExceptionBadResponse reason:reason userInfo:nil];
                }
                if (authToken.length != 40)
                {
                    errorCode = RMAPIErrorCodeBrokenAuthToken;
                    NSString *reason = NSLocalizedString(@"Broken Auth Token value", @"");
                    @throw [NSException exceptionWithName:RMAPIExceptionBadResponse reason:reason userInfo:nil];
                }
            }
            @catch (NSException *exception) {
                DDLogError(@"%@: EXCEPTION: %@, %@", weakSelf.class, exception.name, exception.reason);
                
#if TRACK
                [GoogleAnalytics sendEventWithCategory:@"admin-notification" withAction:@"login-facebook" withLabel:[exception reason] withValue:@1];
#endif
                NSDictionary *userInfo = @{
                                           NSLocalizedDescriptionKey: exception.reason ?: @"Unknown error",
                                           RMAPIErrorUserInfoOriginalExceptionKey: exception,
                                           RMAPIErrorUserInfoRemoteOperationKey: completedOperation ?: [NSNull null],
                                           };
                NSInteger errorCode = RMAPIErrorCodeUnknownErrorSuccess;
                NSError *properError = [NSError errorWithDomain:RMAPIErrorDomain code:errorCode userInfo:userInfo];
                errorBlock(properError, statusCode);
                return;
            }
            
            completionBlock(authToken, nil);
            return;
        }
        else
        {
            NSString *description = NSLocalizedString(@"Server login failed with unknown Status Code", @"");
            NSDictionary *userInfo = @{
                                       NSLocalizedDescriptionKey: description,
                                       };
            NSInteger errorCode = RMAPIErrorCodeUnknownHTTPStatusCode;
            NSError *properError = [NSError errorWithDomain:RMAPIErrorDomain code:errorCode userInfo:userInfo];
            errorBlock(properError, statusCode);
        }
        
    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        
        NSInteger statusCode = [completedOperation HTTPStatusCode];
        NSDictionary *result = [completedOperation responseJSON];
        
#if TRACK
        [GoogleAnalytics sendEventWithCategory:@"admin-notification"
                                                          withAction:[NSString stringWithCString:__PRETTY_FUNCTION__ encoding:NSASCIIStringEncoding]
                                                           withLabel:[NSString stringWithFormat:@"Error: %@; Result: %@;", error.localizedDescription, [result description]]
                                                           withValue:@(error.code)];
#endif
        
        if (result && [result isKindOfClass:[NSDictionary class]] && [result objectForKey:@"error"])
        {
            /*
             --------
             Response
             --------
             {"error": "Error validating access token: The session has been invalidated because the user has changed the password."}
             , [The operation couldn’t be completed. (NSURLErrorDomain error 401.)]
             */
            
            NSString *errorMessage = [result objectForKey:@"error"];
            NSString *description;
            NSInteger errorCode;
            
            if ([errorMessage isEqualToString:@"Error validating access token: The session has been invalidated because the user has changed the password."])
            {
                description = NSLocalizedString(@"Facebook session has expired.", @"");
                errorCode = RMAPIErrorCodeFacebookSessionExpired;
            }
            else if ([errorMessage hasPrefix:@"Error validating access token: Session has expired "])
            {
                description = NSLocalizedString(@"Facebook session has expired.", @"");
                errorCode = RMAPIErrorCodeFacebookSessionExpired;
            }
            else if ([errorMessage isEqualToString:@"Unverified facebook email address conflicts with an existing Redmap account"])
            {
                description = NSLocalizedString(@"Facebook e-mail address has not been verified with Facebook.", @"");
                errorCode = RMAPIErrorCodeFacebookEmailNotVerified;
            }
            else
            {
                errorCode = RMAPIErrorCodeUnknownErrorFail;
                description = NSLocalizedString(@"Server responded with an unknown error", @"");
            }
            NSDictionary *userInfo = @{
                                       NSLocalizedDescriptionKey: description,
                                       RMAPIErrorUserInfoOriginalErrorKey: error,
                                       RMAPIErrorUserInfoRemoteOperationKey: completedOperation ?: [NSNull null],
                                       };
            NSError *localError = [NSError errorWithDomain:RMAPIErrorDomain code:errorCode userInfo:userInfo];
            errorBlock(localError, statusCode);
        }
        else
            errorBlock(error, statusCode);
    }];
    
    [self enqueueOperation:op];
    //return op;
}



#pragma mark Registration

- (void)registerUser:(NSString *)username
            password:(NSString *)password
           firstName:(NSString *)firstName
            lastName:(NSString *)lastName
               email:(NSString *)email
     joinMailingList:(BOOL)joinMailingList
          regionName:(NSString *)regionName
     completionBlock:(authBlock)completionBlock
          errorBlock:(errorBlock)errorBlock
{
    logmethod();
    NSString *errorDomain = @"registerUser";
    if (!self.isReachable)
    {
        errorBlock([NSError errorWithDomain:errorDomain code:106 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Internet disconnected. Unable to reach the server", @"Authentication fails, because there is no active internet connection")}], 106);
        return;
    }
    
    username = username ?: @"";
    password = password ?: @"";
    firstName = firstName ?: @"";
    lastName = lastName ?: @"";
    email = email ?: @"";
    regionName = regionName ?: @"";
    
    NSDictionary *params = @{
                             @"username": username,
                             @"password": password,
                             @"first_name": firstName,
                             @"last_name": lastName,
                             @"email": email,
                             @"join_mailing_list": @(joinMailingList),
                             @"region": regionName,
                             @"format": @"json"
                             };
    
    NSString *path = @"user/register/";
    
    MKNetworkOperation *op;
#if defined(USE_SSL) && USE_SSL == 1
    op = [self operationWithPath:path params:params httpMethod:@"POST" ssl:YES];
#else
    op = [self operationWithPath:path params:params httpMethod:@"POST"];
#endif
    
//    [op setPostDataEncoding:MKNKPostDataEncodingTypeJSON];
    
    __weak RedMapAPIEngine *weakSelf = self;
    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        NSInteger statusCode = [completedOperation HTTPStatusCode];
        if (statusCode == 201) // created
        {
            NSDictionary *result = (NSDictionary *)[completedOperation responseJSON];
            
            @try {
                NSString *registeredUsername = [result objectForKey:@"username"];
                if (![registeredUsername isEqualToString:username])
                    @throw [NSException exceptionWithName:RMAPIExceptionBadResponse reason:@"Mismatched username value" userInfo:nil];
                
                NSString *registeredEmail = [result objectForKey:@"email"];
                if (![registeredEmail isEqualToString:email])
                    @throw [NSException exceptionWithName:RMAPIExceptionBadResponse reason:@"Mismatched email value" userInfo:nil];
                
                NSString *registeredFirstName = [result objectForKey:@"first_name"];
                if (![registeredFirstName isEqualToString:firstName])
                    @throw [NSException exceptionWithName:RMAPIExceptionBadResponse reason:@"Mismatched first name value" userInfo:nil];
                
                NSString *registeredLastName = [result objectForKey:@"last_name"];
                if (![registeredLastName isEqualToString:lastName])
                    @throw [NSException exceptionWithName:RMAPIExceptionBadResponse reason:@"Mismatched last name value" userInfo:nil];
                
                BOOL registeredJoinMailingList = [[result objectForKey:@"join_mailing_list"] boolValue];
                if (registeredJoinMailingList != joinMailingList)
                    @throw [NSException exceptionWithName:RMAPIExceptionBadResponse reason:@"Mismatched join mailing list value" userInfo:nil];
                
                NSString *registeredRegionName = [result objectForKey:@"region"];
                if (![registeredRegionName isEqualToString:regionName])
                    @throw [NSException exceptionWithName:RMAPIExceptionBadResponse reason:@"Mismatched region name value" userInfo:nil];
                
                [weakSelf logInUser:username password:password completionBlock:completionBlock errorBlock:errorBlock];
            }
            @catch (NSException *exception) {
                DDLogError(@"%@: EXCEPTION. %@: %@", weakSelf.class, exception.name, exception.reason);
                
#if TRACK
                [GoogleAnalytics sendEventWithCategory:@"admin-notification" withAction:@"register-user" withLabel:[exception reason] withValue:@1];
#endif
                NSError *properError = [NSError errorWithDomain:errorDomain code:201 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"We are experiencing some technical difficulties at the moment. Please, try again later", @"Registration fails, because the server returned mismatched values")}];
                errorBlock(properError, 201);
            }
        }
        else
        {
            NSError *properError = [NSError errorWithDomain:errorDomain code:statusCode userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"We are experiencing some technical difficulties at the moment. Please, try again later", @"Registration fails, because of server error")}];
            
            DDLogError(@"%@: ERROR while registering with the server. StatusCode: %d. [%d]: %@", weakSelf.class, statusCode, properError.code, properError.localizedDescription );
            
            errorBlock(properError, statusCode);
        }
    } errorHandler:^(MKNetworkOperation *errorOperation, NSError *error) {
        NSInteger statusCode = [errorOperation HTTPStatusCode];
        NSDictionary *result = (NSDictionary *)[errorOperation responseJSON];
        
#if TRACK
        [GoogleAnalytics sendEventWithCategory:@"admin-notification"
                                                          withAction:[NSString stringWithCString:__PRETTY_FUNCTION__ encoding:NSASCIIStringEncoding]
                                                           withLabel:[NSString stringWithFormat:@"Error: %@; Result: %@;", error.localizedDescription, [result description]]
                                                           withValue:@(error.code)];
#endif
        
        if (statusCode == 400)
        {
            id username = [result objectForKey:@"username"];
            id password = [result objectForKey:@"password"];
            id region = [result objectForKey:@"region"];
            id email = [result objectForKey:@"email"];
            
            NSError *properError;
            /*
            if (username || password)
                properError = [NSError errorWithDomain:errorDomain code:401 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Username and password are required to register.", @"Registration fails, because username and/or password were not provided")}];
            else */
            // TODO: handle when username or password are ommited somehow
            if (username)
            {
                NSArray *messages = (NSArray *)username;
                properError = [NSError errorWithDomain:errorDomain code:400 userInfo:@{NSLocalizedDescriptionKey: [messages objectAtIndex:0]}];
            }
            else if (password)
            {
                NSArray *messages = (NSArray *)password;
                properError = [NSError errorWithDomain:errorDomain code:401 userInfo:@{NSLocalizedDescriptionKey: [messages objectAtIndex:0]}];
            }
            else if (email)
            {
                NSArray *messages = (NSArray *)email;
                properError = [NSError errorWithDomain:errorDomain code:402 userInfo:@{NSLocalizedDescriptionKey: [messages objectAtIndex:0]}];
            }
            else if (region)
            {
                properError = [NSError errorWithDomain:errorDomain code:403 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"The selected Region is not one of the available choices.", @"Registration fails, because the provided region is not allowed")}];
            }
            else
                properError = [NSError errorWithDomain:errorDomain code:404 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Couldn't register. Please, try again later", @"Registration fails, because of unknown error")}];
            errorBlock(properError, 400);
        }
        else if (statusCode == 500)
        {
            NSError *properError = [NSError errorWithDomain:errorDomain code:500 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"We are experiencing some technical difficulties at the moment. Please, try again later", @"Registration fails, because of server error")}];
            errorBlock(properError, 500);
        }
        else
            errorBlock(error, statusCode);
    }];

    [self enqueueOperation:op];
    //return op;
}



#pragma mark Fetch user details

- (NSOperation *)getUserDetailsUsingAuthToken:(NSString *)authToken completionBlock:(void (^)(NSDictionary *details, NSError *error))completionBlock
{
    logmethod();
    if (!authToken || [authToken isEqualToString:@""])
    {
        NSString *description = NSLocalizedString(@"Authentication credentials were not provided.", @"When checking user details with no auth_token");
        NSError *error = [NSError errorWithDomain:@"getUserDetailsUsingAuthToken" code:1 userInfo:@{NSLocalizedDescriptionKey: description}];
        completionBlock(nil, error);
        NSBlockOperation *blockOp = [NSBlockOperation blockOperationWithBlock:^{
            // hitting cache
        }];
        return (NSOperation *)blockOp;
    }
    
    NSString *path = @"user/detail/";
    
    MKNetworkOperation *op;
#if defined(USE_SSL) && USE_SSL == 1
    op = [self operationWithPath:path params:nil httpMethod:@"GET" ssl:YES];
#else
    op = [self operationWithPath:path params:nil httpMethod:@"GET"];
#endif
    
//    [op setPostDataEncoding:MKNKPostDataEncodingTypeJSON];
    
    [op setAuthorizationHeaderValue:authToken forAuthType:@"Token"];
    
    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        NSInteger statusCode = [completedOperation HTTPStatusCode];
        if (statusCode == 200)
        {
            NSDictionary *result = (NSDictionary *)[completedOperation responseJSON];
            
            // TODO: assert for
            // id
            // username
            // email
            // first_name
            // last_name
            // sightings[]
            
            completionBlock(result, nil);
        }
        else
        {
            NSString *description = NSLocalizedString(@"Unable to authenticate", @"When checking user details with an auth_token");
            NSError *error = [NSError errorWithDomain:@"getUserDetailsUsingAuthToken" code:1 userInfo:@{NSLocalizedDescriptionKey: description}];
            completionBlock(nil, error);
        }
    } errorHandler:^(MKNetworkOperation *errorOperation, NSError *error) {
#if TRACK
        NSDictionary *result;
        @try {
            result = (NSDictionary *)[errorOperation responseJSON];
        }
        @catch (NSException *exception) {
        }
        @finally {
            [GoogleAnalytics sendEventWithCategory:@"admin-notification"
                                                              withAction:[NSString stringWithCString:__PRETTY_FUNCTION__ encoding:NSASCIIStringEncoding]
                                                               withLabel:[NSString stringWithFormat:@"Error: %@; Result: %@;", error.localizedDescription, [result description]]
                                                               withValue:@(error.code)];
        }
#endif
        //NSInteger statusCode = [errorOperation HTTPStatusCode];
        completionBlock(nil, error);
    }];

    [self enqueueOperation:op];
    
    return op;
}



#pragma mark - Submit a sighting

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
                             completionBlock:(void (^)(NSDictionary *sightingObj, NSError *error))completionBlock
{
    logmethod();
    /*
     
     TODO:
     
     Make a few mockup sightings in the app delegate
     Initiate sending
     Figure out who is holding a strong reference to the IOUploadAPendingSighting operation
     
     */
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [numberFormatter setMaximumFractionDigits:12];
    [numberFormatter setRoundingMode:NSNumberFormatterRoundUp];
    
    NSDictionary *required = @{
         @"sighting_date"     : [dateFormatter stringFromDate: sightingDate],
         @"activity"          : (NSNumber *)activity.ID,
         @"latitude"          : @([[numberFormatter stringFromNumber:@(latitude)] doubleValue]),
         @"count"             : (NSNumber *)count.ID,
         @"sex"               : (NSNumber *)sex.ID,
         @"longitude"         : @([[numberFormatter stringFromNumber:@(longitude)] doubleValue]),
         @"accuracy"          : (NSNumber *)accuracy.ID,
         @"depth"             : @(depth),
         @"water_temperature" : @(waterTemperature),
    };
    
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionaryWithDictionary:required];
    if (species)
        mutableParams[@"species"] = (NSNumber *)species.ID;
    if (otherSpeciesCommonName && otherSpeciesLatinName)
        mutableParams[@"other_species"] = [NSString stringWithFormat:@"%@ (%@)", otherSpeciesLatinName, otherSpeciesCommonName];
    
    if (habitat)
        mutableParams[@"habitat"] = (NSNumber *)habitat.ID;
    if (notes)
        mutableParams[@"notes"] = notes;
    if (photoCaption)
        mutableParams[@"photo_caption"] = photoCaption;
    if (sizeMethod)
    {
        mutableParams[@"size"] = @(size);
        mutableParams[@"size_method"] = (NSNumber *)sizeMethod.ID;
    }
    if (time)
        mutableParams[@"time"] = (NSNumber *)time.ID;
    
    if (weightMethod)
    {
        mutableParams[@"weight"] = @(weight);
        mutableParams[@"weight_method"] = (NSNumber *)weightMethod.ID;
    }
    NSDictionary *params = [mutableParams copy];
    mutableParams = nil;
    
    NSString *path = @"sighting/create/";
    
    /*
    {
        completionBlock(nil, [NSError errorWithDomain:@"test" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"test"}]);
        return nil;
    }
     */

    MKNetworkOperation *op;
#if defined(USE_SSL) && USE_SSL == 1
    op = [self operationWithPath:path params:params httpMethod:@"POST" ssl:YES];
#else
    op = [self operationWithPath:path params:params httpMethod:@"POST"];
#endif
    
    [op setAuthorizationHeaderValue:authToken forAuthType:@"Token"];
    
    [op addFile:photoURL.path forKey:@"photo_url"];
    //[op addData:[NSData dataWithContentsOfURL:photoURL] forKey:@"photo_url" mimeType:@"application/octet-stream" fileName:photoURL.lastPathComponent];
    [op setFreezable:YES];
    
    if (onUploadProgress != nil)
        [op onUploadProgressChanged:^(double progress) {
            onUploadProgress(progress);
        }];
    
    __weak __typeof(self)weakSelf = self;
    [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        
        NSInteger statusCode = [completedOperation HTTPStatusCode];
        
        DDLogVerbose(@"%@: SUCCESS in submitting the sighting. StatusCode: %d", weakSelf.class, statusCode);
#if DEBUG
        DDLogVerbose(@"%@: Response String: %@", weakSelf.class, [completedOperation responseString]);
#endif
        
        NSDictionary *responseObj = [completedOperation responseJSON];
        @try {
            NSAssert(responseObj[@"pk"] != nil, @"Malformed response. No Primary Key.");
            NSAssert(responseObj[@"id"] != nil, @"Malformed response. No ID.");
            NSAssert([responseObj[@"id"] integerValue] == [responseObj[@"pk"] integerValue], @"Malformed response. Different Primary key and ID.");
            NSAssert(responseObj[@"photo_url"] != nil, @"Malformed response. No Photo URL.");
            
            if (responseObj[@"pk"] == nil)
                @throw [NSException exceptionWithName:RMAPIExceptionMissingValue reason:@"Malformed response. No Primary Key." userInfo:nil];
            if (responseObj[@"id"] == nil)
                @throw [NSException exceptionWithName:RMAPIExceptionMissingValue reason:@"Malformed response. No ID." userInfo:nil];
            if ([responseObj[@"pk"] integerValue] != [responseObj[@"id"] integerValue])
                @throw [NSException exceptionWithName:RMAPIExceptionBadResponse reason:@"Malformed response. Different Primary Key and ID." userInfo:nil];
            if (responseObj[@"photo_url"] == nil)
                @throw [NSException exceptionWithName:RMAPIExceptionMissingValue reason:@"Malformed response. No Photo URL." userInfo:nil];
        }
        @catch (NSException *exception) {
            DDLogError(@"%@: EXCEPTION: %@, %@", weakSelf.class, exception.name, exception.reason);
            
            if (completionBlock)
            {
                NSString *localizedDescription = (exception.reason ?: @"Unknown exception");
                NSError *error = [NSError errorWithDomain:@"sendASightingUsingAuthToken" code:400 userInfo:@{ NSLocalizedDescriptionKey: localizedDescription }];
                completionBlock(nil, error);
                return;
            }
        }
        
        if (completionBlock)
            completionBlock(responseObj, nil);
    } errorHandler:^(MKNetworkOperation *errorOperation, NSError *error) {
        NSDictionary *result;
#if TRACK
        @try {
            result = (NSDictionary *)[errorOperation responseJSON];
        }
        @catch (NSException *exception) {
            DDLogError(@"%@: EXCEPTION: %@, %@", weakSelf.class, exception.name, exception.reason);
        }
        @finally {
            [GoogleAnalytics sendEventWithCategory:@"admin-notification"
                                                              withAction:[NSString stringWithCString:__PRETTY_FUNCTION__ encoding:NSASCIIStringEncoding]
                                                               withLabel:[NSString stringWithFormat:@"Error: %@; Result: %@;", error.localizedDescription, [result description]]
                                                               withValue:@(error.code)];
        }
#endif
#if DEBUG
        DDLogError(@"%@: ERROR sending the sighting: [%d] %@.", weakSelf.class, error.code, error.localizedDescription);
        
        @try {
            result = (NSDictionary *)[errorOperation responseJSON];
            DDLogError(@"%@: Response: %@", weakSelf.class, result);
        }
        @catch (NSException *exception) {
            DDLogError(@"%@: EXCEPTION: %@, %@", weakSelf.class, exception.name, exception.reason);
        }
#endif
        completionBlock(nil, error);
    }];

    [self enqueueOperation:op];
    return op;
}

@end