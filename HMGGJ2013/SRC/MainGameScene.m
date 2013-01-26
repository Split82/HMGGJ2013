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
#import "AudioManager.h"
#import "AppDelegate.h"

#define TOP_HEIGHT 80

#define MAX_DELTA_TIME 0.1f
#define MAX_CALC_TIME 0.1f
#define FRAME_TIME_INTERVAL (1.0f / 60)

#define ENEMY_SPAWN_TIME 1.0f
#define ENEMY_SPAWN_DELTA_TIME 2.0f
#define ENEMY_ATTACK_FORCE 5

#define BOMB_COINS_COST 2
#define BOMB_KILL_PERIMETER 85

#define TAP_MIN_DISTANCE2 (60*60)

#define GROUND_Y 45

#define SLIME_WIDTH 280
#define SLIME_GROUND_Y 46
#define SLIME_MAX_HEIGHT 300

@interface MainGameScene() {

    float calcTime;

    GestureRecognizer *gestureRecognizer;

    CCSpriteBatchNode *mainSpriteBatch;
    
    NSMutableArray *tapEnemies;
    NSMutableArray *swipeEnemies;
    NSMutableArray *coins;
    NSMutableArray *bombs;

    NSMutableArray *killedCoins;
    NSMutableArray *killedTapEnemies;
    NSMutableArray *killedSwipeEnemies;
    NSMutableArray *killedBombs;

    BombSpawner *bombSpawner;

    CCSprite *slimeFillSprite;
    CCSprite *slimeTopSprite;
    
    CCParticleBatchNode *particleBatchNode;

    // State vars
    BOOL sceneInitWasPerformed;
    BOOL gameOver;
    
    float enemySpawnTime;
    
    // UI vars
    NSString *fontName;
    UILabel *killsLabel;
    CCSprite *coinsSprite;
    UILabel *coinsLabel;
    UILabel *healthLabel;
    
    UILabel *gameOverLabel;
    UIButton *restartButton;
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
    coins = [[NSMutableArray alloc] initWithCapacity:100];
    bombs = [[NSMutableArray alloc] initWithCapacity:10];

    killedCoins = [[NSMutableArray alloc] initWithCapacity:10];
    killedTapEnemies = [[NSMutableArray alloc] initWithCapacity:100];
    killedSwipeEnemies = [[NSMutableArray alloc] initWithCapacity:100];
    killedBombs = [[NSMutableArray alloc] initWithCapacity:10];

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

    // Background
    CCSprite *backgroundSprite = [[CCSprite alloc] initWithSpriteFrameName:@"mainBack.png"];
    backgroundSprite.anchorPoint = ccp(0.5, 0.5);
    backgroundSprite.position = ccp([CCDirector sharedDirector].winSize.width * 0.5, [CCDirector sharedDirector].winSize.height * 0.5);
    backgroundSprite.scale = [UIScreen mainScreen].scale * 2;    
    [mainSpriteBatch addChild:backgroundSprite];

    // Slime
    slimeFillSprite = [[CCSprite alloc] initWithSpriteFrameName:@"tankWater.png"];
    slimeFillSprite.scaleX = SLIME_WIDTH / slimeFillSprite.contentSize.width;
    slimeFillSprite.scaleY = SLIME_MAX_HEIGHT / slimeFillSprite.contentSize.height;
    slimeFillSprite.anchorPoint = ccp(0.5, 0);
    slimeFillSprite.position = ccp([CCDirector sharedDirector].winSize.width * 0.5, SLIME_GROUND_Y);
    [mainSpriteBatch addChild:slimeFillSprite];
    

    // Foreground
    CCSprite *foregroundSprite = [[CCSprite alloc] initWithSpriteFrameName:@"tankGraphic.png"];
    foregroundSprite.anchorPoint = ccp(0.5, 0);
    foregroundSprite.position = ccp([CCDirector sharedDirector].winSize.width * 0.5, GROUND_Y - 1);
    foregroundSprite.scale = [UIScreen mainScreen].scale * 2;
    [mainSpriteBatch addChild:foregroundSprite];

