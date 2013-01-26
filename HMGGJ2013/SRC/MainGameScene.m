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
#import "ScreenShaker.h"
#import "SlimeBubbleSprite.h"

#define IS_WIDESCREEN ([[UIScreen mainScreen] bounds].size.height == 568.0f)

#define TOP_HEIGHT 80

#define MAX_DELTA_TIME 0.1f
#define MAX_CALC_TIME 0.1f
#define FRAME_TIME_INTERVAL (1.0f / 60)

#define ENEMY_ATTACK_FORCE 5

#define BOMB_COINS_COST 2
#define BOMB_KILL_PERIMETER 85

#define GAME_OBJECTS_Z_ORDER 30

#define TAP_MIN_DISTANCE2 (60*60)
#define SWIPE_MIN_DISTANCE2 (20*20)


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

    ScreenShaker *screenShaker;    

    CCSpriteBatchNode *mainSpriteBatch;
    
    NSMutableArray *tapEnemies;
    NSMutableArray *swipeEnemies;
    NSMutableArray *coins;
    NSMutableArray *bombs;
    NSMutableArray *enemyBodyDebrises;
    NSMutableArray *bubbles;

    NSMutableArray *killedCoins;
    NSMutableArray *killedTapEnemies;
    NSMutableArray *killedSwipeEnemies;
    NSMutableArray *killedBombs;
    NSMutableArray *killedEnemyBodyDebrises;
    NSMutableArray *killedBubbles;    

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
    
    CCSprite *killSprite;
    UILabel *killsLabel;
    
    CCSprite *coinsSprite;
    UILabel *coinsLabel;
    UILabel *healthLabel;
    
    UILabel *gameOverLabel;
    UIButton *restartButton;
    
    UIImageView *pauseButton;
    
    UIView *rageView;
    UIImageView *rageBackgroundView;
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

    // Screen shaker
    screenShaker = [[ScreenShaker alloc] init];

    // Game objects
    tapEnemies = [[NSMutableArray alloc] initWithCapacity:100];
    swipeEnemies = [[NSMutableArray alloc] initWithCapacity:100];
    coins = [[NSMutableArray alloc] initWithCapacity:100];
    bombs = [[NSMutableArray alloc] initWithCapacity:10];
    enemyBodyDebrises = [[NSMutableArray alloc] initWithCapacity:50];
    bubbles = [[NSMutableArray alloc] initWithCapacity:40];

    killedCoins = [[NSMutableArray alloc] initWithCapacity:10];
    killedTapEnemies = [[NSMutableArray alloc] initWithCapacity:100];
    killedSwipeEnemies = [[NSMutableArray alloc] initWithCapacity:100];
    killedBombs = [[NSMutableArray alloc] initWithCapacity:10];
    killedEnemyBodyDebrises = [[NSMutableArray alloc] initWithCapacity:50];
    killedBubbles = [[NSMutableArray alloc] initWithCapacity:2];    

    // Load texture atlas
    CCSpriteFrameCache *frameCache = [CCSpriteFrameCache sharedSpriteFrameCache];
    [frameCache addSpriteFramesWithFile:kGameObjectsSpriteFramesFileName];

    CCSpriteFrame *placeholderSpriteFrame = [frameCache spriteFrameByName:kPlaceholderTextureFrameName];

    // Sprite batch
    mainSpriteBatch = [[CCSpriteBatchNode alloc] initWithFile:placeholderSpriteFrame.textureFilename capacity:100];
    mainSpriteBatch.zOrder = 10;
    [mainSpriteBatch.texture setAliasTexParameters];
    [self addChild:mainSpriteBatch];

    // Particle batch
    particleBatchNode = [[CCParticleBatchNode alloc] initWithFile:kSimpleParticleTextureFileName capacity:10];
    particleBatchNode.zOrder = 20;
    [self addChild:particleBatchNode];

    // Background
    CCSprite *backgroundSprite = [[CCSprite alloc] initWithSpriteFrameName:@"mainBack.png"];
    backgroundSprite.anchorPoint = ccp(0.5, 0.5);
    backgroundSprite.zOrder = 1;
    backgroundSprite.position = ccp([CCDirector sharedDirector].winSize.width * 0.5, [CCDirector sharedDirector].winSize.height * 0.5);
    backgroundSprite.scale = [UIScreen mainScreen].scale * 2;    
    [mainSpriteBatch addChild:backgroundSprite];

    // Monster
    monsterSprite = [[MonsterSprite alloc] init];
    monsterSprite.anchorPoint = ccp(0.5, 0);
    monsterSprite.position = ccp([CCDirector sharedDirector].winSize.width * 0.5, GROUND_Y + 2);
    monsterSprite.zOrder = 3;
    [mainSpriteBatch addChild:monsterSprite];

    // Slime
    slimeSprite = [[SlimeSprite alloc] initWithWidth:SLIME_WIDTH maxHeight:SLIME_MAX_HEIGHT];
    slimeSprite.anchorPoint = ccp(0.5, 0);
    slimeSprite.position = ccp([CCDirector sharedDirector].winSize.width * 0.5, SLIME_GROUND_Y);
    slimeSprite.zOrder = 10;
    [mainSpriteBatch addChild:slimeSprite];

    // Foreground
    CCSprite *foregroundSprite = [[CCSprite alloc] initWithSpriteFrameName:@"tankGraphic.png"];
    foregroundSprite.anchorPoint = ccp(0.5, 0);
    foregroundSprite.position = ccp([CCDirector sharedDirector].winSize.width * 0.5, GROUND_Y - 1);
    foregroundSprite.scale = [UIScreen mainScreen].scale * 2;
    foregroundSprite.zOrder = 20;
    [mainSpriteBatch addChild:foregroundSprite];

    // Bomb spawner
    bombSpawner = [[BombSpawner alloc] init];
    bombSpawner.delegate = self;
    bombSpawner.zOrder = 10000;
    [mainSpriteBatch addChild:bombSpawner];

    // Floor
    CCSprite *floorSprite = [[CCSprite alloc] initWithSpriteFrameName:@"Floor.png"];
    floorSprite.zOrder = 30;
    floorSprite.anchorPoint = ccp(0.5, 1);
    floorSprite.position = ccp([CCDirector sharedDirector].winSize.width * 0.5, GROUND_Y - 1);
    floorSprite.scale = [UIScreen mainScreen].scale * 2;
    [self addChild:floorSprite];
    
    // Master Control Program
    masterControlProgram = [[MasterControlProgram alloc] init];
    masterControlProgram.mainframe = self;

    // Update
    [self scheduleUpdate];
    
    //[[AudioManager sharedManager] startBackgroundTrack];
    
    [self initUI];
}

