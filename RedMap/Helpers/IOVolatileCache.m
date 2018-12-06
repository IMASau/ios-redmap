//
//  IOVolatileCache.m
//  Redmap
//
//  Created by Evo Stamatov on 18/03/2014.
//  Copyright (c) 2014 Ionata. All rights reserved.
//

#import "IOVolatileCache.h"

@interface IOVolatileCache ()
@property (nonatomic, strong) NSMutableDictionary *cache;
@end

@implementation IOVolatileCache

static IOVolatileCache *_sharedInstance;

+ (void)initialize
{
    static BOOL initialized = NO;
    if (!initialized)
    {
        initialized = YES;
        _sharedInstance = [self new];
    }
}

+ (NSMutableDictionary *)cache
{
    return [_sharedInstance cache];
}

+ (id)objectForKey:(id)key
{
    return [_sharedInstance.cache objectForKey:key];
}

+ (void)setObject:(id)object forKey:(id<NSCopying>)key
{
    [_sharedInstance.cache setObject:object forKey:key];
}

- (id)init
{
    self = [super init];
    if (self)
    {
        [self registerForNotifications];
        _cache = [NSMutableDictionary dictionaryWithCapacity:20];
    }
    return self;
}

- (void)dealloc
{
    [self flush];
    _cache = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)applicationDidEnterBackground
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [self flush];
}

- (void)applicationWillEnterForeground
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self registerForNotifications];
}

- (void)flush
{
    [_cache removeAllObjects];
}

- (void)didReceiveMemoryWarning
{
    [self flush];
}

@end
