//
//  MasterControlProgram.m The main villain 
//  HMGGJ2013
//
//  Created by Peter Morihladko on 1/26/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "MasterControlProgram.h"
#import "MainGameScene.h"

#define ARC4RANDOM_MAX      0x100000000

// init values
const float INIT_ENEMIES_PER_WAVE = 4.0f;
const float INIT_WAVE_PERIOD = 15.0f; // seconds

const float INIT_SWIPE_TAP_ENEMIES_RATIO = 0.2;

// constant values
const float ENEMIES_GROWTH_PER_WAVE = 0.9;
const float SWIPE_TAP_RATIO_GROWTH_PER_WAVE = 0.05;
const float WAVE_LENGHT_DECREASE = 0.75; // second

const float MIN_WAVE_LENGTH = 5.0f; // seconds
const float MAX_ENEMIES_PER_WAVE = 30.0f;
const float MAX_TAP_RATION_PER_WAVE = 0.6;

const float ENEMY_SPAWN_TIME = 2.0f;
const float ENEMY_SPAWN_DELTA_TIME = 4.0f;

const float WAVE_ENEMY_SPAWN_TIME = 0.5f;
const float WAVE_ENEMY_SPAWN_DELTA_TIME = 0.5f;

const float INCREASE_SPAWN_SPEED_FACTOR = 1.25f;

float increase(float value, float inc, float MAX) {
    if (value < MAX) {
        value += inc;
        
        if (value > MAX) value = MAX;
    }
    
    return value;
}

float decrease(float value, float dec, float MIN) {
    if (value > MIN) {
        value -= dec;
        
        if (value < MIN) value = MIN;
    }
    
    return value;
}

@implementation MasterControlProgram {
    float enemiesPerWave;
    float wavePeriod;
    float swipeTapRatio;
    
    float nextWaveTime;
    float nextEnemySpawnTime;
    
    float enemySpawnTime;
    float enemySpawnTimeDelta;
    
    // per wave
    int enemiesToGenerate;
    float waveSpawnSpeedFactor;
}

- (id)init {
    self = [super init];
    
    if (self) {
        enemiesPerWave = INIT_ENEMIES_PER_WAVE - ENEMIES_GROWTH_PER_WAVE;
        wavePeriod = INIT_WAVE_PERIOD + WAVE_LENGHT_DECREASE;
        swipeTapRatio = INIT_SWIPE_TAP_ENEMIES_RATIO - SWIPE_TAP_RATIO_GROWTH_PER_WAVE;
        
        enemySpawnTime = ENEMY_SPAWN_TIME;
        enemySpawnTimeDelta = ENEMY_SPAWN_DELTA_TIME;
        
        waveSpawnSpeedFactor = 1.0f;
        
        [self scheduleNewEnemySpawn];
    }
    
    return self;
}

- (void)calc:(ccTime)deltaTime; {
    nextWaveTime -= deltaTime;
    nextEnemySpawnTime -= deltaTime;

    if (nextWaveTime < 0) {
        [self startWave];
    }
    
    if (nextEnemySpawnTime < 0) {
        [self spawnEnemy];
    }

}


- (void)scheduleNewEnemySpawn {
    
    nextEnemySpawnTime = enemySpawnTime + (float)arc4random() / ARC4RANDOM_MAX * enemySpawnTimeDelta;
}


- (void)startWave {
    // previous wave is not finished
    if (enemiesToGenerate > 0) {
        waveSpawnSpeedFactor = waveSpawnSpeedFactor * INCREASE_SPAWN_SPEED_FACTOR;
    }
    
    enemiesPerWave = increase(enemiesPerWave, ENEMIES_GROWTH_PER_WAVE, MAX_ENEMIES_PER_WAVE);
    swipeTapRatio = increase(swipeTapRatio, SWIPE_TAP_RATIO_GROWTH_PER_WAVE, MAX_TAP_RATION_PER_WAVE);
    wavePeriod = decrease(wavePeriod, WAVE_LENGHT_DECREASE, MIN_WAVE_LENGTH);
    
    enemiesToGenerate = (int)round(enemiesPerWave);
    NSLog(@"Starting wave, spawning %d enemies", enemiesToGenerate);
    
    enemySpawnTime = WAVE_ENEMY_SPAWN_TIME / waveSpawnSpeedFactor;
    enemySpawnTimeDelta = WAVE_ENEMY_SPAWN_DELTA_TIME / waveSpawnSpeedFactor;
    
    nextWaveTime = wavePeriod;
    nextEnemySpawnTime = 0;
}

- (void)spawnEnemy {
    
    // TODO for now, it's just randomness, not calculating true ration of spawned enemis
    if ((float)arc4random() / ARC4RANDOM_MAX < swipeTapRatio) {
        NSLog(@"Enemy Swipe");
        [self.mainframe addEnemy:kEnemyTypeSwipe];
    
    } else {
        NSLog(@"Enemy Tap");
        [self.mainframe addEnemy:kEnemyTypeTap];
    }
    
    // in a wave
    if (enemiesToGenerate > 0) {
        enemiesToGenerate -= 1;
        
        // end of wave spawning
        if (enemiesToGenerate == 0) {
            NSLog(@"Enging wave\n");
            enemySpawnTime = ENEMY_SPAWN_TIME;
            enemySpawnTimeDelta = ENEMY_SPAWN_DELTA_TIME;
        }
    }    
    
    [self scheduleNewEnemySpawn];
}

@end


