//
//  IOAudioPlayer.m
//  Redmap
//
//  Created by Evo Stamatov on 17/03/2014.
//  Copyright (c) 2014 Ionata. All rights reserved.
//

#import "IOAudioPlayer.h"
#import <AVFoundation/AVAudioPlayer.h>

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

@interface IOAudioPlayer () <AVAudioPlayerDelegate>
@property (nonatomic, strong) AVAudioPlayer *avSound;
@end

@implementation IOAudioPlayer

static IOAudioPlayer *_sharedInstance;

+ (void)initialize
{
    static BOOL initialized = NO;
    if (!initialized)
    {
        _sharedInstance = [self new];
    }
}

+ (instancetype)sharedInstance
{
    return _sharedInstance;
}

+ (void)playSuccess
{
    [_sharedInstance playSuccess];
}

- (void)dealloc
{
    _avSound = nil;
}

- (void)playSuccess
{
    NSURL *soundURL = [[NSBundle mainBundle] URLForResource:@"success_22050_8bit" withExtension:@"aif"];
    NSError *audioLoadError = nil;
    AVAudioPlayer *ap = [[AVAudioPlayer alloc] initWithContentsOfURL:soundURL error:&audioLoadError];
    
    if (!audioLoadError && ap)
    {
        DDLogVerbose(@"%@: Playing success sound.", self.class);
        ap.delegate = self;
        [ap play];
        
        // delay the completion until the sound finishes playing
        self.avSound = ap;
    }
    else
    {
        DDLogWarn(@"%@: ERROR playing the success sound", self.class);
    }
}

#pragma mark - AVAudioPlayerDelegate Protocol

/* audioPlayerDidFinishPlaying:successfully: is called when a sound has finished playing. This method is NOT called if the player is stopped due to an interruption. */
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    DDLogVerbose(@"%@: Releasing the sound", self.class);
    
    player.delegate = nil;
    
    _avSound = nil;
}

/* if an error occurs while decoding it will be reported to the delegate. */
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    DDLogError(@"%@: ERROR decoding the sound file", self.class);
    
    player.delegate = nil;
    
    _avSound = nil;
}

/* audioPlayerBeginInterruption: is called when the audio session has been interrupted while the player was playing. The player will have been paused. */
- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player
{
    DDLogWarn(@"%@: WARNING - the audio player was interrupted", self.class);
    
    [player stop];
    player.delegate = nil;
    
    _avSound = nil;
}
@end