- (void) initUI {
    fontName = @"Visitor TT1 BRK";
    UIFont *font = [UIFont fontWithName:fontName size:20];
    
    CGFloat labelWidth = (320.0 - 10.0) / 2;
    CGSize contentSize = [CCDirector sharedDirector].winSize;
    killSprite = [[CCSprite alloc] initWithSpriteFrameName:@"skull.png"];
    killSprite.anchorPoint = ccp(0, 0);
    killSprite.scale = [UIScreen mainScreen].scale * 2;
    killSprite.position = ccp(5.0, contentSize.height - killSprite.contentSize.height * killSprite.scale - 15.0);
    [mainSpriteBatch addChild:killSprite];
    
    killsLabel = [[UILabel alloc] initWithFrame:CGRectMake(38.0, 17.0, labelWidth - 28.0, 21.0)];
    [killsLabel setTextAlignment:NSTextAlignmentLeft];
    [killsLabel setTextColor:[UIColor whiteColor]];
    [killsLabel setBackgroundColor:[UIColor clearColor]];
    [killsLabel setFont:font];
    [[CCDirector sharedDirector].view addSubview:killsLabel];
    
    coinsSprite = [[CCSprite alloc] initWithSpriteFrameName:@"coin1.png"];
    coinsSprite.anchorPoint = ccp(0, 0);
    coinsSprite.zOrder = GAME_OBJECTS_Z_ORDER;
    coinsSprite.scale = [UIScreen mainScreen].scale * 2;
    coinsSprite.position = ccp(contentSize.width - 30.0, contentSize.height - coinsSprite.contentSize.height * coinsSprite.scale - 15.0);
    [mainSpriteBatch addChild:coinsSprite];
    
    coinsLabel = [[UILabel alloc] initWithFrame:CGRectMake(labelWidth + 5, 17.0, labelWidth - 30.0, 21.0)];
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
    //[[CCDirector sharedDirector].view addSubview:healthLabel];
    
    UIImage *image;
    CGFloat offset = 0.0;
    if (contentSize.height == 480.0)
        offset = 2.0;
    else
        offset = 22.0;
    image = [UIImage imageNamed:@"progressBarBack"];
    image = [UIImage imageWithCGImage:[image CGImage] scale:[[UIScreen mainScreen] scale] * 2 orientation:image.imageOrientation];
    rageBackgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(16.0, contentSize.height - 24.0 - 8.0 - offset, 288.0, 24.0)];
    [rageBackgroundView setImage:image];
    [rageBackgroundView.layer setMagnificationFilter:kCAFilterNearest];
    [[CCDirector sharedDirector].view addSubview:rageBackgroundView];
    
    image = [UIImage imageNamed:@"progressBar"];
    image = [UIImage imageWithCGImage:[image CGImage] scale:[[UIScreen mainScreen] scale] * 2 orientation:image.imageOrientation];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 272.0, 8.0)];
    [imageView setImage:image];
    [imageView.layer setMagnificationFilter:kCAFilterNearest];
    rageView = [[UIView alloc] initWithFrame:CGRectMake(24.0, contentSize.height - 24.0 - offset, 0.0, 8.0)];
    [rageView setClipsToBounds:YES];
    [rageView addSubview:imageView];
    [[CCDirector sharedDirector].view addSubview:rageView];
    
    image = [UIImage imageNamed:@"pause"];
    image = [UIImage imageWithCGImage:[image CGImage] scale:[[UIScreen mainScreen] scale] * 2 orientation:image.imageOrientation];
    pauseButton = [[UIImageView alloc] initWithFrame:CGRectMake((contentSize.width - 24.0) / 2, 13.0, 24.0, 28.0)];
    [pauseButton.layer setMagnificationFilter:kCAFilterNearest];
    [pauseButton setImage:image];
    [pauseButton setUserInteractionEnabled:YES];
    [pauseButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)]];
    [[CCDirector sharedDirector].view addSubview:pauseButton];
    [self updateUI];
    
    int64_t delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self displayAchievementWithName:@"killingspree"];
    });
}

