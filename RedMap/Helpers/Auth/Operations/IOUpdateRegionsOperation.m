//
//  IOUpdateRegionsOperation.m
//  Redmap
//
//  Created by Evo Stamatov on 5/09/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOUpdateRegionsOperation.h"
#import "AppDelegate.h"
#import "IOAuth.h"
#import "IORegionsController.h"

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface IOUpdateRegionsOperation ()

@property (nonatomic, strong) NSOperation *remoteOperation;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation IOUpdateRegionsOperation

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
        DDLogVerbose(@"%@: Initiating regions update", self.class);
        
        if (self.isCancelled)
            return;
        
        NSString *userDefaultsKey = @"regionsUpdateDate";
        NSDate *now = [NSDate date];
        NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
        NSDate *lastSync = [standardDefaults objectForKey:userDefaultsKey];
        
        if (self.isCancelled)
            return;
        
        BOOL outOfSync = NO;
        if (!lastSync)
        {
            DDLogVerbose(@"%@: Regions were never synced", self.class);
            outOfSync = YES;
        }
        else if (!self.forced)
        {
#if DEBUG
            DDLogVerbose(@"%@: Regions' last sync: %@", self.class, [lastSync descriptionWithLocale:[NSLocale currentLocale]]);
#endif
            NSDate *expiryDate = [lastSync dateByAddingTimeInterval:kIOExpiryIntervalForRegions];
            if ([expiryDate compare:now] == NSOrderedAscending)
            {
                DDLogVerbose(@"%@: Regions' last sync is out of date", self.class);
                outOfSync = YES;
            }
        }
        
        if (self.isCancelled)
            return;
        
        __block IORegionsController *controller = [[IORegionsController alloc] initWithContext:self.context
                                                                                  searchString:nil];
        
        if (self.isCancelled)
            return;
        
        if (self.forced || outOfSync || [controller.objects count] == 0)
        {
            if (self.isCancelled)
                return;
            
            DDLogVerbose(@"%@: Syncing the regions...", self.class);
            
            __weak IOUpdateRegionsOperation *weakSelf = self;
            self.remoteOperation = (NSOperation *)[RMAPI requestRegions:^(NSArray *chunk, BOOL hasMore, NSInteger total, BOOL cached) {
                DDLogVerbose(@"%@: Got a regions chunk", weakSelf.class);
                DDLogVerbose(@"%@: Syncing with local store", weakSelf.class);
                
                [controller syncCoreDataWithDataFromArray:chunk moreComing:hasMore callback:^(NSSet *insertedObjectIDs, NSSet *updatedObjectIDs, NSError *error) {
                    if (error) {
                        DDLogError(@"%@: ERROR syncing with local store. [%d]: %@", weakSelf.class, error.code, error.localizedDescription);
                        [weakSelf finish];
                    }
                    else
                    {
                        DDLogVerbose(@"%@: Synced with local store", weakSelf.class);
                        
                        if (!hasMore)
                        {
                            DDLogInfo(@"%@: Regions are in sync.", weakSelf.class);
                            
                            [standardDefaults setObject:now forKey:userDefaultsKey];
                            [standardDefaults synchronize];
                            
                            [weakSelf finish];
                        }
                    }
                }];
            } errorBlock:^(NSError *error, NSInteger statusCode) {
                DDLogError(@"%@: ERROR getting a regions chunk", weakSelf.class);
                
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

@end
