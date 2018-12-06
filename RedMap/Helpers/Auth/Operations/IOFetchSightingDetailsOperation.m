//
//  IOFetchSightingDetailsOperation.m
//  Redmap
//
//  Created by Evo Stamatov on 17/03/2014.
//  Copyright (c) 2014 Ionata. All rights reserved.
//

#import "IOFetchSightingDetailsOperation.h"
#import "AppDelegate.h"
#import "IOSightingsController.h"
#import "Sighting.h"
#import "IOPhotoCollection.h"
#import "IOCoreDataHelper.h"

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;


@interface IOFetchSightingDetailsOperation ()

@property (nonatomic, assign) NSInteger sightingID;
@property (nonatomic, copy) NSString *authToken;

@property (nonatomic, strong) IOSightingsController *sightingsController;
@property (nonatomic, strong) NSManagedObjectContext *context;

@property (nonatomic, strong) NSOperation *apiOperation;
@property (nonatomic, strong) NSOperation *imageOperation;

@property (nonatomic, strong) IOPhotoCollection *photos;

@end


@implementation IOFetchSightingDetailsOperation

- (instancetype)initWithSightingID:(NSInteger)sightingID authToken:(NSString *)authToken sightingsController:(IOSightingsController *)sightingsController context:(NSManagedObjectContext *)context
{
    self = [super init];
    if (self)
    {
        logmethod();
        _sightingID = sightingID;
        _authToken = authToken;
        
        _sightingsController = sightingsController;
        _context = context;
    }
    return self;
}

- (void)dealloc
{
    logmethod();
#if DEBUG
    DDLogWarn(@"%@: Deallocating", self.class);
#endif
    
    _apiOperation = nil;
    _imageOperation = nil;
    
    _photos = nil;
    
    _sightingsController = nil;
    _context = nil;
}

