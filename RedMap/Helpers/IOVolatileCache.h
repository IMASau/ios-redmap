//
//  IOVolatileCache.h
//  Redmap
//
//  Created by Evo Stamatov on 18/03/2014.
//  Copyright (c) 2014 Ionata. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IOVolatileCache : NSObject

+ (NSDictionary *)cache;

+ (void)setObject:(id)object forKey:(id<NSCopying>)key;
+ (id)objectForKey:(id)key;
- (void)flush;

@end