- (void) updateUI {
    [killsLabel setText:[NSString stringWithFormat:@"%i", [AppDelegate player].points]];
    [coinsLabel setText:[NSString stringWithFormat:@"%i", [AppDelegate player].coins]];
    [healthLabel setText:[NSString stringWithFormat:@"%i", [AppDelegate player].health]];

    CGSize contentSize = [CCDirector sharedDirector].winSize;
    [rageView setFrame:CGRectMake(24.0, contentSize.height - 24.0 - 22.0, 272.0 * [AppDelegate player].rage, 8.0)];
}

#pragma mark - Objects

- (void)addBubble:(CGPoint)pos {

    SlimeBubbleSprite *newBubble = [[SlimeBubbleSprite alloc] initWithPos:pos];
    newBubble.zOrder = 7;
    [mainSpriteBatch addChild:newBubble];
    [bubbles addObject:newBubble];
}

- (void)addCoinAtPos:(CGPoint)pos {

    CoinSprite *newCoin = [[CoinSprite alloc] initWithStartPos:pos groundY:GROUND_Y];
    newCoin.zOrder = GAME_OBJECTS_Z_ORDER;
    newCoin.delegate = self;
    [coins addObject:newCoin];
    [mainSpriteBatch addChild:newCoin];
}

- (void)addEnemy:(EnemyType)type {
    if (gameOver)
        return;
    EnemySprite *enemy = [[EnemySprite alloc] initWithType:type];

    if (enemy.type == kEnemyTypeSwipe) {

        [swipeEnemies addObject:enemy];
    }
    else {

        [tapEnemies addObject:enemy];
    }
    enemy.zOrder = GAME_OBJECTS_Z_ORDER;
    [mainSpriteBatch addChild:enemy];
    enemy.delegate = self;
    
    
}

