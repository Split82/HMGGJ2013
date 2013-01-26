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
const int SOUND_SCREAM = 2;

const int BUFF_BG = 1;
const int BUFF_EFFECTS = 31;

@implementation AudioManager {
    CDSoundEngine* soundEngine;
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
        
        NSArray *sourceGroups = [NSArray arrayWithObjects:[NSNumber numberWithInt:BUFF_BG], [NSNumber numberWithInt:BUFF_EFFECTS], nil];
        [soundEngine defineSourceGroups:sourceGroups];
        
        // only this app will be playing sound
        [CDAudioManager initAsynchronously:kAMM_FxPlusMusic];
    
        //Load sound buffers asynchrounously
        NSMutableArray *loadRequests = [[NSMutableArray alloc] init];
        
        [loadRequests addObject:[[CDBufferLoadRequest alloc] init:SOUND_BRUM filePath:@"brum.mp3"]];
        [loadRequests addObject:[[CDBufferLoadRequest alloc] init:SOUND_SCREAM filePath:@"WilhelmScream.mp3"]];
        [soundEngine loadBuffersAsynchronously:loadRequests];
    }
    
    return self;
}

- (void)preloadSounds {
    
}

- (void)scream {
    [soundEngine playSound:SOUND_SCREAM sourceGroupId:BUFF_EFFECTS pitch:1.0f pan:0.0f gain:1.0f loop:YES];
    NSLog(@"hello");
}

@end
