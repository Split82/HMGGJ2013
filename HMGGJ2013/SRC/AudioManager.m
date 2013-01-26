//
//  AudioManager.m
//  HMGGJ2013
//
//  Created by Peter Morihladko on 1/25/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "AudioManager.h"
#import "CDAudioManager.h"

const int SOUND_BRUM = 1;
const int SOUND_GANDAM = 2;
const int SOUND_MUHAHA = 3;

const int BUFF_BG = kASC_Left;
const int BUFF_EFFECTS = kASC_Right;

@implementation AudioManager {
    CDSoundEngine* soundEngine;
    
    ALuint backgroundSound;
}

+ (id)sharedManager {
    
    static AudioManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    
    return sharedMyManager;
}

- (id)init {
    
    if (self = [super init]) {
        soundEngine = [CDAudioManager sharedManager].soundEngine;
        
        NSArray *sourceGroups = [NSArray arrayWithObjects:[NSNumber numberWithInt:1], [NSNumber numberWithInt:31], nil];
        [soundEngine defineSourceGroups:sourceGroups];
        
        // only this app will be playing sound
        [CDAudioManager initAsynchronously:kAMM_FxPlusMusic];        
    }
    
    return self;
}

- (void)playEffect:(int)soundId {
    
    [soundEngine playSound:soundId sourceGroupId:BUFF_EFFECTS pitch:1.0f pan:0.0f gain:1.0f loop:NO];
}

- (void)preloadSounds {
    
    //Load sound buffers asynchrounously
    NSMutableArray *loadRequests = [[NSMutableArray alloc] init];
    
    [loadRequests addObject:[[CDBufferLoadRequest alloc] init:SOUND_BRUM filePath:@"brum.mp3"]];
    [loadRequests addObject:[[CDBufferLoadRequest alloc] init:SOUND_GANDAM filePath:@"8bit-gandam.mp3"]];
    [loadRequests addObject:[[CDBufferLoadRequest alloc] init:SOUND_MUHAHA filePath:@"muhaha.wav"]];
    
    [soundEngine loadBuffersAsynchronously:loadRequests];
}

- (void)scream {
    
    [self playEffect:SOUND_BRUM];
}

- (void)startBackgroundTrack {
    //[soundEngine playSound:SOUND_GANDAM sourceGroupId:BUFF_BG pitch:1.0f pan:0.0f gain:0.6f loop:YES];
}

- (void)stopBackgroundMusic {
    
    [soundEngine stopSound:backgroundSound];
}

@end
