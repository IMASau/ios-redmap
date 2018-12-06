//
//  NSFileManager+IOFileManager.m
//  Redmap
//
//  Created by Evo Stamatov on 4/10/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "NSFileManager+IOFileManager.h"

static NSString *applicationSupportDirectoryName = @"Application Support";

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation NSFileManager (IOFileManager)

- (NSURL *)URLForApplicationSupportDirectory
{
    static NSURL *applicationSupportURL;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSFileManager *fm = [NSFileManager defaultManager];
        
        NSURL *libDirURL = [[fm URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
        applicationSupportURL = [libDirURL URLByAppendingPathComponent:applicationSupportDirectoryName isDirectory:YES];
        
        // Check if /Library/Application Support/ is reachable
        if ([applicationSupportURL checkResourceIsReachableAndReturnError:nil] == NO)
        {
            // Create the /Library/Application Support/ directory
            if ([fm createDirectoryAtURL:applicationSupportURL withIntermediateDirectories:YES attributes:nil error:nil] == NO)
                applicationSupportURL = nil;
        }
    });
    
    return applicationSupportURL;
}

////////////////////////////////////////////////////////////////////////////////
- (NSURL *)URLForApplicationBundleDirectory
{
    static NSURL *applicationBundleURL;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSFileManager *fm = [NSFileManager defaultManager];
        
        applicationBundleURL = [[fm URLForApplicationSupportDirectory] URLByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier] isDirectory:YES];
        
        // Check if /Library/Application Support/<bundleID>/ is reachable
        if ([applicationBundleURL checkResourceIsReachableAndReturnError:nil] == NO)
        {
            // Create the /Library/Application Support/<bundleID>/ directory
            if ([fm createDirectoryAtURL:applicationBundleURL withIntermediateDirectories:YES attributes:nil error:nil] == NO)
            {
                applicationBundleURL = nil;
            }
        }
    });
    
    return applicationBundleURL;
}

@end
