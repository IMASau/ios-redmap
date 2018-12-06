//
//  GoogleAnalytics.m
//  Redmap
//
//  Created by Evo Stamatov on 7/01/2015.
//  Copyright (c) 2015 Ionata. All rights reserved.
//

#import "GoogleAnalytics.h"

@implementation GoogleAnalytics

+ (void)sendEventWithCategory:(NSString *)category withAction:(NSString *)action withLabel:(NSString *)label withValue:(NSNumber *)value
{
#if TRACK
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];

    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:category
                                                          action:action
                                                           label:label
                                                           value:value] build]];
#endif
}

+ (void)sendView:(NSString *)view
{
#if TRACK
    id tracker = [[GAI sharedInstance] defaultTracker];

    [tracker set:kGAIScreenName value:view];

    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
#endif
}

@end
