//
//  MainGameScene.m
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/25/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "MainGameScene.h"
#import "TextureNameDefinitions.h"
#import "CoinSprite.h"
#import "EnemySprite.h"

#define PIXEL_ART_SPRITE_SCALE 4

#define TOP_HEIGHT 80

#define MAX_DELTA_TIME 0.1f
#define MAX_CALC_TIME 0.1f
#define FRAME_TIME_INTERVAL (1.0f / 60)

#define ENEMY_SPAWN_TIME 2.0f
#define ENEMY_SPAWN_DELTA_TIME 2.0f

@interface MainGameScene() {

    float calcTime;

    CCSpriteBatchNode *mainSpriteBatch;
    NSMutableArray *tapEnemies;
    NSMutableArray *swipeEnemies;
    NSMutableArray *coins;

    BOOL sceneInitWasPerformed;
}

@end


@implementation MainGameScene

- (void)onEnter {

    [super onEnter];

    [self initScene];
}

- (void)initScene {

    if (sceneInitWasPerformed) {
        return;
    }

    sceneInitWasPerformed = YES;

    // Game objects
    tapEnemies = [[NSMutableArray alloc] initWithCapacity:100];
    swipeEnemies = [[NSMutableArray alloc] initWithCapacity:100];
    coins = [[NSMutableArray alloc] initWithCapacity:100];

    // Load texture atlas
    CCSpriteFrameCache *frameCache = [CCSpriteFrameCache sharedSpriteFrameCache];
    [frameCache addSpriteFramesWithFile:kGameObjectsSpriteFramesFileName];

    CCSpriteFrame *placeholderSpriteFrame = [frameCache spriteFrameByName:kPlaceholderTextureFrameName];

    // Batch
    mainSpriteBatch = [[CCSpriteBatchNode alloc] initWithFile:placeholderSpriteFrame.textureFilename capacity:100];
    [mainSpriteBatch.texture setAliasTexParameters];
    [self addChild:mainSpriteBatch];

    CGSize size;

    // Background
    CCSprite *backgroundSprite = [[CCSprite alloc] initWithSpriteFrameName:kPlaceholderTextureFrameName];
    backgroundSprite.anchorPoint = ccp(0, 1);
    backgroundSprite.position = ccp(0, [CCDirector sharedDirector].winSize.height);
    size = backgroundSprite.contentSize;
    backgroundSprite.scaleX = [CCDirector sharedDirector].winSize.width / backgroundSprite.contentSize.width;
    backgroundSprite.scaleY = TOP_HEIGHT / backgroundSprite.contentSize.height;
    [mainSpriteBatch addChild:backgroundSprite];

    // Foreground
    CCSprite *foregroundSprite = [[CCSprite alloc] initWithSpriteFrameName:kPlaceholderTextureFrameName];
    foregroundSprite.anchorPoint = ccp(0, 0);
    foregroundSprite.position = ccp(0, 0);
    foregroundSprite.scale = PIXEL_ART_SPRITE_SCALE;
    [mainSpriteBatch addChild:foregroundSprite];

    [self scheduleUpdate];

    //[self scheduleNewEnemySpawn];
}

- (void)update:(ccTime)deltaTime {

    if (deltaTime > MAX_DELTA_TIME) {

        deltaTime = MAX_DELTA_TIME;
    }

    calcTime += deltaTime;

    if (calcTime > MAX_CALC_TIME) {
        calcTime = FRAME_TIME_INTERVAL;
    }

    while (calcTime >= FRAME_TIME_INTERVAL) {

        for (CoinSprite *coin in coins) {
            [coin update:calcTime];
        }

        for (EnemySprite *enemy in tapEnemies) {
            [enemy update:calcTime];
        }
        
        for (EnemySprite *enemy in swipeEnemies) {
            [enemy update:calcTime];
        }
        
        calcTime -= FRAME_TIME_INTERVAL;
    }
}

- (void)addEnemy {
    
    EnemySprite *enemy = [[EnemySprite alloc] initWithType:(EnemyType)rand() % 2];
    
    if (enemy.type == kEnemyTypeSwipe) {
        
        [swipeEnemies addObject:enemy];
    }
    else {
        
        [tapEnemies addObject:enemy];
    }
    
    [self scheduleNewEnemySpawn];
}

- (void)scheduleNewEnemySpawn {
    
    [self scheduleOnce:@selector(addEnemy) delay:ENEMY_SPAWN_TIME + (float)rand() / RAND_MAX * ENEMY_SPAWN_DELTA_TIME - ENEMY_SPAWN_DELTA_TIME / 2.0f];
}


@end