//
//  MasterControlProgram.m The main villain 
//  HMGGJ2013
//
//  Created by Peter Morihladko on 1/26/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "MasterControlProgram.h"
#import "MainGameScene.h"
#import "CCDirector.h"
#import "MainGameScene.h"

// init values
const float INIT_ENEMIES_PER_WAVE = 1.0f;
const float INIT_WAVE_PERIOD = 15.0f; // seconds
const float INIT_SWIPE_TAP_ENEMIES_RATIO = 0.1;

const float ENEMIES_GROWTH_PER_WAVE = 1.2;
const float SWIPE_TAP_RATIO_GROWTH_PER_WAVE = 0.025;
const float WAVE_LENGHT_DECREASE = 0.75; // second

const float MIN_WAVE_LENGTH = 5.0f; // seconds
const float MAX_ENEMIES_PER_WAVE = 30.0f;
const float MAX_TAP_RATION_PER_WAVE = 0.65;

const float ENEMY_SPAWN_TIME = 7.0f;
const float ENEMY_SPAWN_DELTA_TIME = 3.0f;

const float WAVE_ENEMY_SPAWN_TIME = 0.5f;
const float WAVE_ENEMY_SPAWN_DELTA_TIME = 0.5f;
const float WAVE_WAIT_FOR_USER = 5.0f; // how many seconds to wait for player to kill all the enemies

const float INCREASE_SPAWN_SPEED_FACTOR = 1.25f;

const float RANDOM_COIN_SPAWN_TIME = 3.0f;
const float RANDOM_COIN_SPAWN_DELTA_TIME = 5.0f;

const int LEVEL2_BORDER = 10; // begin to decrease wave period and don't wait for player to kill the previous
const float LEVEL2_GROWTH_PENALTY = 2.0f; // the speed of growth of the enemies and swipe/tap ratio will be decreased

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

float frand() {
    return (float)rand() / RAND_MAX;
}

@implementation MasterControlProgram {
    float enemiesPerWave;
    float wavePeriod;
    float swipeTapRatio;
    
    // timers
    float nextWaveTime;
    float nextEnemySpawnTime;
    float nextRandomCoinTime;
    
    float enemySpawnTime;
    float enemySpawnTimeDelta;
    
    // wave
    int waveNumber;
    
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
        [self sheduleNewCoinSpawn];
    }
    
    return self;
}

- (void)calc:(ccTime)deltaTime; {
    nextWaveTime -= deltaTime;
    nextEnemySpawnTime -= deltaTime;
    nextRandomCoinTime -= deltaTime;

    if (nextRandomCoinTime < 0) {
        [self spawnCoin];
    }
    
    if (nextWaveTime < 0) {
        [self startWave];
    }
    
    if (nextEnemySpawnTime < 0) {
        [self spawnEnemy];
    }

}


- (void)scheduleNewEnemySpawn {
    
    nextEnemySpawnTime = enemySpawnTime + frand() * enemySpawnTimeDelta;
}

- (void)sheduleNewCoinSpawn {
    
    nextRandomCoinTime = RANDOM_COIN_SPAWN_TIME + frand() * RANDOM_COIN_SPAWN_DELTA_TIME;
}


- (void)startWave {
    
    if (waveNumber < LEVEL2_BORDER) {
        
        // wait for player to kill the previous wave
        if ([self.mainframe countTapEnemies] + [self.mainframe countSwipeEnemies] > 2) {
            
            NSLog(@"User still fighting, wating");
            nextWaveTime = WAVE_WAIT_FOR_USER;
            return;
        }
        
        enemiesPerWave = increase(enemiesPerWave, ENEMIES_GROWTH_PER_WAVE, MAX_ENEMIES_PER_WAVE);
        swipeTapRatio = increase(swipeTapRatio, SWIPE_TAP_RATIO_GROWTH_PER_WAVE, MAX_TAP_RATION_PER_WAVE);
        
    } else {
        enemiesPerWave = increase(enemiesPerWave / LEVEL2_GROWTH_PENALTY, ENEMIES_GROWTH_PER_WAVE, MAX_ENEMIES_PER_WAVE);
        swipeTapRatio = increase(swipeTapRatio / LEVEL2_GROWTH_PENALTY, SWIPE_TAP_RATIO_GROWTH_PER_WAVE, MAX_TAP_RATION_PER_WAVE);
        wavePeriod = decrease(wavePeriod, WAVE_LENGHT_DECREASE, MIN_WAVE_LENGTH);
    }
    
    // hardcore level
    if (enemiesToGenerate > 0) {
        waveSpawnSpeedFactor = waveSpawnSpeedFactor * INCREASE_SPAWN_SPEED_FACTOR;
    }
    
    enemiesToGenerate = (int)round(enemiesPerWave);
    NSLog(@"Starting wave, spawning %d enemies", enemiesToGenerate);
    
    enemySpawnTime = WAVE_ENEMY_SPAWN_TIME / waveSpawnSpeedFactor;
    enemySpawnTimeDelta = WAVE_ENEMY_SPAWN_DELTA_TIME / waveSpawnSpeedFactor;
    
    nextWaveTime = wavePeriod;
    nextEnemySpawnTime = 0;

    waveNumber += 1;
}

- (void)spawnEnemy {
    
    // TODO for now, it's just randomness, not calculating true ration of spawned enemis
    if (frand() < swipeTapRatio) {
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

- (void)spawnCoin {
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    
    [self.mainframe addCoinAtPos:ccp(winSize.width * frand(), winSize.height * frand() + GROUND_Y)];
    [self sheduleNewCoinSpawn];
}

@end


