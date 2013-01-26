//
//  MainGameScene.m
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/25/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "MainGameScene.h"
#import "GameDataNameDefinitions.h"
#import "EnemySprite.h"

#define PIXEL_ART_SPRITE_SCALE 4

#define TOP_HEIGHT 80

#define MAX_DELTA_TIME 0.1f
#define MAX_CALC_TIME 0.1f
#define FRAME_TIME_INTERVAL (1.0f / 60)

#define ENEMY_SPAWN_TIME 3.0f
#define ENEMY_SPAWN_DELTA_TIME 2.0f

@interface MainGameScene() {

    float calcTime;

    GestureRecognizer *gestureRecognizer;

    CCSpriteBatchNode *mainSpriteBatch;
    NSMutableArray *tapEnemies;
    NSMutableArray *swipeEnemies;
    NSMutableArray *killedTapEnemies;
    NSMutableArray *killedSwipeEnemies;
    NSMutableArray *coins;

    NSMutableArray *killedCoins;

    CCParticleBatchNode *particleBatchNode;

    // State vars
    BOOL sceneInitWasPerformed;
    
    float enemySpawnTime;
}

@end


@implementation MainGameScene

- (void)onEnter {

    [super onEnter];

    gestureRecognizer = [[GestureRecognizer alloc] init];
    gestureRecognizer.delegate = self;
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:gestureRecognizer priority:0 swallowsTouches:YES];

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
    killedTapEnemies = [[NSMutableArray alloc] initWithCapacity:100];
    killedSwipeEnemies = [[NSMutableArray alloc] initWithCapacity:100];
    coins = [[NSMutableArray alloc] initWithCapacity:100];

    killedCoins = [[NSMutableArray alloc] initWithCapacity:10];

    // Load texture atlas
    CCSpriteFrameCache *frameCache = [CCSpriteFrameCache sharedSpriteFrameCache];
    [frameCache addSpriteFramesWithFile:kGameObjectsSpriteFramesFileName];

    CCSpriteFrame *placeholderSpriteFrame = [frameCache spriteFrameByName:kPlaceholderTextureFrameName];

    // Sprite batch
    mainSpriteBatch = [[CCSpriteBatchNode alloc] initWithFile:placeholderSpriteFrame.textureFilename capacity:100];
    [mainSpriteBatch.texture setAliasTexParameters];
    [self addChild:mainSpriteBatch];

    // Particle batch
    particleBatchNode = [[CCParticleBatchNode alloc] initWithFile:kSimpleParticleTextureFileName capacity:10];
    [self addChild:particleBatchNode];

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

    /*
    CCParticleSystem *test = [[CCParticleSystemQuad alloc] initWithFile:kExplosionParticleSystemFileName];
    test.position = ccp(100, 100);
    [particleBatchNode addChild:test];
     */

    //[self scheduleNewEnemySpawn];
}

#pragma mark - Objects

- (void)addCoinAtPos:(CGPoint)pos {

    CoinSprite *newCoin = [[CoinSprite alloc] initWithStartPos:pos];

    newCoin.delegate = self;
    [coins addObject:newCoin];
    [mainSpriteBatch addChild:newCoin];
}

- (void)addEnemy {

    EnemySprite *enemy = [[EnemySprite alloc] initWithType:(EnemyType)rand() % 2];

    if (enemy.type == kEnemyTypeSwipe) {

        [swipeEnemies addObject:enemy];
    }
    else {

        [tapEnemies addObject:enemy];
    }

    [mainSpriteBatch addChild:enemy];
    enemy.delegate = self;
    
    [self scheduleNewEnemySpawn];
}

- (void)scheduleNewEnemySpawn {

    enemySpawnTime = ENEMY_SPAWN_TIME + (float)rand() / RAND_MAX * ENEMY_SPAWN_DELTA_TIME;
}

#pragma mark - CoinSpriteDelegate

- (void)coinDidDie:(CoinSprite *)coinSprite {

    [killedCoins addObject:coinSprite];
}

#pragma mark - Gestures

- (void)longPressStarted:(CGPoint)pos {

    NSLog(@"LongPress start");
}

- (void)longPressEnded {

        NSLog(@"LongPress end");
}

- (void)swipeStarted:(CGPoint)pos {

        NSLog(@"Swipe start");
}

- (void)swipeMoved:(CGPoint)pos {

        NSLog(@"Swipe moved");    
}

- (void)swipeCancelled {

            NSLog(@"Swipe cancelled"); 
}

- (void)swipeEnded:(CGPoint)pos {

        NSLog(@"Swipe ended");     
}

- (void)tapRecognized:(CGPoint)pos {

    [self addCoinAtPos:pos];

        NSLog(@"Tap recognized");
}

#pragma mark - Update

- (void)update:(ccTime)deltaTime {

    if (deltaTime > MAX_DELTA_TIME) {

        deltaTime = MAX_DELTA_TIME;
    }

    calcTime += deltaTime;

    if (calcTime > MAX_CALC_TIME) {
        calcTime = FRAME_TIME_INTERVAL;
    }

    while (calcTime >= FRAME_TIME_INTERVAL) {

        // Gestures
        [gestureRecognizer update:FRAME_TIME_INTERVAL];

        // Coin
        for (CoinSprite *coin in coins) {
            [coin update:FRAME_TIME_INTERVAL];
        }

        for (EnemySprite *enemy in tapEnemies) {
            [enemy update:FRAME_TIME_INTERVAL];
        }
        
        for (EnemySprite *enemy in swipeEnemies) {
            [enemy update:FRAME_TIME_INTERVAL];
        }

        // Killed
        for (CoinSprite *coin in killedCoins) {
            [coins removeObject:coin];
            [coin removeFromParentAndCleanup:YES];
        }
        [killedCoins removeAllObjects];
        
        for (EnemySprite *killedEnemy in killedTapEnemies) {
            
            [tapEnemies removeObject:killedEnemy];
        }
        
        [killedTapEnemies removeAllObjects];
        
        for (EnemySprite *killedEnemy in killedSwipeEnemies) {
            
            [swipeEnemies removeObject:killedEnemy];
        }
        
        [killedSwipeEnemies removeAllObjects];
        
        
        calcTime -= FRAME_TIME_INTERVAL;
    }
}

#pragma EnemySpriteDelegate

- (void)enemyDidClimbWall:(EnemySprite*)enemy {

    if (enemy.type == kEnemyTypeTap) {
        
        [killedTapEnemies addObject:enemy];
    }
    else {
        
        [killedSwipeEnemies addObject:enemy];
    }
    
    [mainSpriteBatch removeChild:enemy cleanup:YES];
}


@end