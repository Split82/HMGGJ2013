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


// deltas can be calculated
#define CALCULATE FLT_MIN_10_EXP

// wait for user to kill all the wave?
#define NOWAIT 0.0f

#define TUTORIAL_FINISHED_KEY  @"tutorial"

const float START_ENEMIES_PER_WAVE[]      = {    1.000f,    1.000f,    5.000f,    8.000f};
const float END_ENEMIES_PER_WAVE[]        = {   16.000f,   10.000f,   20.000f,   15.000f};

const float START_SWIPE_ENEMIES_RATIO[]   = {    0.000f,    1.000f,    0.200f,    0.400f};
const float END_SWIPE_ENEMIES_RATIO[]     = {    0.000f,    1.000f,    0.650f,    0.500f};

const float START_WAVE_LENGTH[]           = {   10.000f,   10.000f,    5.000f,   20.000f};
const float END_WAVE_LENGTH[]             = {   10.000f,   10.000f,    7.000f,    7.000f};

const float ENEMIES_DELTA[]               = { CALCULATE, CALCULATE, CALCULATE, CALCULATE};
const float SWIPE_ENEMIES_DELTA[]         = { CALCULATE, CALCULATE, CALCULATE, CALCULATE};
const float WAVE_LENGHT_DELTA[]           = { CALCULATE, CALCULATE, CALCULATE, CALCULATE};

const float ENEMY_IDLE_SPAWN_TIME[]       = {    7.000f,    7.000f,    7.000f,    0.500f};
const float ENEMY_IDLE_SPAWN_DELTA_TIME[] = {   10.000f,   10.000f,    3.000f,    1.000f};

const float ENEMY_WAVE_SPAWN_TIME[]       = {    0.500f,    0.500f,    0.200f,    0.500f};
const float ENEMY_WAVE_SPAWN_DELTA_TIME[] = {    2.000f,    1.000f,    0.500f,    1.000f};

// how many seconds to wait for player to kill all the enemies / 0.0f is no wait
const float WAVE_WAIT_FOR_USER[]          = {    8.000f,    5.000f,    3.000f,    NOWAIT};

// after how many levels level up
const int LEVEL_UP_WAVE_COUNT[] = {3, 5, 8, 11};
const int LEVEL_COUNT = 4;

const float INCREASE_SPAWN_SPEED_FACTOR = 1.25f;

const float RANDOM_COIN_SPAWN_TIME = 3.0f;
const float RANDOM_COIN_SPAWN_DELTA_TIME = 5.0f;

const int MIN_PLAYER_COINS_TO_SPAWN_A_COIN = 4;

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

float nextVal(float value, float delta, float end) {
    if (delta < 0) {
        
        return decrease(value, -delta, end);
    } else {
        
        return increase(value, delta, end);
    }
}

float frand() {
    return (float)rand() / RAND_MAX;
}

@implementation MasterControlProgram {
    // current value
    float enemiesPerWave;
    float waveLength;
    float swipeEnemiesRatio;
    
    // deltas
    float enemiesDelta;
    float swipeEnemiesRatioDelta;
    float waveLengthDelta;
    
    BOOL waitForUserProgress;
    
    // timers
    float nextWaveTime;
    float nextEnemySpawnTime;
    float nextRandomCoinTime;
    
    float enemySpawnTime;
    float enemySpawnTimeDelta;
    
    // wave
    int waveNumber; // waves count
    int level;
    
    // per wave
    int enemiesToGenerate;
    float waveSpawnSpeedFactor;

}

- (id)init {
    self = [super init];
    
    if (self) {
        level = 0;
        
        [self initLevel];
    }
    
    return self;
}

- (void)initLevel {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber * res = [defaults objectForKey:TUTORIAL_FINISHED_KEY];
    if (res) {
        
        _tutorialFinished = [res boolValue];
    }
    else {
        
        _tutorialFinished = NO;
    }
    
    int levelLength = level == 0 ? LEVEL_UP_WAVE_COUNT[0] : LEVEL_UP_WAVE_COUNT[level] - LEVEL_UP_WAVE_COUNT[level-1];
    
    // calculate deltas
    enemiesDelta = ENEMIES_DELTA[level] == CALCULATE ?
        (float)(END_ENEMIES_PER_WAVE[level] - START_ENEMIES_PER_WAVE[level]) / levelLength :
        ENEMIES_DELTA[level];
    
    swipeEnemiesRatioDelta = SWIPE_ENEMIES_DELTA[level] == CALCULATE ?
        (float)(END_SWIPE_ENEMIES_RATIO[level] - START_SWIPE_ENEMIES_RATIO[level]) / levelLength :
        SWIPE_ENEMIES_DELTA[level];
    
    waveLengthDelta = WAVE_LENGHT_DELTA[level] == CALCULATE ?
        (float)(END_WAVE_LENGTH[level] - START_WAVE_LENGTH[level]) / levelLength :
        WAVE_LENGHT_DELTA[level];
    
    // start values
    enemiesPerWave = START_ENEMIES_PER_WAVE[level] - enemiesDelta;
    waveLength = START_WAVE_LENGTH[level] - waveLengthDelta;
    swipeEnemiesRatio = START_SWIPE_ENEMIES_RATIO[level] - swipeEnemiesRatioDelta;
    
    enemySpawnTime = ENEMY_IDLE_SPAWN_TIME[level];
    enemySpawnTimeDelta = ENEMY_IDLE_SPAWN_DELTA_TIME[level];
    
    waitForUserProgress = WAVE_WAIT_FOR_USER[level] != NOWAIT;
    
    waveSpawnSpeedFactor = 1.0f;
    
    [self scheduleNewEnemySpawn];
    [self sheduleNewCoinSpawn];
    

    _tutorialFinished = YES;
    _tapperKilled = NO;
    _swiperKilled = NO;
    
    if (!_tutorialFinished) {
        
        nextEnemySpawnTime = 2;
    }
    
}

