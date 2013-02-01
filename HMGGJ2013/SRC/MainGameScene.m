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
#import "MonsterHearth.h"
#import "MainMenuGameScene.h"
#import "MenuCoinSprite.h"
#import "MenuButton.h"

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
#define TAP_THROW_MIN_DISTANCE2 (60*60)
#define TAP_PICK_COIN_MIN_DISTANCE2 (50*50)
#define SWIPE_MIN_DISTANCE2 (30*30)

#define SLIME_WIDTH 280
#define SLIME_GROUND_Y (GROUND_Y + 1)
#define SLIME_MAX_HEIGHT 300

#define MAX_BODY_DEBRIS_COUNT 300
#define BLOODY_MARY_BODY_DEBRIS_COUNT 150

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
    NSMutableArray *labels;
    NSMutableArray *flyingSkulls;
    NSMutableArray *bombExplosions;
    NSMutableArray *lightnings;
    NSMutableArray *waterSplashes;
    NSMutableArray *trails;

    NSMutableArray *killedCoins;
    NSMutableArray *killedTapEnemies;
    NSMutableArray *killedSwipeEnemies;
    NSMutableArray *killedBombs;
    NSMutableArray *killedEnemyBodyDebrises;
    NSMutableArray *killedBubbles;
    NSMutableArray *killedLabels;
    NSMutableArray *killedFlyingSkulls;
    NSMutableArray *killedBombExplosions;
    NSMutableArray *killedLightnings;
    NSMutableArray *killedWaterSplashes;
    NSMutableArray *killedTrails;
    
    NSMutableArray *unusedBloodParticleSystems;

    BombSpawner *bombSpawner;
    SlimeSprite *slimeSprite;
    CCSprite *slimeTop;
    MonsterSprite *monsterSprite;
    MonsterHearth *monsterHearth;
    
    NSMutableArray *menuCoins;
    MonsterHearth *menuHeart;
    
    MasterControlProgram *masterControlProgram;
    
    CCParticleBatchNode *particleBatchNode;

    int numberOfKillsInLastFrame;

    // State vars
    BOOL sceneInitWasPerformed;
    
    // UI vars
    UIView *mainView;
    
    NSString *lastKill;
    CCSprite *killSprite;
    CCLabelBMFont *killsLabel;
    
    NSString *lastCoin;
    CCSprite *coinsSprite;
    CCLabelBMFont *coinsLabel;
    
    MenuButton *pauseButton;
    MenuButton *restartButton;
    
    UIView *rageProgressView;
    UIImageView *rageBackgroundView;
    CCLayer *menuBackground;
    
    CCLayer *gameOverLayer;
    
    Trail *currentTrail;
    // Leaderboard
    GKLeaderboard *leaderboard;
    
    BOOL bombSpawning;
}

@end


@implementation MainGameScene

@synthesize menuBackground;
@synthesize mainView;
@synthesize gameOver;

- (void)onEnter {

    [super onEnter];
    
    gestureRecognizer = [[GestureRecognizer alloc] init];
    gestureRecognizer.delegate = self;
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:gestureRecognizer priority:0 swallowsTouches:YES];

    [self initScene];
}

- (void)onExit {

}

- (void)initScene {

    if (sceneInitWasPerformed) {
        return;
    }
    sceneInitWasPerformed = YES;

    leaderboard = [[GKLeaderboard alloc] init];
    
    // Screen shaker
    screenShaker = [[ScreenShaker alloc] init];

    // Game objects
    tapEnemies = [[NSMutableArray alloc] initWithCapacity:100];
    swipeEnemies = [[NSMutableArray alloc] initWithCapacity:100];
    coins = [[NSMutableArray alloc] initWithCapacity:100];
    bombs = [[NSMutableArray alloc] initWithCapacity:10];
    enemyBodyDebrises = [[NSMutableArray alloc] initWithCapacity:50];
    bubbles = [[NSMutableArray alloc] initWithCapacity:40];
    labels = [[NSMutableArray alloc] initWithCapacity:4];
    flyingSkulls = [[NSMutableArray alloc] initWithCapacity:4];
    bombExplosions = [[NSMutableArray alloc] initWithCapacity:4];
    lightnings = [[NSMutableArray alloc] initWithCapacity:10];
    waterSplashes = [[NSMutableArray alloc] initWithCapacity:10];
    trails = [[NSMutableArray alloc] initWithCapacity:10];

    killedCoins = [[NSMutableArray alloc] initWithCapacity:10];
    killedTapEnemies = [[NSMutableArray alloc] initWithCapacity:100];
    killedSwipeEnemies = [[NSMutableArray alloc] initWithCapacity:100];
    killedBombs = [[NSMutableArray alloc] initWithCapacity:10];
    killedEnemyBodyDebrises = [[NSMutableArray alloc] initWithCapacity:50];
    killedBubbles = [[NSMutableArray alloc] initWithCapacity:2];
    killedLabels = [[NSMutableArray alloc] initWithCapacity:4];
    killedFlyingSkulls = [[NSMutableArray alloc] initWithCapacity:4];
    killedBombExplosions = [[NSMutableArray alloc] initWithCapacity:4];
    killedLightnings = [[NSMutableArray alloc] initWithCapacity:10];
    killedWaterSplashes = [[NSMutableArray alloc] initWithCapacity:4];
    killedTrails = [[NSMutableArray alloc] initWithCapacity:4];
    
    menuCoins = [[NSMutableArray alloc] initWithCapacity:2];

    // Load texture atlas
    CCSpriteFrameCache *frameCache = [CCSpriteFrameCache sharedSpriteFrameCache];
    [frameCache addSpriteFramesWithFile:kGameObjectsSpriteFramesFileName];

    CCSpriteFrame *placeholderSpriteFrame = [frameCache spriteFrameByName:kPlaceholderTextureFrameName];

    // Load font texture
    CCTexture2D *pixelFontTexture = [[CCTextureCache sharedTextureCache] addImage:@"PixelFont.png"];
    [pixelFontTexture setAliasTexParameters];

    // Sprite batch
    mainSpriteBatch = [[CCSpriteBatchNode alloc] initWithFile:placeholderSpriteFrame.textureFilename capacity:100];
    mainSpriteBatch.zOrder = 10;
    [mainSpriteBatch.texture setAliasTexParameters];
    [self addChild:mainSpriteBatch];

    // Particle batch
    particleBatchNode = [[CCParticleBatchNode alloc] initWithFile:kSimpleParticleTextureFileName capacity:10000];
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

    // Monster hearth
    monsterHearth = [[MonsterHearth alloc] init];
    monsterHearth.anchorPoint = ccp(0.5, 0);
    monsterHearth.position = ccp([CCDirector sharedDirector].winSize.width * 0.5, CGRectGetMaxY(monsterSprite.boundingBox) - 18);
    monsterHearth.zOrder = 4;
    [mainSpriteBatch addChild:monsterHearth];

    // Slime
    slimeSprite = [[SlimeSprite alloc] initWithWidth:SLIME_WIDTH maxHeight:SLIME_MAX_HEIGHT];
    [slimeSprite setActualEnergy:0.5];
    slimeSprite.anchorPoint = ccp(0.5, 0);
    slimeSprite.position = ccp([CCDirector sharedDirector].winSize.width * 0.5, SLIME_GROUND_Y);
    slimeSprite.zOrder = 10;
    [mainSpriteBatch addChild:slimeSprite];

    slimeTop = [[CCSprite alloc] initWithSpriteFrameName:@"tankWaterLevel.png"];
    slimeTop.scale = [UIScreen mainScreen].scale * 2;    
    slimeTop.anchorPoint = ccp(0.5, 0);
    slimeTop.position = ccp([CCDirector sharedDirector].winSize.width * 0.5, CGRectGetMaxY(slimeSprite.boundingBox));
    slimeTop.zOrder = 11;
    [mainSpriteBatch addChild:slimeTop];

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
    
    [[AudioManager sharedManager] startBackgroundMusic];
    bombSpawning = NO;

    
    for (int i = 0; i < MAX_BODY_DEBRIS_COUNT; i++) {
        
        [unusedBloodParticleSystems addObject:[self createBloodParticleSystem:NO]];
    }
    
    [self initUI];
}