    // Bomb spawner
    bombSpawner = [[BombSpawner alloc] init];
    bombSpawner.delegate = self;
    bombSpawner.zOrder = 10000;
    [mainSpriteBatch addChild:bombSpawner];

    [self scheduleUpdate];
    
    [self scheduleNewEnemySpawn];
    
    [[AudioManager sharedManager] startBackgroundMusic];
    
    [self initUI];
}

- (void) initUI {
    fontName = @"Visitor TT1 BRK";
    UIFont *font = [UIFont fontWithName:fontName size:20];
    
    CGFloat labelWidth = (320.0 - 10.0) / 2;
    killsLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 7.0, labelWidth, 21.0)];
    [killsLabel setTextAlignment:NSTextAlignmentLeft];
    [killsLabel setTextColor:[UIColor whiteColor]];
    [killsLabel setBackgroundColor:[UIColor clearColor]];
    [killsLabel setFont:font];
    [[CCDirector sharedDirector].view addSubview:killsLabel];
    
    coinsSprite = [[CCSprite alloc] initWithSpriteFrameName:@"coin1.png"];
    coinsSprite.anchorPoint = ccp(0, 0);
    coinsSprite.scale = [UIScreen mainScreen].scale * 2;
    coinsSprite.position = ccp(labelWidth - coinsSprite.contentSize.width,
                               [CCDirector sharedDirector].winSize.height - coinsSprite.contentSize.height * coinsSprite.scale - 5);
    [mainSpriteBatch addChild:coinsSprite];
    
    coinsLabel = [[UILabel alloc] initWithFrame:CGRectMake(labelWidth, 7.0, labelWidth, 21.0)];
    [coinsLabel setTextColor:[UIColor whiteColor]];
    [coinsLabel setTextAlignment:NSTextAlignmentRight];
    [coinsLabel setBackgroundColor:[UIColor clearColor]];
    [coinsLabel setFont:font];
    [[CCDirector sharedDirector].view addSubview:coinsLabel];
    
    healthLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 215.0, 320.0, 40.0)];
    [healthLabel setTextColor:[UIColor redColor]];
    [healthLabel setFont:[UIFont fontWithName:fontName size:30]];
    [healthLabel setTextAlignment:NSTextAlignmentCenter];
    [healthLabel setBackgroundColor:[UIColor clearColor]];
    [[CCDirector sharedDirector].view addSubview:healthLabel];
    
    [self updateUI];
}

- (void) updateUI {
    [killsLabel setText:[NSString stringWithFormat:@"kills %i", [AppDelegate player].kills]];
    [coinsLabel setText:[NSString stringWithFormat:@"coins %i", [AppDelegate player].coins]];
    [healthLabel setText:[NSString stringWithFormat:@"%i", [AppDelegate player].health]];
    
    CGSize size = [coinsLabel.text sizeWithFont:coinsLabel.font forWidth:coinsLabel.frame.size.width lineBreakMode:coinsLabel.lineBreakMode];
    coinsSprite.position = ccp([CCDirector sharedDirector].winSize.width - size.width - 43.0, coinsSprite.position.y);
}

#pragma mark - Objects

- (void)addCoinAtPos:(CGPoint)pos {

    CoinSprite *newCoin = [[CoinSprite alloc] initWithStartPos:pos groundY:GROUND_Y];

    newCoin.delegate = self;
    [coins addObject:newCoin];
    [mainSpriteBatch addChild:newCoin];
}

