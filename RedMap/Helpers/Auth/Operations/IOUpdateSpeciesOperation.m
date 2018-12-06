//
//  IOUpdateSpeciesOperation.m
//  Redmap
//
//  Created by Evo Stamatov on 5/09/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOUpdateSpeciesOperation.h"
#import "AppDelegate.h"
#import "IOSpeciesController.h"
#import "Species-typedefs.h"
#import "IOAuth.h"

#if DEBUG
#define SKIP_IMAGES 1
#endif

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface IOUpdateSpeciesOperation ()

@property (nonatomic, strong) NSOperation *remoteOperation;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation IOUpdateSpeciesOperation

- (void)dealloc
{
    logmethod();
    DDLogWarn(@"%@: Deallocating", self.class);
    _remoteOperation = nil;
}

////////////////////////////////////////////////////////////////////////////////
- (void)main
{
    logmethod();
    @autoreleasepool {
        DDLogVerbose(@"%@: Initiating species update", self.class);
        
        if (self.isCancelled)
            return;
        
        NSString *userDefaultsKey = @"speciesUpdateDate";
        NSDate *now = [NSDate date];
        __block NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
        NSDate *lastSync = [standardDefaults objectForKey:userDefaultsKey];
        
        if (self.isCancelled)
            return;
        
        BOOL outOfSync = NO;
        if (!lastSync)
        {
            DDLogVerbose(@"%@: Species were never synced", self.class);
            outOfSync = YES;
        }
        else if (!self.forced)
        {
            //DDLogVerbose(@"%@: Species' last sync: %@", self.class, lastSync);
            NSDate *expiryDate = [lastSync dateByAddingTimeInterval:kIOExpiryIntervalForSpecies];
            if ([expiryDate compare:now] == NSOrderedAscending)
            {
                DDLogVerbose(@"%@: Species' last sync is out of date", self.class);
                outOfSync = YES;
            }
        }
        
        if (self.isCancelled)
            return;
        
        __block IOSpeciesController *controller = [[IOSpeciesController alloc] initWithContext:self.context
                                                                                    region:nil
                                                                                  category:nil
                                                                              searchString:nil];
        
        if (self.isCancelled)
            return;
        
        if (self.forced || outOfSync || [controller.objects count] == 0)
        {
            if (self.isCancelled)
                return;
        
            DDLogVerbose(@"%@: Syncing the species...", self.class);
            
            __weak __typeof(self)weakSelf = self;
            self.remoteOperation = (NSOperation *)[RMAPI requestSpecies:^(NSArray *chunk, BOOL hasMore, NSInteger total, BOOL cached) {
                DDLogVerbose(@"%@: Got a species chunk", weakSelf.class);
                DDLogVerbose(@"%@: Syncing with local store", weakSelf.class);
                
                [controller syncCoreDataWithDataFromArray:chunk moreComing:hasMore callback:^(NSSet *insertedObjectIDs, NSSet *updatedObjectIDs, NSError *error) {
                    if (error)
                    {
                        DDLogError(@"%@: ERROR syncing with local store. [%d]: %@", weakSelf.class, error.code, error.localizedDescription);
                        [weakSelf finish];
                    }
                    else
                    {
                        DDLogVerbose(@"%@: Synced with local store", weakSelf.class);
                        
                        NSSet *objectsToUpdate = [insertedObjectIDs setByAddingObjectsFromSet:updatedObjectIDs];
                        NSMutableSet *imagesToDownload = [[NSMutableSet alloc] initWithCapacity:objectsToUpdate.count];
                        for (NSManagedObjectID *objectID in objectsToUpdate)
                        {
                            NSManagedObject *managedObject = [weakSelf.context objectWithID:objectID];
                            
                            // queue the picture urls
                            NSString *imageURL = [managedObject valueForKey:kIOSpeciesPropertyPictureUrl];
                            if (imageURL.length > 0)
                                [imagesToDownload addObject:imageURL];
                            
                            // add the distribution images to the mix
                            NSString *distributionURL = [managedObject valueForKey:kIOSpeciesPropertyDistributionUrl];
                            if (distributionURL.length > 0)
                                [imagesToDownload addObject:distributionURL];
                        }
                        
                        [weakSelf queueTheImages:imagesToDownload];
                        
                        if (!hasMore)
                        {
                            DDLogVerbose(@"%@: Species are in sync.", weakSelf.class);
                            
                            [standardDefaults setObject:now forKey:userDefaultsKey];
                            [standardDefaults synchronize];
                            
                            [weakSelf finish];
                        }
                    }
                }];
            } errorBlock:^(NSError *error, NSInteger statusCode) {
                DDLogError(@"%@: ERROR getting a species chunk", weakSelf.class);
                
                [weakSelf finish];
            }];
        }
        else
        {
            DDLogVerbose(@"%@: SKIPPING operation - in sync and not out of date", self.class);
            [self finish];
        }
    }
}

////////////////////////////////////////////////////////////////////////////////
- (void)cancel
{
    logmethod();
    DDLogVerbose(@"%@: Operation cancelled", self.class);
    
    [self.remoteOperation cancel];
    self.remoteOperation = nil;
    
    [super cancel];
}

////////////////////////////////////////////////////////////////////////////////
- (void)queueTheImages:(NSSet *)imagesToDownload
{
    logmethod();
#if SKIP_IMAGES
    DDLogWarn(@"%@: !!!!!!!!!! SKIPPING QUEUEING THE IMAGES", self.class);
    return;
#endif
    
    if (imagesToDownload.count > 0)
    {
        DDLogVerbose(@"%@: Scheduling the species images (%d)", self.class, imagesToDownload.count);
        
        NSSet *imagesToDownloadCopy = [imagesToDownload copy];
        
        __weak __typeof(self)weakSelf = self;
        double delayInSeconds = 5.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            DDLogVerbose(@"%@: Downloading the species images", weakSelf.class);
            
            [imagesToDownloadCopy enumerateObjectsUsingBlock:^(NSString *imageURL, BOOL *stop) {
                [ApplicationDelegate.imageEngine loadImageFromURL:imageURL successBlock:^(UIImage *image) {
                    // bang! done
                } errorBlock:^(NSError *error, NSInteger statusCode) {
                    // bang! error
                    DDLogError(@"%@: ERROR downloading a species image", weakSelf.class);
                }];
            }];
        });
    }
}

@end