- (void)initUI {

    // Main UI container
    mainView = [[UIView alloc] initWithFrame:[CCDirector sharedDirector].view.bounds];
    [mainView setBackgroundColor:[UIColor clearColor]];
    [[CCDirector sharedDirector].view addSubview:mainView];

    CGSize contentSize = [CCDirector sharedDirector].winSize;
    CGFloat offsetY = 0.0;
    if (contentSize.height > 480.0) {
        offsetY = 18.0;
    }

    killSprite = [[CCSprite alloc] initWithSpriteFrameName:@"skull.png"];
    killSprite.anchorPoint = ccp(0, 0);
    killSprite.scale = [UIScreen mainScreen].scale * 2;
    killSprite.position = ccp(5.0, contentSize.height - killSprite.contentSize.height * killSprite.scale - 13.0 - offsetY);
    killSprite.zOrder = 5000;
    [self addChild:killSprite];
    
    coinsSprite = [[CCSprite alloc] initWithSpriteFrameName:@"coin1.png"];
    coinsSprite.anchorPoint = ccp(0.5, 0.5);
    coinsSprite.zOrder = 5000;
    coinsSprite.scale = [UIScreen mainScreen].scale * 2;
    coinsSprite.position = ccp(contentSize.width - 20.0, contentSize.height - 26 - offsetY);
    [self addChild:coinsSprite];

    pauseButton = [[MenuButton alloc] initWithFrame:CGRectMake((contentSize.width - 24.0) / 2 - 10.0, 1.0 + offsetY, 44.0, 48.0)];
    [pauseButton setImage:[UIImage imageNamed:@"pause"]];
    [pauseButton addTarget:self action:@selector(pauseGame) forControlEvents:UIControlEventTouchUpInside];
    [mainView addSubview:pauseButton];

    if (contentSize.height == 480.0) {
        offsetY = 2.0;
    }
    else {
        offsetY = 22.0;
    }
    
    rageBackgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(16.0, contentSize.height - 24.0 - 8.0 - offsetY, 288.0, 24.0)];
    rageBackgroundView.image = [UIImage imageNamed:@"progressBarBack"];
    rageBackgroundView.layer.contentsScale = [UIScreen mainScreen].scale * 2;
    rageBackgroundView.layer.magnificationFilter = kCAFilterNearest;
    [mainView addSubview:rageBackgroundView];

    rageProgressView = [[UIView alloc] initWithFrame:CGRectMake(24.0, contentSize.height - 24.0 - offsetY, 0.0, 8.0)];
    rageProgressView.clipsToBounds = YES;
    [mainView addSubview:rageProgressView];

    UIImageView *rageProgressImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 272, 8.0)];
    rageProgressImageView.image = [UIImage imageNamed:@"progressBar"];
    rageProgressImageView.layer.contentsScale = [UIScreen mainScreen].scale * 2;
    rageProgressImageView.layer.magnificationFilter = kCAFilterNearest;
    [rageProgressView addSubview:rageProgressImageView];
    
    [self updateUI];
}

- (void)updateUI {
    
    if (gameOver) {
        return;
    }
    CGFloat offset = 0.0;
    if ([CCDirector sharedDirector].winSize.height > 480.0)
        offset = 18.0;
    NSString *kill = [NSString stringWithFormat:@"%d", [AppDelegate player].points];
    
    if (![lastKill isEqualToString:kill]) {
        [killsLabel removeFromParentAndCleanup:YES];
        killsLabel = [[CCLabelBMFont alloc] initWithString:kill fntFile:@"PixelFont.fnt"];
        killsLabel.anchorPoint = ccp(0, 0);
        killsLabel.scale = [UIScreen mainScreen].scale * 1.3;
        killsLabel.position = ccp(40.0, [CCDirector sharedDirector].winSize.height - 36.0 - offset);
        killsLabel.zOrder = 5000;
        [killsLabel setColor:ccc3(255, 255, 255)];
        [self addChild:killsLabel];
    }
    lastKill = kill;
    NSString *coin = [NSString stringWithFormat:@"%d", [AppDelegate player].coins];
    
    if (![lastCoin isEqualToString:coin]) {
        [coinsLabel removeFromParentAndCleanup:YES];
        coinsLabel = [[CCLabelBMFont alloc] initWithString:coin fntFile:@"PixelFont.fnt"];
        coinsLabel.anchorPoint = ccp(1, 0);
        coinsLabel.scale = [UIScreen mainScreen].scale * 1.3;
        coinsLabel.position = ccp(320 - 38.0, [CCDirector sharedDirector].winSize.height - 36.0 - offset);
        coinsLabel.zOrder = 5000;
        [coinsLabel setColor:ccc3(255, 255, 255)];
        [self addChild:coinsLabel];
    }
    lastCoin = coin;
    
    CGSize contentSize = [CCDirector sharedDirector].winSize;
    if (contentSize.height == 480.0)
        offset = 2.0;
    else
        offset = 22.0;
    [rageProgressView setFrame:CGRectMake(24.0, contentSize.height - 24.0 - offset, 272.0 * [AppDelegate player].rage, 8.0)];
}