- (void)addEnemy {
    if (gameOver)
        return;
    EnemySprite *enemy = [[EnemySprite alloc] initWithType:(EnemyType)kEnemyTypeTap/*rand() % 2*/];

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

- (void)addBombAtPosX:(CGFloat)posX {

    BombSprite *newBomb = [[BombSprite alloc] initWithStartPos:ccp(posX, 500) groundY:GROUND_Y];
    newBomb.delegate = self;
    [bombs addObject:newBomb];
    [mainSpriteBatch addChild:newBomb];
}

- (void)scheduleNewEnemySpawn {

    enemySpawnTime = ENEMY_SPAWN_TIME + (float)rand() / RAND_MAX * ENEMY_SPAWN_DELTA_TIME;
}

-(void)coinEndedCashingAnimation:(CoinSprite*)coin {
    
    [coin removeFromParentAndCleanup:YES];
}

- (void)makeBombExplosionAtPos:(CGPoint)pos {

    for (EnemySprite *enemy in tapEnemies) {
        if (ccpLengthSQ(ccpSub(enemy.position, pos)) < BOMB_KILL_PERIMETER * BOMB_KILL_PERIMETER) {
            [killedTapEnemies addObject:enemy];
            [self kill:enemy];
        }
    }

    for (EnemySprite *enemy in swipeEnemies) {
        if (ccpLengthSQ(ccpSub(enemy.position, pos)) < BOMB_KILL_PERIMETER * BOMB_KILL_PERIMETER) {
            [killedSwipeEnemies addObject:enemy];
            [self kill:enemy];
        }
    }

    CCParticleSystem *explosionParticleSystem = [[CCParticleSystemQuad alloc] initWithFile:kExplosionParticleSystemFileName];
    explosionParticleSystem.autoRemoveOnFinish = YES;
    explosionParticleSystem.position = pos;
    [particleBatchNode addChild:explosionParticleSystem];
}

#pragma mark - CoinSpriteDelegate

- (void)coinDidDie:(CoinSprite *)coinSprite {

    [killedCoins addObject:coinSprite];
}

#pragma mark - BombSpriteDelegate

- (void)bombDidDie:(BombSprite *)bombSprite {

    [killedBombs addObject:bombSprite];
    [self makeBombExplosionAtPos:bombSprite.position];
}

#pragma EnemySpriteDelegate

- (void)enemyDidClimbWall:(EnemySprite*)enemy {

    if (enemy.type == kEnemyTypeTap) {

        [killedTapEnemies addObject:enemy];
    }
    else {

        [killedSwipeEnemies addObject:enemy];
    }
    [AppDelegate player].health -= ENEMY_ATTACK_FORCE;
    
    if ([AppDelegate player].health == 0) {
        [self gameOver];
    }
    [self updateUI];
}

#pragma mark - BombSpawnerDelegate

- (void)bombSpawnerWantsBombToSpawn:(BombSpawner *)_bombSpawner {

    [self addBombAtPosX:bombSpawner.pos.x];
}

#pragma mark - Gestures

- (void)longPressStarted:(CGPoint)pos {

    NSLog(@"LongPress start");
    [self dropBombAtPos:pos];
}

- (void)longPressEnded {

    NSLog(@"LongPress end");    
    [bombSpawner cancelSpawning];
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

    [[AudioManager sharedManager] scream];
    [[AudioManager sharedManager] stopBackgroundMusic];

    EnemySprite *nearestEnemy = nil;
    CoinSprite *nearestCoin = nil;
    float nearestDistance = -1;
    
    for (CoinSprite *coin in coins) {
        
        if (nearestDistance < 0) {
            
            nearestDistance = ccpDistanceSQ(coin.position, pos);
            nearestCoin = coin;
        }
        else {
            
            float distance = ccpDistanceSQ(coin.position, pos);
            
            if (distance < nearestDistance) {
                
                nearestDistance = distance;
                nearestCoin = coin;
            }
        }
    }
    
    if (nearestCoin && nearestDistance < TAP_MIN_DISTANCE2) {
        [coins removeObject:nearestCoin];

        CCAction *action = [CCEaseOut actionWithAction:[CCSequence actions:[CCMoveTo actionWithDuration:1.0f position:coinsSprite.position],
                                                        [CCCallFuncN actionWithTarget:self selector:@selector(coinEndedCashingAnimation:)], nil] rate:2.0f];
        
        [nearestCoin runAction:action];
        [self addCoin];
        return;
    }
    
    for (EnemySprite *enemy in tapEnemies) {
        
        if (nearestDistance < 0) {
            
            nearestDistance = ccpDistanceSQ(enemy.position, pos);
            nearestEnemy = enemy;
        }
        else {
            
            float distance = ccpDistanceSQ(enemy.position, pos);
            
            if (distance < nearestDistance) {
                
                nearestDistance = distance;
                nearestEnemy = enemy;
            }
        }
    }
    
    if (nearestEnemy && nearestDistance < TAP_MIN_DISTANCE2) {
        
        [nearestEnemy throwFromWall];
    }
    
}

#pragma mark -

- (void) kill:(EnemySprite *)enemy
{
    [AppDelegate player].kills++;
    [self addCoinAtPos:enemy.position];
    [self updateUI];
}

- (void) addCoin
{
    [AppDelegate player].coins++;
    [self updateUI];
}

- (void) dropBombAtPos:(CGPoint)pos
{
    if ([AppDelegate player].coins >= BOMB_COINS_COST) {
        [bombSpawner startSpawningAtPos:pos];
        [[AppDelegate player] updateDropBombCount:1];

        [AppDelegate player].coins -= BOMB_COINS_COST;
        [self updateUI];
    }
}

- (void) gameOver
{
    if (gameOver) {
        return;
    }

    gameOver = YES;
    CGSize screen = [CCDirector sharedDirector].winSize;
    gameOverLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, screen.width, screen.height)];
    [gameOverLabel setTextColor:[UIColor whiteColor]];
    [gameOverLabel setTextAlignment:NSTextAlignmentCenter];
    [gameOverLabel setFont:[UIFont fontWithName:fontName size:30]];
    [gameOverLabel setText:@"Game Over, Loser!"];
    [gameOverLabel setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5]];
    [[CCDirector sharedDirector].view addSubview:gameOverLabel];

    restartButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [restartButton setFrame:CGRectMake((screen.width - 126.0) / 2, (screen.height - 44.0) / 2 + 50.0, 126.0, 44.0)];
    [restartButton setTitle:@"Restart" forState:UIControlStateNormal];
    [restartButton.titleLabel setFont:[UIFont fontWithName:fontName size:20]];
    [restartButton addTarget:self action:@selector(restart) forControlEvents:UIControlEventTouchUpInside];
    [[CCDirector sharedDirector].view addSubview:restartButton];
}

