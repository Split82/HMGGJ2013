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
#import "SlimeSprite.h"
#import "MonsterSprite.h"
#import "MasterControlProgram.h"

#define TOP_HEIGHT 80

#define MAX_DELTA_TIME 0.1f
#define MAX_CALC_TIME 0.1f
#define FRAME_TIME_INTERVAL (1.0f / 60)

#define ENEMY_ATTACK_FORCE 5

#define BOMB_COINS_COST 2
#define BOMB_KILL_PERIMETER 85

#define TAP_MIN_DISTANCE2 (60*60)
#define SWIPE_MIN_DISTANCE2 (20*20)

#define GROUND_Y 45

float lineSegmentPointDistance2(CGPoint v, CGPoint w, CGPoint p) {
    // Return minimum distance between line segment vw and point p
    const float l2 = ccpDistanceSQ(v, w);  // i.e. |w-v|^2 -  avoid a sqrt
    if (l2 == 0.0) return ccpDistanceSQ(p, v);   // v == w case
    // Consider the line extending the segment, parameterized as v + t (w - v).
    // We find projection of point p onto the line.
    // It falls where t = [(p-v) . (w-v)] / |w-v|^2
    const float t = ccpDot(ccpSub(p, v), ccpSub(w, v)) / l2;
    if (t < 0.0) return ccpDistanceSQ(p, v);       // Beyond the 'v' end of the segment
    else if (t > 1.0) return ccpDistanceSQ(p, w);  // Beyond the 'w' end of the segment
    const CGPoint projection = ccpAdd(v, ccpMult(ccpSub(w, v), t));  // Projection falls on the segment
    return ccpDistanceSQ(p, projection);
}

#define SLIME_WIDTH 280
#define SLIME_GROUND_Y (GROUND_Y + 1)
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
    SlimeSprite *slimeSprite;
    MonsterSprite *monsterSprite;
    
    MasterControlProgram *masterControlProgram;
    
    CCParticleBatchNode *particleBatchNode;

    // State vars
    BOOL sceneInitWasPerformed;
    BOOL gameOver;
    
    // UI vars
    NSString *fontName;
    UILabel *killsLabel;
    CCSprite *coinsSprite;
    UILabel *coinsLabel;
    UILabel *healthLabel;
    
    UILabel *gameOverLabel;
    UIButton *restartButton;
    
    UIView *rageView;
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

    // Monster
    monsterSprite = [[MonsterSprite alloc] init];
    monsterSprite.anchorPoint = ccp(0.5, 0);
    monsterSprite.position = ccp([CCDirector sharedDirector].winSize.width * 0.5, GROUND_Y + 1);
    [mainSpriteBatch addChild:monsterSprite];

    // Slime
    slimeSprite = [[SlimeSprite alloc] initWithWidth:SLIME_WIDTH maxHeight:SLIME_MAX_HEIGHT];
    slimeSprite.anchorPoint = ccp(0.5, 0);
    slimeSprite.position = ccp([CCDirector sharedDirector].winSize.width * 0.5, SLIME_GROUND_Y);
    [mainSpriteBatch addChild:slimeSprite];

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
    
    // Master Control Program
    masterControlProgram = [[MasterControlProgram alloc] init];
    masterControlProgram.mainframe = self;

    [self scheduleUpdate];
    
    //[[AudioManager sharedManager] startBackgroundTrack];
    
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
    
    rageView = [[UIView alloc] initWithFrame:CGRectMake(0.0, [CCDirector sharedDirector].winSize.height - 5.0, 0.0, 5.0)];
    [rageView setBackgroundColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:0.5]];
    [[CCDirector sharedDirector].view addSubview:rageView];
    
    [self updateUI];
}

