//
//  NSFileManager+IOFileManager.h
//  Redmap
//
//  Created by Evo Stamatov on 4/10/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (IOFileManager)

- (NSURL *)URLForApplicationSupportDirectory;
- (NSURL *)URLForApplicationBundleDirectory;

@end