- (void) restart
{
    [gameOverLabel removeFromSuperview];
    gameOverLabel = nil;
    [restartButton removeFromSuperview];
    restartButton = nil;

    [killedBombs addObjectsFromArray:bombs];
    [killedCoins addObjectsFromArray:coins];
    [killedTapEnemies addObjectsFromArray:tapEnemies];
    [killedSwipeEnemies addObjectsFromArray:swipeEnemies];

    [[AppDelegate player] newGame];
    [self updateUI];
    gameOver = NO;
}


#pragma mark - Update

- (void)calc:(ccTime)deltaTime {

    // Gestures
    [gestureRecognizer update:deltaTime];

    // Game objects
    [bombSpawner calc:deltaTime];

    for (CoinSprite *coin in coins) {
        [coin calc:deltaTime];
    }

    for (BombSprite *bomb in bombs) {
        [bomb calc:deltaTime];
    }
    
    for (EnemySprite *enemy in tapEnemies) {
        [enemy calc:deltaTime];
    }

    for (EnemySprite *enemy in swipeEnemies) {
        [enemy calc:deltaTime];
    }

    // Killed
    for (CoinSprite *coin in killedCoins) {
        [coins removeObject:coin];
        [coin removeFromParentAndCleanup:YES];
    }
    [killedCoins removeAllObjects];

    for (BombSprite *bomb in killedBombs) {
        [bombs removeObject:bomb];
        [bomb removeFromParentAndCleanup:YES];
    }

    for (EnemySprite *killedEnemy in killedTapEnemies) {

        [tapEnemies removeObject:killedEnemy];
        [killedEnemy removeFromParentAndCleanup:YES];
    }
    [killedTapEnemies removeAllObjects];

    for (EnemySprite *killedEnemy in killedSwipeEnemies) {

        [swipeEnemies removeObject:killedEnemy];
        [killedEnemy removeFromParentAndCleanup:YES];
    }
    [killedSwipeEnemies removeAllObjects];

    enemySpawnTime -= deltaTime;
    if (enemySpawnTime < 0) {
        
        [self addEnemy];
    }
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

        [self calc:FRAME_TIME_INTERVAL];
        calcTime -= FRAME_TIME_INTERVAL;
    }
}

@end