- (void) updateUI {
    [killsLabel setText:[NSString stringWithFormat:@"points %i", [AppDelegate player].points]];
    [coinsLabel setText:[NSString stringWithFormat:@"coins %i", [AppDelegate player].coins]];
    [healthLabel setText:[NSString stringWithFormat:@"%i", [AppDelegate player].health]];
    
    CGSize size = [coinsLabel.text sizeWithFont:coinsLabel.font forWidth:coinsLabel.frame.size.width lineBreakMode:coinsLabel.lineBreakMode];
    coinsSprite.position = ccp([CCDirector sharedDirector].winSize.width - size.width - 43.0, coinsSprite.position.y);
    
    [rageView setFrame:CGRectMake(0.0, [CCDirector sharedDirector].winSize.height - 5.0, 320 * [AppDelegate player].rage, 5.0)];
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
    EnemySprite *enemy = [[EnemySprite alloc] initWithType:(EnemyType)rand() % 2];

    if (enemy.type == kEnemyTypeSwipe) {

        [swipeEnemies addObject:enemy];
    }
    else {

        [tapEnemies addObject:enemy];
    }

    [mainSpriteBatch addChild:enemy];
    enemy.delegate = self;
    
    
}

- (void)addBombAtPosX:(CGFloat)posX {

    BombSprite *newBomb = [[BombSprite alloc] initWithStartPos:ccp(posX, 520 + (rand() / (float)RAND_MAX) * 20) groundY:GROUND_Y];
    newBomb.delegate = self;
    [bombs addObject:newBomb];
    [mainSpriteBatch addChild:newBomb];
}

-(void)coinEndedCashingAnimation:(CoinSprite*)coin {
    
    [coin removeFromParentAndCleanup:YES];
}

- (void)makeBombExplosionAtPos:(CGPoint)pos {
    NSInteger kills = 0;
    
    for (EnemySprite *enemy in tapEnemies) {
        if (ccpLengthSQ(ccpSub(enemy.position, pos)) < BOMB_KILL_PERIMETER * BOMB_KILL_PERIMETER) {
            [killedTapEnemies addObject:enemy];
            [self kill:enemy];
            kills++;
        }
    }

    for (EnemySprite *enemy in swipeEnemies) {
        if (ccpLengthSQ(ccpSub(enemy.position, pos)) < BOMB_KILL_PERIMETER * BOMB_KILL_PERIMETER) {
            [killedSwipeEnemies addObject:enemy];
            [self kill:enemy];
            kills++;
        }
    }
    [AppDelegate player].points += kills;
    [self updateUI];

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

    [[AppDelegate player] updateDropBombCount:1];

    [AppDelegate player].coins -= BOMB_COINS_COST;
    [self updateUI];
}

#pragma mark - MainframeDelegate

- (int)countTapEnemies {
    
    return [tapEnemies count];
}

- (int)countSwipeEnemies {
    
    return [swipeEnemies count];
}

#pragma mark - Gestures

- (void)longPressStarted:(CGPoint)pos {

    if ([AppDelegate player].coins >= BOMB_COINS_COST) {
        [bombSpawner startSpawningAtPos:pos];
    }
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
    
    for (EnemySprite *enemy in swipeEnemies) {
        
        if (lineSegmentPointDistance2(gestureRecognizer.lastPos, pos, enemy.position) < SWIPE_MIN_DISTANCE2) {
            
            [enemy throwFromWall];
        }
    }
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

    [masterControlProgram calc:deltaTime];
    
    if ([AppDelegate player].rage >= 1) {
        [self addBombAtPosX:25.0];
        [self addBombAtPosX:85.0];
        [self addBombAtPosX:155.0];
        [self addBombAtPosX:225.0];
        [self addBombAtPosX:295.0];
        [[AppDelegate player] updateDropBombCount:5];
        [self updateUI];
        [AppDelegate player].rage = 0;
    }

    [slimeSprite setEnergy:[AppDelegate player].health * 0.01];
    [slimeSprite calc:deltaTime];

    [monsterSprite calc:deltaTime];
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