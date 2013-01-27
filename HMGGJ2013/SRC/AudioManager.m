//
//  AudioManager.m
//  HMGGJ2013
//
//  Created by Peter Morihladko on 1/25/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "AudioManager.h"
#import "CDAudioManager.h"
#import "RandomPicker.h"

const int SOUND_GROUND_HIT_1 = 4;
const int SOUND_GROUND_HIT_2 = 5;
const int SOUND_GROUND_HIT_3 = 6;

const int SOUND_ENEMY_HIT_1 = 7;
const int SOUND_ENEMY_HIT_2 = 8;
const int SOUND_ENEMY_HIT_3 = 9;

const int SOUND_EXPLOSION_1 = 10;
const int SOUND_EXPLOSION_2 = 11;
const int SOUND_EXPLOSION_3 = 12;

const int SOUND_COIN_HIT_1 = 13;
const int SOUND_COIN_HIT_2 = 14;
const int SOUND_COIN_HIT_3 = 15;

const int SOUND_BOMB_SPAWNER_RELEASED = 16;
const int SOUND_BOMB_SPAWNER_CANCELLED = 17;
const int SOUND_BOMB_SPAWNER = 18;

const int SOUND_MENU_MUSIC = 19;

const int BUFF_BG = kASC_Left;
const int BUFF_EFFECTS = kASC_Right;

@implementation AudioManager {
    CDSoundEngine* soundEngine;
    
    ALuint backgroundSound;
    ALuint bombSpawning;
    
    RandomPicker *groundPicker;
    RandomPicker *enemyHitPicker;
    RandomPicker *explosionPicker;
    RandomPicker *coinHitPicker;
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
        
        groundPicker = [[RandomPicker alloc] initWithItems:@[[NSNumber numberWithInt:SOUND_GROUND_HIT_1], [NSNumber numberWithInt:SOUND_GROUND_HIT_2], [NSNumber numberWithInt:SOUND_GROUND_HIT_3]] minimumPickupInterval:0.100];
        
        enemyHitPicker = [[RandomPicker alloc] initWithItems:@[[NSNumber numberWithInt:SOUND_ENEMY_HIT_1], [NSNumber numberWithInt:SOUND_ENEMY_HIT_2], [NSNumber numberWithInt:SOUND_ENEMY_HIT_3]] minimumPickupInterval:0.100];
        
        explosionPicker = [[RandomPicker alloc] initWithItems:@[[NSNumber numberWithInt:SOUND_EXPLOSION_1], [NSNumber numberWithInt:SOUND_EXPLOSION_2], [NSNumber numberWithInt:SOUND_EXPLOSION_3]] minimumPickupInterval:0.100];
        
        coinHitPicker = [[RandomPicker alloc] initWithItems:@[[NSNumber numberWithInt:SOUND_COIN_HIT_1], [NSNumber numberWithInt:SOUND_COIN_HIT_2], [NSNumber numberWithInt:SOUND_COIN_HIT_3]] minimumPickupInterval:0.010];
    }
    
    return self;
}

- (ALuint)playEffect:(int)soundId {
    
    return [soundEngine playSound:soundId sourceGroupId:BUFF_EFFECTS pitch:1.0f pan:0.0f gain:1.0f loop:NO];
}

- (void)playEffectFromPicker:(RandomPicker*)picker {
    
    NSNumber *soundId = [picker pickRandomItem];
    
    if (soundId) {
        [self playEffect:[soundId intValue]];
    }
    
}