#pragma mark - Objects

- (void)addBubble:(CGPoint)pos {

    SlimeBubbleSprite *newBubble = [[SlimeBubbleSprite alloc] initWithPos:pos];
    newBubble.zOrder = 7;
    [mainSpriteBatch addChild:newBubble];
    [bubbles addObject:newBubble];
}

- (void)addCoinAtPos:(CGPoint)pos {

    CoinSprite *newCoin = [[CoinSprite alloc] initWithStartPos:pos spaceBounds:CGRectMake(0, GROUND_Y, [CCDirector sharedDirector].winSize.width, [CCDirector sharedDirector].winSize.height - GROUND_Y)];
    newCoin.zOrder = GAME_OBJECTS_Z_ORDER;
    newCoin.delegate = self;
    [coins addObject:newCoin];
    [mainSpriteBatch addChild:newCoin];
}

- (void)addMenuCoinAtPos:(CGPoint)pos {
    CoinSprite *newCoin = [[MenuCoinSprite alloc] initWithStartPos:pos spaceBounds:CGRectMake(0, GROUND_Y, [CCDirector sharedDirector].winSize.width, [CCDirector sharedDirector].winSize.height - GROUND_Y)];
    newCoin.zOrder = 4000;
    newCoin.delegate = self;
    [menuCoins addObject:newCoin];
    [self addChild:newCoin];
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

- (CCParticleSystemQuad*)createBloodParticleSystem:(BOOL)getFromUnusedSystems{
    
    if ([unusedBloodParticleSystems count] && getFromUnusedSystems == YES) {
        
        CCParticleSystemQuad *bloodParticleSystem = [unusedBloodParticleSystems lastObject];
        [unusedBloodParticleSystems removeLastObject];
        
        [bloodParticleSystem resetSystem];
        return bloodParticleSystem;
    }
    
    CCParticleSystemQuad *bloodParticleSystem = [[CCParticleSystemQuad alloc] initWithFile:@"BloodParticleSystem.plist"];
    
    return bloodParticleSystem;
}

- (void)createEnemyBodyExplosionAtPos:(CGPoint)pos enemyType:(EnemyType)enemyType {

    int numberOfBodyPars = rand() % 3 + 3;

    for (int i = 0; i < numberOfBodyPars; i++) {

        if ([enemyBodyDebrises count] >= MAX_BODY_DEBRIS_COUNT) {
            
            break;
        }
        
        // Debris
        float angle = M_PI * (rand() / (float)RAND_MAX) - M_PI_2;
        CGPoint randVelocity;
        randVelocity.x = sinf(angle) * 1500.0f;
        randVelocity.y = cosf(angle) * 1500.0f;
        EnemyBodyDebris *enemyBodyDebris = [[EnemyBodyDebris alloc] init:enemyType velocity:randVelocity spaceBounds:CGRectMake(0, GROUND_Y, [CCDirector sharedDirector].winSize.width, [CCDirector sharedDirector].winSize.height - GROUND_Y)];
        enemyBodyDebris.bloodParticleSystem = [self createBloodParticleSystem:YES];
        
        enemyBodyDebris.bloodParticleSystem.position = pos;
        [particleBatchNode addChild:enemyBodyDebris.bloodParticleSystem];
        
        enemyBodyDebris.position = pos;
        enemyBodyDebris.delegate = self;
        enemyBodyDebris.zOrder = GAME_OBJECTS_Z_ORDER - 1;
        [enemyBodyDebrises addObject:enemyBodyDebris];
        [mainSpriteBatch addChild:enemyBodyDebris];
    }
}

- (void)makeBombExplosionAtPos:(CGPoint)pos {
    
    NSInteger kills = 0;
    
    [[AudioManager sharedManager] explode];
    
    for (EnemySprite *enemy in tapEnemies) {
        if (ccpLengthSQ(ccpSub(enemy.position, pos)) < BOMB_KILL_PERIMETER * BOMB_KILL_PERIMETER) {

            [killedTapEnemies addObject:enemy];
            [enemy removeFromParentAndCleanup:YES];

            [self createEnemyBodyExplosionAtPos:enemy.position enemyType:enemy.type];
            [self enemyDidDie:enemy];

            kills++;
        }
    }

    if ([enemyBodyDebrises count] > BLOODY_MARY_BODY_DEBRIS_COUNT) {
        
        [[AppDelegate player] filledFloorWithBlood];
    }
    
    if (kills > 0) {
        [self addScoreAddLabelWithText:[NSString stringWithFormat:@"+%d", kills * kills] pos:ccpAdd(pos, ccp(0, 20)) type:ScoreAddLabelTypeRising addSkull:YES];
    }
    [AppDelegate player].points += kills * kills;

    numberOfKillsInLastFrame += kills;

    BombExplosion *newBombExplosion = [[BombExplosion alloc] init];
    newBombExplosion.zOrder = GAME_OBJECTS_Z_ORDER - 1;
    newBombExplosion.scale = [UIScreen mainScreen].scale * 2;
    newBombExplosion.anchorPoint = ccp(0.5, 0);
    newBombExplosion.position = pos;
    newBombExplosion.delegate = self;
    [mainSpriteBatch addChild:newBombExplosion];
    [bombExplosions addObject:newBombExplosion];
}

- (void)addScoreAddLabelWithText:(NSString*)text pos:(CGPoint)pos type:(ScoreAddLabelType)type addSkull:(BOOL)addSkull {

    ScoreAddLabel *scoreAddLabel = [[ScoreAddLabel alloc] initWithText:text pos:pos type:type];
    if (addSkull) {
        scoreAddLabel.anchorPoint = ccp(1, 0.5);
    }
    else {
        scoreAddLabel.anchorPoint = ccp(0.5, 0.5);
    }
    scoreAddLabel.scale = [UIScreen mainScreen].scale * 2;
    scoreAddLabel.delegate = self;
    scoreAddLabel.zOrder = 100;
    [self addChild:scoreAddLabel];
    [labels addObject:scoreAddLabel];

    if (addSkull) {

        FlyingSkullSprite *flyingSkull = [[FlyingSkullSprite alloc] initWithPos:ccpAdd(pos, ccp(4, -4))];
        flyingSkull.delegate = self;
        flyingSkull.scale = [UIScreen mainScreen].scale * 2;        
        flyingSkull.zOrder = 100;
        flyingSkull.anchorPoint = ccp(0, 0.5);
        [flyingSkulls addObject:flyingSkull];
        [mainSpriteBatch addChild:flyingSkull];
    }
}

#pragma mark - ScoreAddDelegate

- (void)scoreAddLabelDidFinish:(ScoreAddLabel *)label {

    [killedLabels addObject:label];
    [label removeFromParentAndCleanup:YES];
}

#pragma mark - CoinSpriteDelegate

- (void)coinDidDie:(CoinSprite *)coinSprite {

    [killedCoins addObject:coinSprite];
    [coinSprite removeFromParentAndCleanup:YES];
}

#pragma mark - FlyingSkullSpriteDelegate

- (void)flyingSkullSpriteDidFinish:(FlyingSkullSprite *)flyingSkull {

    [killedFlyingSkulls addObject:flyingSkull];
    [flyingSkull removeFromParentAndCleanup:YES];
    
}

#pragma mark - LightningDelegate

- (void)lightningDidFinish:(Lightning *)lightning {
    
    [killedLightnings addObject:lightning];
    [lightning removeFromParentAndCleanup:YES];
}

#pragma mark - WaterSplashDelegate

- (void)waterSplashDidFinish:(WaterSplash *)waterSplash {
    
    [killedWaterSplashes addObject:waterSplash];
    [waterSplash removeFromParentAndCleanup:YES];
}

#pragma mark - TrailDelegate

- (void)trailDidFinish:(Trail *)trail {
    
    if (trail == currentTrail) {
        
        currentTrail = nil;
    }
    
    [killedTrails addObject:trail];
    [trail removeFromParentAndCleanup:YES];
}


#pragma mark - BombSpriteDelegate

- (void)bombDidDie:(BombSprite *)bombSprite {

    [killedBombs addObject:bombSprite];
    [bombSprite removeFromParentAndCleanup:YES];
    
    [self makeBombExplosionAtPos:bombSprite.position];
    [screenShaker shake];
}

#pragma mark - EnemySpriteDelegate

- (void)enemyDidFallIntoSlime:(EnemySprite*)enemy {

    if (enemy.type == kEnemyTypeTap) {

        [killedTapEnemies addObject:enemy];
    }
    else {

        [killedSwipeEnemies addObject:enemy];
    }
    [enemy removeFromParentAndCleanup:YES];
    
    [AppDelegate player].health -= ENEMY_ATTACK_FORCE;
    int diff = (100 - [AppDelegate player].health);
    monsterHearth.infarkt = (float)diff / 100;
    
    WaterSplash *waterSplash = [[WaterSplash alloc] init];
    waterSplash.scale = [UIScreen mainScreen].scale * 2;
    waterSplash.anchorPoint = ccp(0.5, 0);
    CGPoint waterSplashPos = enemy.position;
    waterSplashPos.y = CGRectGetMaxY(slimeSprite.boundingBox);
    waterSplash.position = waterSplashPos;
    waterSplash.delegate = self;
    waterSplash.zOrder = 16;
    [mainSpriteBatch addChild:waterSplash];
    [waterSplashes addObject:waterSplash];
    
    if ([AppDelegate player].health <= 0) {
        [self showGameOver];
    }
    [self updateUI];
}

#pragma mark - BombExplosionDelegate

- (void)bombExplosionDidFinish:(BombExplosion *)bombExplosion {

    [killedBombExplosions addObject:bombExplosion];
    [bombExplosion removeFromParentAndCleanup:YES];
    
}

#pragma mark - BombSpawnerDelegate

- (void)bombSpawnerWantsBombToSpawn:(BombSpawner *)_bombSpawner {
    
    bombSpawning = NO;

    if ([AppDelegate player].coins < BOMB_COINS_COST) {

        [self addScoreAddLabelWithText:@"NOT ENOUGH COINS!" pos:ccp([CCDirector sharedDirector].winSize.width * 0.5f, [CCDirector sharedDirector].winSize.height * 0.5) type:ScoreAddLabelTypeBlinking addSkull:NO];

        [_bombSpawner cancelSpawning];
    }
    else {

        [[AudioManager sharedManager] bombReleased];
        [self addBombAtPosX:bombSpawner.pos.x];

        [[AppDelegate player] updateDropBombCount:1];

        [AppDelegate player].coins -= BOMB_COINS_COST;
        [self updateUI];

        [_bombSpawner startEndAnimation];
    }
}

#pragma mark - EnemyBodyDebrisDelegate

- (void)enemyBodyDebrisDidDie:(EnemyBodyDebris *)enemyBodyDebris {

    [unusedBloodParticleSystems addObject:enemyBodyDebris.bloodParticleSystem];
    [enemyBodyDebris.bloodParticleSystem removeFromParentAndCleanup:YES];

    [killedEnemyBodyDebrises addObject:enemyBodyDebris];
    [enemyBodyDebris removeFromParentAndCleanup:YES];
}

- (void)enemyBodyDebrisDidDieAndSpawnTapEnemy:(EnemyBodyDebris *)enemyBodyDebris {
    
    [self enemyBodyDebrisDidDie:enemyBodyDebris];
    
    EnemySprite *enemy = [[EnemySprite alloc] initWithWakingTapperWithPos:enemyBodyDebris.position];
    [tapEnemies addObject:enemy];
    enemy.zOrder = GAME_OBJECTS_Z_ORDER;
    [mainSpriteBatch addChild:enemy];
    enemy.delegate = self;
}


#pragma mark - MainframeDelegate

- (int)countTapEnemies {
    
    return [tapEnemies count];
}

- (int)countSwipeEnemies {
    
    return [swipeEnemies count];
}

- (int)getPlayerCoins {
    
    return [AppDelegate player].coins;
}

#pragma mark - Gestures

- (void)longPressStarted:(CGPoint)pos {

    [[AudioManager sharedManager] bombSpawningStarted];
    bombSpawning = YES;
    
    [bombSpawner startSpawningAtPos:pos];
}

- (void)longPressEnded {

    //NSLog(@"LongPress end");
    
    if (bombSpawning) {
        [[AudioManager sharedManager] bombSpawningCancelled];
    }
    
    bombSpawning = NO;
    [bombSpawner cancelSpawning];
}

- (void)swipeStarted:(CGPoint)pos {

    //NSLog(@"Swipe start");
}

- (void)swipeMoved:(CGPoint)pos {

    //NSLog(@"Swipe moved");
    
    for (EnemySprite *enemy in swipeEnemies) {
        
        if (lineSegmentPointDistance2(gestureRecognizer.lastPos, pos, enemy.position) < SWIPE_MIN_DISTANCE2) {
            
            [self sliceEnemyFromWall:enemy direction:ccpSub(pos, gestureRecognizer.lastPos)];
        }
    }
    
    if (currentTrail) {
        
        [currentTrail addPoint:pos];
    }
    else {
        
        [self createNewTrail:gestureRecognizer.startPos endPos:pos];
    }
}

- (void)swipeCancelled {

    currentTrail = nil;
    //NSLog(@"Swipe cancelled");
}

- (void)swipeEnded:(CGPoint)pos {

    currentTrail = nil;
    //NSLog(@"Swipe ended");
}

- (void)tapRecognized:(CGPoint)pos {

    CoinSprite *nearestCoin = nil;
    float nearestDistance = -1;
    
    NSMutableArray *pickedCoins = [[NSMutableArray alloc] initWithCapacity:10];
    
    for (CoinSprite *coin in coins) {
        
        float distance = ccpDistanceSQ(coin.position, pos);
        
        if (nearestDistance < 0) {
            
            nearestDistance = distance;
            nearestCoin = coin;
        }
        else {
            
            if (distance < nearestDistance) {
                
                nearestDistance = distance;
                nearestCoin = coin;
            }
        }
        
        if (distance < TAP_PICK_COIN_MIN_DISTANCE2) {
            
            [pickedCoins addObject:coin];
        }
    }
    
    // only the nearest coin will be picked
    
    if (nearestCoin && nearestDistance < TAP_MIN_DISTANCE2) {
        
        [coins removeObject:nearestCoin];

        CCAction *action = [CCEaseOut actionWithAction:[CCSequence actions:[CCMoveTo actionWithDuration:1.0f position:coinsSprite.position],
                                                        [CCCallFuncN actionWithTarget:self selector:@selector(coinEndedCashingAnimation:)], nil] rate:2.0f];
        
        [nearestCoin runAction:action];
        [self coinWasAdded];
        return;
    }
    
    
    // multiple coins can be picked
    /*
    if ([pickedCoins count]) {
        
        for (CoinSprite * coin in pickedCoins) {
            
            [coins removeObject:coin];
            
            CCAction *action = [CCEaseOut actionWithAction:[CCSequence actions:[CCMoveTo actionWithDuration:1.0f position:coinsSprite.position],
                                                            [CCCallFuncN actionWithTarget:self selector:@selector(coinEndedCashingAnimation:)], nil] rate:2.0f];
            
            [coin runAction:action];
            [self coinWasAdded];
        }
        
        return;
    }
    */
    
    EnemySprite *nearestEnemy = nil;
    
    nearestDistance = -1;
    for (EnemySprite *enemy in tapEnemies) {
        
        float distance = ccpDistanceSQ(enemy.position, pos);
        if (nearestDistance < 0) {
            
            nearestDistance = distance;
            nearestEnemy = enemy;
        }
        else {
            
            if (distance < nearestDistance) {
                
                nearestDistance = distance;
                nearestEnemy = enemy;
            }
        }
    }

    if (nearestEnemy && nearestDistance < TAP_MIN_DISTANCE2) {
        

        [self throwEnemyFromWall:nearestEnemy];
        return;
    }

    nearestDistance = - 1;
    for (EnemySprite *enemy in swipeEnemies) {
        
        float distance = ccpDistanceSQ(enemy.position, pos);
        if (nearestDistance < 0) {
            
            nearestDistance = distance;
            nearestEnemy = enemy;
        }
        else {
            
            if (distance < nearestDistance) {
                
                nearestDistance = distance;
                nearestEnemy = enemy;
            }
        }
    }
    
    if (nearestEnemy && nearestDistance < TAP_MIN_DISTANCE2) {
        
        
        [self throwEnemyFromWall:nearestEnemy];
        return;
    }
}

- (void) sliceEnemyFromWall:(EnemySprite*)enemy direction:(CGPoint)direction {
    
    if (enemy.state != kEnemyStateClimbing && enemy.state != kEnemyStateCrossing) {
        
        return;
    }
    
    if (enemy.state == kEnemyStateCrossing && [AppDelegate player].health <= ENEMY_ATTACK_FORCE) {
        
        [[AppDelegate player] closeCall];
    }

     
    // Debris
    CGPoint pos;
    pos = ccpAdd(enemy.position, ccpMult(ccpNormalize(CGPointMake(direction.y, -direction.x)), 20));
    
    float directionAngle = atan2f(direction.y, direction.x);
    float angle = -M_PI * (rand() / (float)RAND_MAX) / 4 - M_PI / 8 + directionAngle;
    CGPoint randVelocity;
    randVelocity.x = cosf(angle);
    randVelocity.y = sinf(angle);
    randVelocity = ccpMult(randVelocity, 30.0f * ccpLength(direction));
    EnemyBodyDebris *enemyBodyDebris = [[EnemyBodyDebris alloc] init:kEnemyTypeSwipe velocity:randVelocity spaceBounds:CGRectMake(0, GROUND_Y, [CCDirector sharedDirector].winSize.width, [CCDirector sharedDirector].winSize.height - GROUND_Y)];
    enemyBodyDebris.bloodParticleSystem = [self createBloodParticleSystem:YES];
    enemyBodyDebris.bloodParticleSystem.position = pos;
    [particleBatchNode addChild:enemyBodyDebris.bloodParticleSystem];
    
    enemyBodyDebris.swipeEnemyPart = YES;
    enemyBodyDebris.position = pos;
    enemyBodyDebris.delegate = self;
    enemyBodyDebris.zOrder = GAME_OBJECTS_Z_ORDER - 1;
    [enemyBodyDebrises addObject:enemyBodyDebris];
    [mainSpriteBatch addChild:enemyBodyDebris];
    
    pos = ccpSub(enemy.position, ccpMult(ccpNormalize(CGPointMake(direction.y, -direction.x)), 20));
    
    directionAngle = atan2f(direction.y, direction.x);
    angle = -M_PI * (rand() / (float)RAND_MAX) / 4 - M_PI / 8 + directionAngle;
    randVelocity.x = cosf(angle);
    randVelocity.y = sinf(angle);
    randVelocity = ccpMult(randVelocity, 30.0f * ccpLength(direction));
    enemyBodyDebris = [[EnemyBodyDebris alloc] init:kEnemyTypeSwipe velocity:randVelocity spaceBounds:CGRectMake(0, GROUND_Y, [CCDirector sharedDirector].winSize.width, [CCDirector sharedDirector].winSize.height - GROUND_Y)];
    enemyBodyDebris.bloodParticleSystem = [self createBloodParticleSystem:YES];
    enemyBodyDebris.bloodParticleSystem.position = pos;
    [particleBatchNode addChild:enemyBodyDebris.bloodParticleSystem];
    
    enemyBodyDebris.swipeEnemyPart = YES;
    enemyBodyDebris.position = pos;
    enemyBodyDebris.delegate = self;
    enemyBodyDebris.zOrder = GAME_OBJECTS_Z_ORDER - 1;
    [enemyBodyDebrises addObject:enemyBodyDebris];
    [mainSpriteBatch addChild:enemyBodyDebris];
    
    [killedSwipeEnemies addObject:enemy];
    [enemy removeFromParentAndCleanup:YES];
}


- (void) throwEnemyFromWall:(EnemySprite*)enemy {
    
    if (enemy.state != kEnemyStateClimbing && enemy.state != kEnemyStateCrossing) {
        
        return;
    }
    
    
    if (enemy.type == kEnemyTypeSwipe) {
     
        [self createLightningToEnemy:enemy];
        [enemy elecrify];
    }
    else {
        
        if (enemy.state == kEnemyStateCrossing && [AppDelegate player].health <= ENEMY_ATTACK_FORCE) {
            
            [[AppDelegate player] closeCall];
        }
        
        [enemy throwFromWall];
        [self createLightningToEnemy:enemy];
    }
}

- (void) setPause:(BOOL)pause
{
    _pause = pause;
    if (_pause == NO) {
        for (MenuCoinSprite *coin in menuCoins) {
            [coin removeFromParentAndCleanup:YES];
        }
        [menuCoins removeAllObjects];
        [menuHeart removeFromParentAndCleanup:YES];
        menuHeart = nil;
        
        gestureRecognizer.delegate = self;
    }
}

- (void) pauseGame {
    [self setPause:YES];
    
    gestureRecognizer.delegate = nil;
    
    menuBackground = [[CCLayerColor alloc] initWithColor:ccc4(0, 0, 0, 0.6 * 255)];
    menuBackground.contentSize = [[CCDirector sharedDirector] winSize];
    menuBackground.zOrder = 2000;
    [self addChild:menuBackground];
    
    CGFloat offset = 0.0;
    if (!IS_WIDESCREEN) {
        offset = 44.0;
    }
    [[AppDelegate mainMenuScene] setGame:YES];
    [[CCDirector sharedDirector].view addSubview:[[AppDelegate mainMenuScene] mainView]];
    
    [UIView animateWithDuration:0.25 animations:^{
        [mainView setAlpha:0];
    } completion:^(BOOL finished) {
        [mainView removeFromSuperview];
    }];
    menuHeart = [[MonsterHearth alloc] init];
    menuHeart.anchorPoint = ccp(0.5, 0);
    menuHeart.position = ccp([CCDirector sharedDirector].winSize.width * 0.5, CGRectGetMaxY(monsterSprite.boundingBox) + 120.0);
    menuHeart.zOrder = 5000;
    [self addChild:menuHeart];
    
    [self addMenuCoinAtPos:CGPointMake(60.0, 410.0 - offset)];
    [self addMenuCoinAtPos:CGPointMake(260.0, 410.0 - offset)];
}

#pragma mark -

- (void) createNewTrail:(CGPoint)startPos endPos:(CGPoint)endPos {
    
    currentTrail = [[Trail alloc] initWithStartPos:startPos endPos:endPos];
    currentTrail.delegate = self;
    currentTrail.zOrder = 999;
    [self addChild:currentTrail];
    
    [trails addObject:currentTrail];
}

- (void) createLightningToEnemy:(EnemySprite*)enemy {
    [[AudioManager sharedManager] enemyHit];    
    
    CGPoint startPos = CGPointMake([CCDirector sharedDirector].winSize.width / 2, [CCDirector sharedDirector].winSize.height / 2 + 220);
    Lightning *lightning = [[Lightning alloc] initWithStartPos:startPos endPos:enemy.position];
    lightning.zOrder = 30;
    [self addChild:lightning];
    [lightnings addObject:lightning];
    
    lightning.lightningTarget = enemy;
}

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
    /*
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    
    UIImage *image = [UIImage imageNamed:name];
    CGSize size = [image size];
    CGFloat scale = [[UIScreen mainScreen] scale];
    image = [UIImage imageWithCGImage:[image CGImage] scale:scale * 2 orientation:image.imageOrientation];
    UIImageView *attachmentView = [[UIImageView alloc] initWithFrame:CGRectMake((winSize.width - (size.width * scale)) / 2, (winSize.height - (size.height * scale)) / 2,
                                                                                size.width * scale, size.height * scale)];
    [attachmentView setImage:image];
    [attachmentView setAlpha:0];
    [mainView  addSubview:attachmentView];
    
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
    */
}