- (void)main
{
    logmethod();
    if (self.isCancelled)
        return;
    
    NSInteger sightingID = self.sightingID;
    DDLogVerbose(@"%@: Fetching sighitng with ID: %d", self.class, sightingID);
    
    __weak __typeof(self)weakSelf = self;
    self.apiOperation = [RMAPI requestUserSightingByID:sightingID
                                             authToken:self.authToken
                                       completionBlock:^(NSDictionary *sightingDict)
    {
        DDLogVerbose(@"%@: Got a sighting with ID: %d", weakSelf.class, sightingID);
        DDLogVerbose(@"%@: Syncing with local store", weakSelf.class);
        
        if (weakSelf.isCancelled)
            return;
        
        [weakSelf.sightingsController syncCoreDataWithDataFromArray:@[sightingDict] moreComing:NO callback:^(NSSet *insertedObjectIDs, NSSet *updatedObjectIDs, NSError *error) {
            if (error)
            {
                DDLogError(@"%@: ERROR syncing with local store. [%d]: %@", weakSelf.class, error.code, error.localizedDescription);
                [weakSelf finish];
                return;
            }
            
            NSString *photoURL = sightingDict[@"photo_url"];
            if (!photoURL || [photoURL isKindOfClass:[NSNull class]])
            {
                DDLogError(@"%@: ERROR: No photo url for sighting with ID %d. Skipping.", weakSelf.class, sightingID);
                [weakSelf finish];
                return;
            }
            
            BOOL update = NO;
            NSManagedObjectID *objID;
            if (insertedObjectIDs.count > 0)
            {
                DDLogVerbose(@"%@: Will insert the sighting with ID %d", weakSelf.class, sightingID);
                objID = [insertedObjectIDs anyObject];
            }
            else if (updatedObjectIDs.count > 0)
            {
                DDLogVerbose(@"%@: Will update the sighting with ID %d", weakSelf.class, sightingID);
                objID = [updatedObjectIDs anyObject];
                update = YES;
            }
            else
            {
                DDLogVerbose(@"%@: SKIPPING. No need to update/insert the sighting with ID %d", weakSelf.class, sightingID);
                [weakSelf finish];
                return;
            }
            
#warning CHECK if self.sightingsContext will work better
            Sighting *sighting = (Sighting *)[weakSelf.context objectWithID:objID];
            NSString *sightingUUID = sighting.uuid;
            
            DDLogVerbose(@"%@: Checking sighting image.", weakSelf.class);
            //DDLogVerbose(@"%@: %@", weakSelf.class, photoURL);
            
            weakSelf.photos = [[IOPhotoCollection alloc] init];
            [weakSelf.photos reSetTheUUID:sightingUUID retainingPhotos:YES withCallback:^(NSError *error) {
                BOOL shouldDownload = NO;
                
                if (error)
                {
                    if ([error.domain isEqualToString:NSCocoaErrorDomain] && error.code == NSFileReadNoSuchFileError)
                    {
                        DDLogVerbose(@"%@: No local sighting photo(s) found. Downloading one.", weakSelf.class);
                        shouldDownload = YES;
                    }
                    else
                    {
                        DDLogError(@"%@: ERROR fetching local photos for sighting with ID %d. [%d]: %@", weakSelf.class, sightingID, error.code, error.localizedDescription);
                        
                        // fault the object to free up memory
                        [IOCoreDataHelper faultObjectWithID:objID inContext:weakSelf.context];
                        
                        weakSelf.photos = nil;
                        
                        [weakSelf finish];
                        return;
                    }
                }
                else if (weakSelf.photos.count == 0)
                    shouldDownload = YES;
                
                if (shouldDownload)
                {
                    weakSelf.imageOperation = [ApplicationDelegate.imageEngine loadImageFromURL:photoURL successBlock:^(UIImage *image) {
                        DDLogVerbose(@"%@: Got an image for sighting with ID %d", weakSelf.class, sightingID);
                        
#warning CHECK why this block is called twice on a random basis!!!!!!
                        // TODO: check for update
                        if (/*update &&*/ weakSelf.photos.count > 0)
                            [weakSelf.photos removePhotoObjectAtIndex:0];
                        
                        [weakSelf.photos addPhotoObject:image];
                        sighting.photosCount = @(1);
                        // fault the object to save it and free up memory
                        [IOCoreDataHelper faultObjectWithID:objID inContext:weakSelf.context];
                        
                        weakSelf.photos = nil;
                        
                        DDLogVerbose(@"%@: Broadcasting a notification for sighting photo update", weakSelf.class);
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"sightingPhotoUpdated" object:nil userInfo:@{ @"sightingUUID": sightingUUID }];
                        
                        DDLogVerbose(@"%@: Done with sighting %d", weakSelf.class, sightingID);
                        [weakSelf finish];
                    } errorBlock:^(NSError *error, NSInteger statusCode) {
                        DDLogError(@"%@: ERROR fetching an image for sighting with ID %d. StatusCode: %d, [%d]: %@", weakSelf.class, sightingID, statusCode, error.code, error.localizedDescription);
                        
                        // fault the object to free up memory
                        [IOCoreDataHelper faultObjectWithID:objID inContext:weakSelf.context];
                        
                        weakSelf.photos = nil;
                        
                        DDLogVerbose(@"%@: Done with sighting with ID %d", weakSelf.class, sightingID);
                        [weakSelf finish];
                    }];
                }
                else
                {
                    DDLogVerbose(@"%@: No need to download photo for sighting", weakSelf.class);
                    DDLogVerbose(@"%@: Done with sighting with ID %d", weakSelf.class, sightingID);
                    
                    weakSelf.photos = nil;
                    [weakSelf finish];
                }
            }];
        }];
        
    } errorBlock:^(NSError *error, NSInteger statusCode) {
        DDLogError(@"%@: ERROR fetching a sighting. StatusCode: %d. [%d]: %@", weakSelf.class, statusCode, error.code, error.localizedDescription);
        [weakSelf finish];
    }];
    
#if DEBUG
    double delayInSeconds = 5.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        DDLogWarn(@"Nil check? %@ (1001) [%@]", weakSelf == nil ? @"YES" : @"NO", @"IOUpdateUserDetailsWithAuthTokenOperation");
    });
#endif
}

- (void)cancel
{
    logmethod();
    [self.apiOperation cancel];
    self.apiOperation = nil;
    
    [self.imageOperation cancel];
    self.imageOperation = nil;
    
    [super cancel];
}

@end
