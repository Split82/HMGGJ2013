//
//  MasterControlProgram.m The main villain 
//  HMGGJ2013
//
//  Created by Peter Morihladko on 1/26/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "MasterControlProgram.h"
#import "MainGameScene.h"

const float ENEMY_SPAWN_TIME = 1.0f;
const float ENEMY_SPAWN_DELTA_TIME = 2.0f;

@implementation MasterControlProgram {
    float enemySpawnTime;
}

- (id)init {
    self = [super init];
    
    if (self) {
        [self scheduleNewEnemySpawn];
    }
    
    return self;
}

- (void)calc:(ccTime)deltaTime; {
    enemySpawnTime -= deltaTime;

    if (enemySpawnTime < 0) {
        [self.mainframe addEnemy];
        
        [self scheduleNewEnemySpawn];
    }
}


- (void)scheduleNewEnemySpawn {
    
    enemySpawnTime = ENEMY_SPAWN_TIME + (float)rand() / RAND_MAX * ENEMY_SPAWN_DELTA_TIME;
}


@end


