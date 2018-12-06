//
//  GoogleAnalytics.h
//  Redmap
//
//  Created by Evo Stamatov on 7/01/2015.
//  Copyright (c) 2015 Ionata. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GoogleAnalytics : NSObject

+ (void)sendEventWithCategory:(NSString *)category withAction:(NSString *)action withLabel:(NSString *)label withValue:(NSNumber *)value;
+ (void)sendView:(NSString *)view;

@end
