//
//  IOAudioPlayer.h
//  Redmap
//
//  Created by Evo Stamatov on 17/03/2014.
//  Copyright (c) 2014 Ionata. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IOAudioPlayer : NSObject

+ (instancetype)sharedInstance;
+ (void)playSuccess;

@end
