//
//  IOUpdateCategoriesOperation.m
//  Redmap
//
//  Created by Evo Stamatov on 5/09/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOUpdateCategoriesOperation.h"
#import "IOAuth.h"
#import "IOCategoriesController.h"
#import "IOCategory-typedefs.h"
#import "AppDelegate.h"

#if DEBUG
#define SKIP_IMAGES 1
#endif

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface IOUpdateCategoriesOperation ()

@property (nonatomic, strong) NSOperation *remoteOperation;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation IOUpdateCategoriesOperation

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
        DDLogVerbose(@"%@: Initiating categories update", self.class);
        
        if (self.isCancelled)
            return;
        
        NSString *userDefaultsKey = @"categoriesUpdateDate";
        NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
        NSDate *lastSync = [standardDefaults objectForKey:userDefaultsKey];
        
        if (self.isCancelled)
            return;
        
        BOOL outOfSync = NO;
        if (!lastSync)
        {
            DDLogVerbose(@"%@: Categories were never synced", self.class);
            outOfSync = YES;
        }
        else if (!self.forced)
        {
#if DEBUG
            DDLogVerbose(@"%@: Categories' last sync: %@", self.class, [lastSync descriptionWithLocale:[NSLocale currentLocale]]);
#endif
            NSDate *expiryDate = [lastSync dateByAddingTimeInterval:kIOExpiryIntervalForCategories];
            if ([expiryDate compare:[NSDate date]] == NSOrderedAscending)
            {
                DDLogVerbose(@"%@: Categories' last sync is out of date", self.class);
                outOfSync = YES;
            }
        }
        
        if (self.isCancelled)
            return;
        
        IOCategoriesController *cc = [[IOCategoriesController alloc] initWithContext:self.context region:nil searchString:nil];
        
        if (self.isCancelled)
            return;
        
        if (self.forced || outOfSync || [cc.objects count] == 0)
        {
            if (self.isCancelled)
                return;
            
            DDLogVerbose(@"%@: Syncing the categories...", self.class);
            
            __weak __typeof(self)weakSelf = self;
            self.remoteOperation = (NSOperation *)[RMAPI requestCategories:^(NSArray *chunk, BOOL hasMore, NSInteger total, BOOL cached) {
                DDLogVerbose(@"%@: Got a categories chunk", weakSelf.class);
                DDLogVerbose(@"%@: Syncing with local store", weakSelf.class);
                
                [cc syncCoreDataWithDataFromArray:chunk moreComing:hasMore callback:^(NSSet *insertedObjectIDs, NSSet *updatedObjectIDs, NSError *error) {
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
                            NSString *imageURL = [managedObject valueForKey:kIOCategoryPropertyPictureUrl];
                            if (imageURL.length > 0)
                                [imagesToDownload addObject:imageURL];
                        }
                        
                        [weakSelf queueTheImages:imagesToDownload];
                        
                        if (!hasMore)
                        {
                            DDLogInfo(@"%@: Categories are in sync.", weakSelf.class);
                            
                            [standardDefaults setObject:[NSDate date] forKey:userDefaultsKey];
                            [standardDefaults synchronize];
                            
                            [weakSelf finish];
                        }
                    }
                }];
            } errorBlock:^(NSError *error, NSInteger statusCode) {
                DDLogError(@"%@: ERROR getting a categories chunk", weakSelf.class);
                
                [weakSelf finish];
            }];
        }
        else
        {
            DDLogInfo(@"%@: SKIPPING operation - in sync and not out of date", self.class);
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
    DDLogWarn(@"%@: !!!!!!!!! SKIPPING QUEUEING THE IMAGES", self.class);
    return;
#endif
    
    if (imagesToDownload.count > 0)
    {
        DDLogVerbose(@"%@: Scheduling the categories images (%d)", self.class, imagesToDownload.count);
        
        NSSet *imagesToDownloadCopy = [imagesToDownload copy];
        
        __weak __typeof(self)weakSelf = self;
        double delayInSeconds = 5.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            DDLogVerbose(@"%@: Downloading the categories images", weakSelf.class);
            
            [imagesToDownloadCopy enumerateObjectsUsingBlock:^(NSString *imageURL, BOOL *stop) {
                [ApplicationDelegate.imageEngine loadImageFromURL:imageURL successBlock:^(UIImage *image) {
                    // bang! done
                } errorBlock:^(NSError *error, NSInteger statusCode) {
                    // bang! error
                    DDLogError(@"%@: ERROR downloading a category image", weakSelf.class);
                }];
            }];
        });
    }
}

@end