- (void)addBombAtPosX:(CGFloat)posX {

    BombSprite *newBomb = [[BombSprite alloc] initWithStartPos:ccp(posX, 520 + (rand() / (float)RAND_MAX) * 20) groundY:GROUND_Y];
    newBomb.zOrder = GAME_OBJECTS_Z_ORDER;
    newBomb.delegate = self;
    [bombs addObject:newBomb];
    [mainSpriteBatch addChild:newBomb];
}

-(void)coinEndedCashingAnimation:(CoinSprite*)coin {
    
    [coin removeFromParentAndCleanup:YES];
}

- (void)createEnemyBodyExplosionAtPos:(CGPoint)pos enemyType:(EnemyType)enemyType {

    int numberOfBodyPars = rand() % 3 + 3;

    for (int i = 0; i < numberOfBodyPars; i++) {

        // Particle system
        CCParticleSystemQuad *bloodParticleSystem = [[CCParticleSystemQuad alloc] initWithFile:@"BloodParticleSystem.plist"];
        bloodParticleSystem.position = pos;
        [particleBatchNode addChild:bloodParticleSystem];

        // Debris
        float angle = M_PI * (rand() / (float)RAND_MAX) - M_PI_2;
        CGPoint randVelocity;
        randVelocity.x = sinf(angle) * 1500.0f;
        randVelocity.y = cosf(angle) * 1500.0f;
        EnemyBodyDebris *enemyBodyDebris = [[EnemyBodyDebris alloc] init:enemyType velocity:randVelocity spaceBounds:CGRectMake(0, GROUND_Y, [CCDirector sharedDirector].winSize.width, [CCDirector sharedDirector].winSize.height - GROUND_Y)];
        enemyBodyDebris.bloodParticleSystem = bloodParticleSystem;
        enemyBodyDebris.position = pos;
        enemyBodyDebris.delegate = self;
        enemyBodyDebris.zOrder = GAME_OBJECTS_Z_ORDER - 1;
        [enemyBodyDebrises addObject:enemyBodyDebris];
        [mainSpriteBatch addChild:enemyBodyDebris];
    }
}

- (void)makeBombExplosionAtPos:(CGPoint)pos {
    
    NSInteger kills = 0;
    
    for (EnemySprite *enemy in tapEnemies) {
        if (ccpLengthSQ(ccpSub(enemy.position, pos)) < BOMB_KILL_PERIMETER * BOMB_KILL_PERIMETER) {

            [killedTapEnemies addObject:enemy];

            [self createEnemyBodyExplosionAtPos:enemy.position enemyType:enemy.type];
            [self enemyDidDie:enemy];

            kills++;
        }
    }

    for (EnemySprite *enemy in swipeEnemies) {
        if (ccpLengthSQ(ccpSub(enemy.position, pos)) < BOMB_KILL_PERIMETER * BOMB_KILL_PERIMETER) {

            [killedSwipeEnemies addObject:enemy];

            [self createEnemyBodyExplosionAtPos:enemy.position enemyType:enemy.type];
            [self enemyDidDie:enemy];
            kills++;
        }
    }
    [AppDelegate player].points += kills;
    [self updateUI];

    CCParticleSystemQuad *explosionParticleSystem = [[CCParticleSystemQuad alloc] initWithFile:kExplosionParticleSystemFileName];
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
    [screenShaker shake];
}

#pragma mark - EnemySpriteDelegate