- (void) showGameOver
{
    if (gameOver) {
        return;
    }
    [monsterHearth setInfarkt:0];
    gestureRecognizer.delegate = nil;
    masterControlProgram = nil;
    
    [killsLabel removeFromParentAndCleanup:YES];
    [killSprite setZOrder:0];
    
    [coinsLabel removeFromParentAndCleanup:YES];
    [coinsSprite setZOrder:0];

    [bombSpawner cancelSpawning];
    
    menuBackground = [[CCLayerColor alloc] initWithColor:ccc4(0, 0, 0, 0.6 * 255)];
    menuBackground.contentSize = [[CCDirector sharedDirector] winSize];
    menuBackground.zOrder = 2000;
    [self addChild:menuBackground];
    
    CGSize contentSize = [[CCDirector sharedDirector] winSize];
    CGFloat offset = 0.0;
    if (contentSize.height == 480.0)
        offset = 34.0;
    
    restartButton = [[MenuButton alloc] initWithFrame:CGRectMake((contentSize.width - 114.0 * 2) / 2, 490.0 - offset * 2 - 10.0, 114.0 * 2, 16.0 * 2 + 20.0)];
    [restartButton setImage:[UIImage imageNamed:@"go-play"]];
    [restartButton addTarget:self action:@selector(restartGame) forControlEvents:UIControlEventTouchUpInside];
    [mainView addSubview:restartButton];
    
    gameOver = YES;

    [rageProgressView setAlpha:0];
    [rageBackgroundView setAlpha:0];
    [pauseButton setAlpha:0];
    
    [[AppDelegate player] storeScore:[AppDelegate player].points];
    
    gameOverLayer = [[CCLayer alloc] init];
    gameOverLayer.zOrder = 5000;
    
    CCSprite *sprite;
    sprite = [[CCSprite alloc] initWithSpriteFrameName:@"go-bones.png"];
    sprite.anchorPoint = ccp(0.5, 0.5);
    sprite.position = ccp([CCDirector sharedDirector].winSize.width / 2, 120 - offset);
    sprite.scale = [UIScreen mainScreen].scale * 2;
    [gameOverLayer addChild:sprite];
    
    sprite = [[CCSprite alloc] initWithSpriteFrameName:@"go-bones2.png"];
    sprite.anchorPoint = ccp(0.5, 0.5);
    sprite.position = ccp([CCDirector sharedDirector].winSize.width / 2, 400 - offset);
    sprite.scale = [UIScreen mainScreen].scale * 2;
    [gameOverLayer addChild:sprite];

    CCLabelBMFont *label;
    label = [[CCLabelBMFont alloc] initWithString:[NSString stringWithFormat:@"%i", [AppDelegate player].points] fntFile:@"PixelFont.fnt"];
    label.anchorPoint = ccp(0.5, 0.5);
    label.scale = [UIScreen mainScreen].scale * 4;
    label.position = ccp([CCDirector sharedDirector].winSize.width / 2 + 5, 350.0 - offset);
    [label setColor:ccc3(255, 211, 14)];
    [gameOverLayer addChild:label];
    
    if ([[AppDelegate player] topScore] < [AppDelegate player].points || [AppDelegate player].points == 0) {
        label = [[CCLabelBMFont alloc] initWithString:[AppDelegate player].points == 0 ? @"Loser!" : @"New Record" fntFile:@"PixelFont.fnt"];
        label.anchorPoint = ccp(0.5, 0.5);
        label.scale = [UIScreen mainScreen].scale * 2;
        label.position = ccp([CCDirector sharedDirector].winSize.width / 2 + 3, 315.0 - offset);
        [label setColor:ccc3(255, 211, 14)];
        [gameOverLayer addChild:label];
    }    
    sprite = [[CCSprite alloc] initWithSpriteFrameName:@"go-gameover.png"];
    sprite.anchorPoint = ccp(0.5, 0.5);
    sprite.position = ccp([CCDirector sharedDirector].winSize.width / 2, 458.0 - offset);
    sprite.scale = [UIScreen mainScreen].scale * 2;
    [gameOverLayer addChild:sprite];
    
    [leaderboard loadScoresWithCompletionHandler:^(NSArray *scores, NSError *error) {
        if (!gameOver)
            return;
        NSMutableArray *array = [NSMutableArray array];
        for (GKScore *score in scores)
            [array addObject:score.playerID];
        
        [GKPlayer loadPlayersForIdentifiers:array withCompletionHandler:^(NSArray *players, NSError *error) {
            CCLabelBMFont *label;
            int i, lines = [scores count];
            if (lines > 3) lines = 3;
            
            for (i = 0; i < lines; i++) {
                GKScore *score = scores[i];
                GKPlayer *player = players[i];
                CGFloat offsetY = 265.0;
                
                label = [[CCLabelBMFont alloc] initWithString:[NSString stringWithFormat:@"%i", score.rank] fntFile:@"PixelFont.fnt"];
                label.anchorPoint = ccp(0.5, 0.5);
                label.scale = [UIScreen mainScreen].scale * 2;
                label.position = ccp(40.0, offsetY - i * 44.0 - offset);
                [label setColor:ccc3(145, 145, 153)];
                [gameOverLayer addChild:label];
                
                NSString *string = [player.alias uppercaseString];
                NSData *data = [string dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
                label = [[CCLabelBMFont alloc] initWithString:[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] fntFile:@"PixelFont.fnt"];
                label.anchorPoint = ccp(0, 0.5);
                label.scale = [UIScreen mainScreen].scale * 2;
                label.position = ccp(70.0, offsetY - i * 44.0 - offset);
                [label setColor:ccc3(145, 145, 153)];
                [gameOverLayer addChild:label];
                
                label = [[CCLabelBMFont alloc] initWithString:[NSString stringWithFormat:@"%lld", score.value] fntFile:@"PixelFont.fnt"];
                label.anchorPoint = ccp(1, 0.5);
                label.scale = [UIScreen mainScreen].scale * 2;
                label.position = ccp(290.0, offsetY - i * 44.0 - offset);
                [label setColor:ccc3(145, 145, 153)];
                [gameOverLayer addChild:label];
            }
        }];
    }];
    if (contentSize.height > 480.0) {
        menuHeart = [[MonsterHearth alloc] init];
        menuHeart.anchorPoint = ccp(0.5, 0);
        menuHeart.position = ccp([CCDirector sharedDirector].winSize.width * 0.5, 472.0 - offset);
        [gameOverLayer addChild:menuHeart];
    }    
    [self addChild:gameOverLayer];
    [[AppDelegate player] newGame];
}

- (void) restartGame
{
    masterControlProgram = [[MasterControlProgram alloc] init];
    masterControlProgram.mainframe = self;
    
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

    [rageProgressView setAlpha:1];
    [rageBackgroundView setAlpha:1];
    [pauseButton setAlpha:1];
    
    [gameOverLayer removeFromParentAndCleanup:YES];
    gameOverLayer = nil;
    menuHeart = nil;
    
    [menuBackground removeFromParentAndCleanup:YES];
    
    coinsSprite.zOrder = 5000;
    killSprite.zOrder = 5000;
    
    lastCoin = nil;
    lastKill = nil;
}


#pragma mark - Update

- (void)calc:(ccTime)deltaTime {
    
    if (_pause) {
        for (MenuCoinSprite *coin in menuCoins) {
            [coin calc:deltaTime];
        }
        [menuHeart calc:deltaTime];
        return;
    }

    numberOfKillsInLastFrame = 0;

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
            [bubble removeFromParentAndCleanup:YES];
        }
    }

    for (ScoreAddLabel *label in labels) {
        [label calc:deltaTime];
    }

    for (FlyingSkullSprite *skull in flyingSkulls) {
        [skull calc:deltaTime];
    }
    
    for (Lightning *lightning in lightnings) {
        [lightning calc:deltaTime];
    }

    for (WaterSplash *waterSplash in waterSplashes) {
        [waterSplash calc:deltaTime];
    }

    for (Trail *trail in trails) {
        [trail calc:deltaTime];
    }
    
    for (BombExplosion *bombExplosion in bombExplosions) {
        [bombExplosion calc:deltaTime];
    }

    // Killed
    for (CoinSprite *coin in killedCoins) {
        [coins removeObject:coin];
    }
    [killedCoins removeAllObjects];


    for (BombSprite *bomb in killedBombs) {
        [bombs removeObject:bomb];
    }
    [killedBombs removeAllObjects];

    for (EnemySprite *killedEnemy in killedTapEnemies) {
        [tapEnemies removeObject:killedEnemy];
    }
    [killedTapEnemies removeAllObjects];

    for (EnemySprite *killedEnemy in killedSwipeEnemies) {
        [swipeEnemies removeObject:killedEnemy];
    }
    [killedSwipeEnemies removeAllObjects];

    for (EnemyBodyDebris *enemyBodyDebris in killedEnemyBodyDebrises) {
        [enemyBodyDebrises removeObject:enemyBodyDebris];
    }
    [killedEnemyBodyDebrises removeAllObjects];

    for (SlimeBubbleSprite *bubble in killedBubbles) {
        [bubbles removeObject:bubble];
    }
    [killedBubbles removeAllObjects];

    for (ScoreAddLabel *label in killedLabels) {
        [labels removeObject:label];
    }
    [killedLabels removeAllObjects];

    for (FlyingSkullSprite *skull in killedFlyingSkulls) {
        [flyingSkulls removeObject:skull];
    }
    [killedFlyingSkulls removeAllObjects];
    
    for (Lightning *lightning in killedLightnings) {
        [lightnings removeObject:lightning];
    }
    [killedLightnings removeAllObjects];

    for (WaterSplash *waterSplash in killedWaterSplashes) {
        [waterSplashes removeObject:waterSplash];
    }
    [killedWaterSplashes removeAllObjects];
    
    for (Trail *trail in killedTrails) {
        [trails removeObject:trail];
    }
    [killedTrails removeAllObjects];
    
    for (BombExplosion *bombExplosion in killedBombExplosions) {
        [bombExplosions removeObject:bombExplosion];
    }
    [killedBombExplosions removeAllObjects];

    [masterControlProgram calc:deltaTime];
    
    if ([AppDelegate player].rage >= 1.0) {
        [self addBombAtPosX:80.0];
        [self addBombAtPosX:160.0];
        [self addBombAtPosX:240.0];
        [[AppDelegate player] updateDropBombCount:3];
        [self updateUI];
        [AppDelegate player].rage = 0;
    }
    [[AppDelegate player] calc:deltaTime];

    // Slime
    [slimeSprite setEnergy:[AppDelegate player].health * 0.01];
    [slimeSprite calc:deltaTime];

    slimeTop.position = ccp([CCDirector sharedDirector].winSize.width * 0.5, CGRectGetMaxY(slimeSprite.boundingBox));    

    // Monster
    [monsterSprite calc:deltaTime];
    [monsterHearth calc:deltaTime];
    
    [menuHeart calc:deltaTime];

    // Shake
    [screenShaker calc:deltaTime];
    self.position = screenShaker.offset;

    // Add bubbles
    if (slimeSprite.boundingBox.size.height > 10 && rand() % 100 == 0) {
        [self addBubble:ccp(slimeSprite.boundingBox.origin.x + (slimeSprite.boundingBox.size.width - 40) * rand() / RAND_MAX + 20, GROUND_Y + 5 + rand() % 7)];
    }

    // Killing
    if (numberOfKillsInLastFrame == 2) {
        [self addScoreAddLabelWithText:@"DOUBLE KILL!" pos:ccp([CCDirector sharedDirector].winSize.width * 0.5f, [CCDirector sharedDirector].winSize.height * 0.5) type:ScoreAddLabelTypeBlinking addSkull:NO];
    }
    else if (numberOfKillsInLastFrame == 3) {
        [self addScoreAddLabelWithText:@"TRIPLE KILL!" pos:ccp([CCDirector sharedDirector].winSize.width * 0.5f, [CCDirector sharedDirector].winSize.height * 0.5) type:ScoreAddLabelTypeBlinking addSkull:NO];
    }
    else if (numberOfKillsInLastFrame == 4) {
        [self addScoreAddLabelWithText:@"MEGA KILL!" pos:ccp([CCDirector sharedDirector].winSize.width * 0.5f, [CCDirector sharedDirector].winSize.height * 0.5) type:ScoreAddLabelTypeBlinking addSkull:NO];
    }
    else if (numberOfKillsInLastFrame > 5) {
        [self addScoreAddLabelWithText:@"GODLIKE!" pos:ccp([CCDirector sharedDirector].winSize.width * 0.5f, [CCDirector sharedDirector].winSize.height * 0.5) type:ScoreAddLabelTypeBlinking addSkull:NO];
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

    // video hack
    //deltaTime = FRAME_TIME_INTERVAL * 2;

    while (calcTime >= FRAME_TIME_INTERVAL) {

        [self calc:FRAME_TIME_INTERVAL];
        calcTime -= FRAME_TIME_INTERVAL;
    }

    /*
    UIImage *image = [self captureScreen];
    static int frameNum = 0;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT , 0), ^{
        NSString *fileName = [basePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.jpg", frameNum]];
        [UIImageJPEGRepresentation(image, 0.8) writeToFile:fileName atomically:YES];
    });

    frameNum++;
     */
}