- (void)setTutorialFinished:(BOOL)tutorialFinished {
    
    _tutorialFinished = tutorialFinished;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults setObject:[NSNumber numberWithBool:tutorialFinished] forKey:TUTORIAL_FINISHED_KEY];
    [defaults synchronize];
}

- (void)levelUp {
    if (level < LEVEL_COUNT-1) {
        level += 1;
        
        [self initLevel];
    }
}

- (void)calc:(ccTime)deltaTime; {
    

    nextRandomCoinTime -= deltaTime;

    if (nextRandomCoinTime < 0) {
        [self spawnCoin];
    }

    if (_tutorialFinished) {
        
        nextWaveTime -= deltaTime;
        nextEnemySpawnTime -= deltaTime;
        
        if (nextWaveTime < 0) {
            
            [self startWave];
        }
        
        if (nextEnemySpawnTime < 0) {
            
            [self spawnEnemy];
        }
    }
    else {

        if ((!_tapperKilled && ([_mainframe masterControlProgramNumberOfTapEnemies:self] == 0)) || (_tapperKilled && !_swiperKilled && ([_mainframe masterControlProgramNumberOfSwipeEnemies:self] == 0))) {
            
            nextEnemySpawnTime -= deltaTime;
            
            if (nextEnemySpawnTime < 0) {
                
                [_mainframe masterControlProgram:self addEnemy:_tapperKilled ? kEnemyTypeSwipe : kEnemyTypeTap];
                nextEnemySpawnTime = 1;
            }
        }
        
        if (_swiperKilled && [_mainframe masterControlProgramNumberOfTapEnemies:self] == 0 && [_mainframe masterControlProgramNumberOfSwipeEnemies:self] == 0) {
            
            self.tutorialFinished = YES;
            [self scheduleNewEnemySpawn];
        }
    }
}

- (void)scheduleNewEnemySpawn {
    
    nextEnemySpawnTime = enemySpawnTime + frand() * enemySpawnTimeDelta;
}

- (void)sheduleNewCoinSpawn {
    
    nextRandomCoinTime = RANDOM_COIN_SPAWN_TIME + frand() * RANDOM_COIN_SPAWN_DELTA_TIME;
}


- (void)startWave {   
    
    if (waitForUserProgress) {
        // wait for player to kill the previous wave
        if ([_mainframe masterControlProgramNumberOfTapEnemies:self] + [_mainframe masterControlProgramNumberOfSwipeEnemies:self] > 1) {
            
            nextWaveTime = WAVE_WAIT_FOR_USER[level];
            return;
        }
    }
    
    if (waveNumber >= LEVEL_UP_WAVE_COUNT[level] && level < LEVEL_COUNT - 1) {
        [self levelUp];
    }
    
    enemiesPerWave = nextVal(enemiesPerWave, enemiesDelta, END_ENEMIES_PER_WAVE[level]);
    swipeEnemiesRatio = nextVal(swipeEnemiesRatio, swipeEnemiesRatioDelta, END_SWIPE_ENEMIES_RATIO[level]);
    waveLength = nextVal(waveLength, waveLengthDelta, END_WAVE_LENGTH[level]);
    
    // hardcore level
    if (enemiesToGenerate > 0) {
        waveSpawnSpeedFactor = waveSpawnSpeedFactor * INCREASE_SPAWN_SPEED_FACTOR;
    }
    
    enemiesToGenerate = (int)round(enemiesPerWave);
    
    enemySpawnTime = ENEMY_WAVE_SPAWN_TIME[level] / waveSpawnSpeedFactor;
    enemySpawnTimeDelta = ENEMY_WAVE_SPAWN_DELTA_TIME[level] / waveSpawnSpeedFactor;
    
    nextWaveTime = waveLength;
    nextEnemySpawnTime = 0;

    waveNumber += 1;
}

- (void)spawnEnemy {
    
    if (frand() <= swipeEnemiesRatio) {
        [_mainframe masterControlProgram:self addEnemy:kEnemyTypeSwipe];
    
    } else {
        [_mainframe masterControlProgram:self addEnemy:kEnemyTypeTap];
    }
    
    // in a wave
    if (enemiesToGenerate > 0) {
        enemiesToGenerate -= 1;
        
        // end of wave spawning
        if (enemiesToGenerate == 0) {
            
            enemySpawnTime = ENEMY_IDLE_SPAWN_TIME[level];
            enemySpawnTimeDelta = ENEMY_IDLE_SPAWN_DELTA_TIME[level];
        }
    }    
    
    [self scheduleNewEnemySpawn];
}

- (void)spawnCoin {
    
    if ([_mainframe masterControlProgramNumberOfPlayerCoins:self] <= MIN_PLAYER_COINS_TO_SPAWN_A_COIN) {
        CGSize winSize = [[CCDirector sharedDirector] winSize];
        
        [_mainframe masterControlProgram:self addCoinAtPos:ccp(winSize.width * frand(), 600 /* randomly chosen by Jail */)];
    }
    
    [self sheduleNewCoinSpawn];
}

@end