- (void)enemyDidClimbWall:(EnemySprite*)enemy {

    if (enemy.type == kEnemyTypeTap) {

        [killedTapEnemies addObject:enemy];
    }
    else {

        [killedSwipeEnemies addObject:enemy];
    }
    [AppDelegate player].health -= ENEMY_ATTACK_FORCE;
    
    if ([AppDelegate player].health == 0) {
        [self showGameOver];
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

#pragma mark - EnemyBodyDebrisDelegate

- (void)enemyBodyDebrisDidDie:(EnemyBodyDebris *)enemyBodyDebris {

    [enemyBodyDebris.bloodParticleSystem removeFromParentAndCleanup:YES];

    [killedEnemyBodyDebrises addObject:enemyBodyDebris];
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
        [self coinWasAdded];
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

- (void) dismiss {
    [[CCDirector sharedDirector] dismissViewControllerAnimated:YES completion:^{
        [[CCDirector sharedDirector] end];
    }];
}

#pragma mark -

- (void) enemyDidDie:(EnemySprite *)enemy
{
    [AppDelegate player].kills++;
    [self addCoinAtPos:enemy.position];
    [self updateUI];
}

- (void) coinWasAdded
{
    [AppDelegate player].coins++;
    [self updateUI];
}

- (void) displayAchievementWithName:(NSString *)name
{
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    
    UIImage *image = [UIImage imageNamed:name];
    CGSize size = [image size];
    CGFloat scale = [[UIScreen mainScreen] scale];
    image = [UIImage imageWithCGImage:[image CGImage] scale:scale * 2 orientation:image.imageOrientation];
    UIImageView *attachmentView = [[UIImageView alloc] initWithFrame:CGRectMake((winSize.width - (size.width * scale)) / 2, (winSize.height - (size.height * scale)) / 2,
                                                                                size.width * scale, size.height * scale)];
    [attachmentView setImage:image];
    [attachmentView setAlpha:0];
    [[CCDirector sharedDirector].view  addSubview:attachmentView];
    
    [UIView animateWithDuration:0.5 animations:^{
        [attachmentView setAlpha:1];
        int64_t delayInSeconds = 2.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [UIView animateWithDuration:0.5 animations:^{
                [attachmentView setAlpha:0];
            } completion:^(BOOL finished) {
                [attachmentView removeFromSuperview];
            }];
        });
    }];
}

- (void) showGameOver
{
    if (gameOver) {
        return;
    }
    gestureRecognizer.delegate = nil;
    masterControlProgram = nil;
    
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
    [restartButton addTarget:self action:@selector(restartGame) forControlEvents:UIControlEventTouchUpInside];
    [[CCDirector sharedDirector].view addSubview:restartButton];

    [[CCDirector sharedDirector].view bringSubviewToFront:coinsLabel];
    [coinsSprite setZOrder:10000];
    [[CCDirector sharedDirector].view bringSubviewToFront:killsLabel];
    [killSprite setZOrder:10000];
    [[CCDirector sharedDirector].view bringSubviewToFront:pauseButton];
}

- (void) restartGame
{
    masterControlProgram = [[MasterControlProgram alloc] init];
    masterControlProgram.mainframe = self;
    
    [gameOverLabel removeFromSuperview];
    gameOverLabel = nil;
    [restartButton removeFromSuperview];
    restartButton = nil;

    [killedBombs addObjectsFromArray:bombs];
    [killedCoins addObjectsFromArray:coins];
    [killedTapEnemies addObjectsFromArray:tapEnemies];
    [killedSwipeEnemies addObjectsFromArray:swipeEnemies];

    gestureRecognizer.delegate = self; 
    
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

    for (EnemyBodyDebris *enemyBodyDebris in enemyBodyDebrises) {
        [enemyBodyDebris calc:deltaTime];
    }

    for (SlimeBubbleSprite *bubble in bubbles) {
        [bubble calc:deltaTime];
        if (bubble.position.y > CGRectGetMaxY(slimeSprite.boundingBox) - bubble.boundingBox.size.height) {
            [killedBubbles addObject:bubble];
        }
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

    for (EnemyBodyDebris *enemyBodyDebris in killedEnemyBodyDebrises) {

        [enemyBodyDebrises removeObject:enemyBodyDebris];
        [enemyBodyDebris removeFromParentAndCleanup:YES];
    }
    [killedEnemyBodyDebrises removeAllObjects];

    for (SlimeBubbleSprite *bubble in killedBubbles) {
        [bubbles removeObject:bubble];
        [bubble removeFromParentAndCleanup:YES];
    }
    [killedBubbles removeAllObjects];

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
    [[AppDelegate player] calc:deltaTime];

    [slimeSprite setEnergy:[AppDelegate player].health * 0.01];
    [slimeSprite calc:deltaTime];

    [monsterSprite calc:deltaTime];

    // Shake
    [screenShaker calc:deltaTime];
    self.position = screenShaker.offset;

    // Add bubbles
    if (rand() % 100 == 0) {
        [self addBubble:ccp(slimeSprite.boundingBox.origin.x + (slimeSprite.boundingBox.size.width - 40) * rand() / RAND_MAX + 20, GROUND_Y + 5 + rand() % 7)];
    }
    [self updateUI];
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