- (void)preloadSounds {
    
    //Load sound buffers asynchrounously
    NSMutableArray *loadRequests = [[NSMutableArray alloc] init];
    
    [loadRequests addObject:[[CDBufferLoadRequest alloc] init:SOUND_GROUND_HIT_1 filePath:@"GroundHit1.wav"]];
    [loadRequests addObject:[[CDBufferLoadRequest alloc] init:SOUND_GROUND_HIT_2 filePath:@"GroundHit2.wav"]];
    [loadRequests addObject:[[CDBufferLoadRequest alloc] init:SOUND_GROUND_HIT_3 filePath:@"GroundHit3.wav"]];
    
    [loadRequests addObject:[[CDBufferLoadRequest alloc] init:SOUND_ENEMY_HIT_1 filePath:@"ElHit1.wav"]];
    [loadRequests addObject:[[CDBufferLoadRequest alloc] init:SOUND_ENEMY_HIT_2 filePath:@"ElHit2.wav"]];
    [loadRequests addObject:[[CDBufferLoadRequest alloc] init:SOUND_ENEMY_HIT_3 filePath:@"ElHit3.wav"]];
    
    [loadRequests addObject:[[CDBufferLoadRequest alloc] init:SOUND_EXPLOSION_1 filePath:@"Explosion1.wav"]];
    [loadRequests addObject:[[CDBufferLoadRequest alloc] init:SOUND_EXPLOSION_2 filePath:@"Explosion2.wav"]];
    [loadRequests addObject:[[CDBufferLoadRequest alloc] init:SOUND_EXPLOSION_3 filePath:@"Explosion3.wav"]];
    
    [loadRequests addObject:[[CDBufferLoadRequest alloc] init:SOUND_COIN_HIT_1 filePath:@"CoinHit1.wav"]];
    [loadRequests addObject:[[CDBufferLoadRequest alloc] init:SOUND_COIN_HIT_2 filePath:@"CoinHit2.wav"]];
    [loadRequests addObject:[[CDBufferLoadRequest alloc] init:SOUND_COIN_HIT_3 filePath:@"CoinHit3.wav"]];
    
    [loadRequests addObject:[[CDBufferLoadRequest alloc] init:SOUND_BOMB_SPAWNER_RELEASED filePath:@"BombSpawnerBombReleased.wav"]];
    [loadRequests addObject:[[CDBufferLoadRequest alloc] init:SOUND_BOMB_SPAWNER_CANCELLED filePath:@"BombSpawnerCancelled.wav"]];
    [loadRequests addObject:[[CDBufferLoadRequest alloc] init:SOUND_BOMB_SPAWNER filePath:@"BombSpawner.wav"]];
    
    [loadRequests addObject:[[CDBufferLoadRequest alloc] init:SOUND_MENU_MUSIC filePath:@"MenuMusic.mp3"]];
    
    [soundEngine loadBuffersAsynchronously:loadRequests];
}

- (void)startBackgroundMusic {
    //[soundEngine playSound:SOUND_GANDAM sourceGroupId:BUFF_BG pitch:1.0f pan:0.0f gain:0.6f loop:YES];
    
    [soundEngine playSound:SOUND_MENU_MUSIC sourceGroupId:BUFF_BG pitch:1.0f pan:0.0f gain:0.6f loop:YES];
}

- (void)startMenuMusic {
    
    //[soundEngine stopSourceGroup:BUFF_BG];
    [soundEngine playSound:SOUND_MENU_MUSIC sourceGroupId:BUFF_BG pitch:1.0f pan:0.0f gain:0.6f loop:YES];
}

- (void)stopBackgroundMusic {
    
    [soundEngine stopSourceGroup:BUFF_BG];
}

- (void)groundHit {
    [self playEffectFromPicker:groundPicker];
}

- (void)enemyHit {
    [self playEffectFromPicker:enemyHitPicker];
}

- (void)explode {
    [self playEffectFromPicker:explosionPicker];
}

- (void)coinHit {
    [self playEffectFromPicker:coinHitPicker];
}

- (void)bombSpawningStarted {
    bombSpawning = [self playEffect:SOUND_BOMB_SPAWNER];
}

- (void)bombSpawningCancelled {
    [soundEngine stopSound:bombSpawning];
    
    [self playEffect:SOUND_BOMB_SPAWNER_CANCELLED];
}

- (void)bombReleased {
    [self playEffect:SOUND_BOMB_SPAWNER_RELEASED];
}

@end
