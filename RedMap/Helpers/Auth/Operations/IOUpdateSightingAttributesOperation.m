//
//  IOUpdateSightingAttributesOperation.m
//  Redmap
//
//  Created by Evo Stamatov on 5/09/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOUpdateSightingAttributesOperation.h"
#import "IOAuth.h"
#import "IOSightingAttributesController.h"
#import "AppDelegate.h"

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface IOUpdateSightingAttributesOperation ()

@property (nonatomic, strong) NSOperation *remoteOperation;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation IOUpdateSightingAttributesOperation

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
        DDLogVerbose(@"%@: Initiating sighting attributes update", self.class);
        
        if (self.isCancelled)
            return;
        
        NSFileManager *fm = [NSFileManager defaultManager];
        NSURL *bundlePlistURL = [[NSBundle mainBundle] URLForResource:@"sightingAttributes" withExtension:@"plist"];
        
        if (self.isCancelled)
            return;
        
        NSURL *plistURL = [IOSightingAttributesController sightingAttributesPlistURL];
        
        if (self.isCancelled)
            return;
        
        BOOL outOfSync = NO;
        // Check if the default plist exists and copy it into the Documents directory
        if (![fm fileExistsAtPath:[plistURL path]])
        {
            if (self.isCancelled)
                return;
        
            NSError *error = nil;
            if (![fm copyItemAtURL:bundlePlistURL toURL:plistURL error:&error])
            {
                if (error)
                {
                    DDLogError(@"%@: ERROR copying default sighting attributes. [%d]: %@", self.class, error.code, error.localizedDescription);
                }
                
                if (self.isCancelled)
                    return;
                
                [self finish];
                return;
            }
            else
            {
                if (self.isCancelled)
                    return;
                
                // Apply the bundle plist modification date
                NSDictionary *bundlePlistAttributes = [fm attributesOfItemAtPath:[bundlePlistURL path] error:nil];
                // TODO: should we handle errors?
                
                if (self.isCancelled)
                    return;
                
                if (bundlePlistAttributes)
                {
                    [fm setAttributes:bundlePlistAttributes ofItemAtPath:[plistURL path] error:nil];
                    // TODO: should we handle errors?
                }
            }
            
            DDLogVerbose(@"%@: Sighting attributes were never synced", self.class);
            outOfSync = YES;
        }
        
        if (!outOfSync && !self.forced)
        {
            NSError *error = nil;
            NSDictionary *fileAttributes = [fm attributesOfItemAtPath:[plistURL path] error:&error];
            if (self.isCancelled)
                return;
        
            if (!fileAttributes || error)
            {
                DDLogError(@"%@: ERROR while checking the sighting attributes modification date", self.class);
                
                [self finish];
                return;
            }
            NSDate *modificationDate = (NSDate *)[fileAttributes objectForKey:NSFileModificationDate];
            //DDLogVerbose(@"%@: Sighting attributes last sync: %@", self.class, modificationDate);
            
            if (self.isCancelled)
                return;
            
            NSDate *expiryDate = [modificationDate dateByAddingTimeInterval:kIOExpiryIntervalForSightingAttributes];
            
            if (self.isCancelled)
                return;
            
            if ([[expiryDate earlierDate:[NSDate date]] isEqualToDate:expiryDate])
            {
                DDLogVerbose(@"%@: Sighting attributes' last sync is out of date", self.class);
                outOfSync = YES;
            }
        }
        
        if (self.isCancelled)
            return;
        
        if (self.forced || outOfSync)
        {
            DDLogVerbose(@"%@: Syncing the sighting attributes...", self.class);
            
            //[self prepareForLock];
            
            __weak __typeof(self)weakSelf = self;
            @try {
                self.remoteOperation = [RMAPI requestSightingAttributes:^(NSDictionary *attributes) {
                    DDLogVerbose(@"%@: Got the sighting attributes", weakSelf.class);
                    
                    if (weakSelf.isCancelled)
                        return;
                    
                    [attributes writeToURL:plistURL atomically:YES];
                    DDLogVerbose(@"%@: Sighting attributes are in sync.", weakSelf.class);
                    
                    [weakSelf finish];
                } errorBlock:^(NSError *error, NSInteger statusCode) {
                    DDLogError(@"%@: ERROR getting the sighting attributes", weakSelf.class);
                    
                    [weakSelf finish];
                }];
                /*
                self.remoteOperation.completionBlock = ^{
                    weakSelf.remoteOperation = nil;
                };
                 */
            }
            @catch (NSException *e) {
                DDLogError(@"%@: EXCEPTION. Cought an exception: %@, %@", self.class, e.name, e.reason);
                [self finish];
            }
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

@end