- (float)slimeSurfacePosY {
    
    return CGRectGetMaxY(slimeSprite.boundingBox);
}


#pragma mark - Screen capture

static void releaseScreenshotData(void *info, const void *data, size_t size) {
	free((void *)data);
};

- (UIImage*)captureScreen {

    int framebufferWidth = 320;
    int framebufferHeight = 480;

	NSInteger dataLength = framebufferWidth * framebufferHeight * 4;

	// Allocate array.
	GLuint *buffer = (GLuint *) malloc(dataLength);
	GLuint *resultsBuffer = (GLuint *)malloc(dataLength);
    // Read data
	glReadPixels(0, 0, framebufferWidth, framebufferHeight, GL_RGBA, GL_UNSIGNED_BYTE, buffer);

    // Flip vertical
	for(int y = 0; y < framebufferHeight; y++) {
		for(int x = 0; x < framebufferWidth; x++) {
			resultsBuffer[x + y * framebufferWidth] = buffer[x + (framebufferHeight - 1 - y) * framebufferWidth];
		}
	}

	free(buffer);

	// make data provider with data.
	CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, resultsBuffer, dataLength, releaseScreenshotData);

	// prep the ingredients
	const int bitsPerComponent = 8;
	const int bitsPerPixel = 4 * bitsPerComponent;
	const int bytesPerRow = 4 * framebufferWidth;
	CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
	CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
	CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;

	// make the cgimage
	CGImageRef imageRef = CGImageCreate(framebufferWidth, framebufferHeight, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
	CGColorSpaceRelease(colorSpaceRef);
	CGDataProviderRelease(provider);

	// then make the UIImage from that
	UIImage *image = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);

	return image;
}

@end