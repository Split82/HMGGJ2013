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
    BOOL gameOver;
    
    // UI vars
    UIView *mainView;
    
    NSString *lastKill;
    CCSprite *killSprite;
    CCLabelBMFont *killsLabel;
    
    NSString *lastCoin;
    CCSprite *coinsSprite;
    CCLabelBMFont *coinsLabel;
    
    UIImageView *pauseButton;
    UIImageView *restartButton;
    
    UIView *rageView;
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
    
    //[[AudioManager sharedManager] startBackgroundTrack];
    bombSpawning = NO;

    [self initUI];
}

- (void) initUI {
    UIView *view = [[UIView alloc] initWithFrame:[CCDirector sharedDirector].view.bounds];
    [view setBackgroundColor:[UIColor clearColor]];
    [[CCDirector sharedDirector].view addSubview:view];
    mainView = view;

    CGSize contentSize = [CCDirector sharedDirector].winSize;
    UIImage *image;
    CGFloat offset = 0.0;
    if (contentSize.height > 480.0)
        offset = 18.0;

    killSprite = [[CCSprite alloc] initWithSpriteFrameName:@"skull.png"];
    killSprite.anchorPoint = ccp(0, 0);
    killSprite.scale = [UIScreen mainScreen].scale * 2;
    killSprite.position = ccp(5.0, contentSize.height - killSprite.contentSize.height * killSprite.scale - 13.0 - offset);
    killSprite.zOrder = 5000;
    [self addChild:killSprite];
    
    coinsSprite = [[CCSprite alloc] initWithSpriteFrameName:@"coin1.png"];
    coinsSprite.anchorPoint = ccp(0.5, 0.5);
    coinsSprite.zOrder = 5000;
    coinsSprite.scale = [UIScreen mainScreen].scale * 2;
    coinsSprite.position = ccp(contentSize.width - 20.0, contentSize.height - 26 - offset);
    [self addChild:coinsSprite];
    
    if (contentSize.height == 480.0)
        offset = 2.0;
    else
        offset = 22.0;
    image = [UIImage imageNamed:@"progressBarBack"];
    image = [UIImage imageWithCGImage:[image CGImage] scale:[[UIScreen mainScreen] scale] * 2 orientation:image.imageOrientation];
    rageBackgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(16.0, contentSize.height - 24.0 - 8.0 - offset, 288.0, 24.0)];
    [rageBackgroundView setImage:image];
    [rageBackgroundView.layer setMagnificationFilter:kCAFilterNearest];
    [mainView addSubview:rageBackgroundView];
    
    image = [UIImage imageNamed:@"progressBar"];
    image = [UIImage imageWithCGImage:[image CGImage] scale:[[UIScreen mainScreen] scale] * 2 orientation:image.imageOrientation];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 272.0, 8.0)];
    [imageView setImage:image];
    [imageView.layer setMagnificationFilter:kCAFilterNearest];
    rageView = [[UIView alloc] initWithFrame:CGRectMake(24.0, contentSize.height - 24.0 - offset, 0.0, 8.0)];
    [rageView setClipsToBounds:YES];
    [rageView addSubview:imageView];
    [mainView addSubview:rageView];
    
    if (contentSize.height > 480.0)
        offset = 16.0;
    
    image = [UIImage imageNamed:@"pause"];
    image = [UIImage imageWithCGImage:[image CGImage] scale:[[UIScreen mainScreen] scale] * 2 orientation:image.imageOrientation];
    pauseButton = [[UIImageView alloc] initWithFrame:CGRectMake((contentSize.width - 24.0) / 2, 13.0 + offset, 24.0, 28.0)];
    [pauseButton.layer setMagnificationFilter:kCAFilterNearest];
    [pauseButton setImage:image];
    [pauseButton setUserInteractionEnabled:YES];
    [pauseButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pauseGame)]];
    [mainView addSubview:pauseButton];
    [self updateUI];
}

- (void) updateUI {
    
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
    [rageView setFrame:CGRectMake(24.0, contentSize.height - 24.0 - offset, 272.0 * [AppDelegate player].rage, 8.0)];
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
    
    [[AudioManager sharedManager] explode];
    
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

    if (kills > 0) {
        [self addScoreAddLabelWithText:[NSString stringWithFormat:@"+%d", kills * kills] pos:ccpAdd(pos, ccp(0, 20)) type:ScoreAddLabelTypeRising addSkull:YES];
    }
    [AppDelegate player].points += kills * kills;

    numberOfKillsInLastFrame += kills;

    /*CCParticleSystemQuad *explosionParticleSystem = [[CCParticleSystemQuad alloc] initWithFile:kExplosionParticleSystemFileName];
    explosionParticleSystem.autoRemoveOnFinish = YES;
    explosionParticleSystem.position = pos;
    [particleBatchNode addChild:explosionParticleSystem];*/

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
}

#pragma mark - CoinSpriteDelegate

- (void)coinDidDie:(CoinSprite *)coinSprite {

    [killedCoins addObject:coinSprite];
}

#pragma mark - FlyingSkullSpriteDelegate

- (void)flyingSkullSpriteDidFinish:(FlyingSkullSprite *)flyingSkull {

    [killedFlyingSkulls addObject:flyingSkull];
}


#pragma mark - LightningDelegate

- (void)lightningDidFinish:(Lightning *)lightning {
    
    [killedLightnings addObject:lightning];
}

#pragma mark - WaterSplashDelegate

- (void)waterSplashDidFinish:(WaterSplash *)waterSplash {
    
    [killedWaterSplashes addObject:waterSplash];
}

#pragma mark - TrailDelegate

- (void)trailDidFinish:(Trail *)trail {
    
    if (trail == currentTrail) {
        
        currentTrail = nil;
    }
    
    [killedTrails addObject:trail];
}


#pragma mark - BombSpriteDelegate

- (void)bombDidDie:(BombSprite *)bombSprite {

    [killedBombs addObject:bombSprite];
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
    [AppDelegate player].health -= ENEMY_ATTACK_FORCE;
    
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
    
    if ([AppDelegate player].health == 0) {
        [self showGameOver];
    }
    [self updateUI];
}

#pragma mark - BombExplosionDelegate

- (void)bombExplosionDidFinish:(BombExplosion *)bombExplosion {

    [killedBombExplosions addObject:bombExplosion];
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
            
            if ([enemy throwFromWall]) {
                
                [self createLightningToEnemy:enemy];
            }
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

    EnemySprite *nearestEnemy = nil;
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
    /*
    if (nearestCoin && nearestDistance < TAP_MIN_DISTANCE2) {
        
        [coins removeObject:nearestCoin];

        CCAction *action = [CCEaseOut actionWithAction:[CCSequence actions:[CCMoveTo actionWithDuration:1.0f position:coinsSprite.position],
                                                        [CCCallFuncN actionWithTarget:self selector:@selector(coinEndedCashingAnimation:)], nil] rate:2.0f];
        
        [nearestCoin runAction:action];
        [self coinWasAdded];
        return;
    }
    */
    
    // multiple coins can be picked
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
        // multiple enemies will be thrown
        /*
        if (distance < TAP_THROW_MIN_DISTANCE2) {
        
             if ([enemy throwFromWall]) {
             
             [self createLightningToEnemy:enemy];
             }

        }
        */
    }

    if (nearestEnemy && nearestDistance < TAP_MIN_DISTANCE2) {
        
        if ([nearestEnemy throwFromWall]) {
            
            [self createLightningToEnemy:nearestEnemy];
        }

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
    gestureRecognizer.delegate = nil;
    masterControlProgram = nil;
    
    [killsLabel removeFromParentAndCleanup:YES];
    [killSprite setZOrder:0];
    
    [coinsLabel removeFromParentAndCleanup:YES];
    [coinsSprite setZOrder:0];
    
    menuBackground = [[CCLayerColor alloc] initWithColor:ccc4(0, 0, 0, 0.6 * 255)];
    menuBackground.contentSize = [[CCDirector sharedDirector] winSize];
    menuBackground.zOrder = 2000;
    [self addChild:menuBackground];
    
    CGSize contentSize = [[CCDirector sharedDirector] winSize];
    CGFloat offset = 0.0;
    if (contentSize.height == 480.0)
        offset = 34.0;
    
    UIImage *image = [UIImage imageNamed:@"go-play"];
    image = [UIImage imageWithCGImage:[image CGImage] scale:[[UIScreen mainScreen] scale] * 2 orientation:image.imageOrientation];
    restartButton = [[UIImageView alloc] initWithFrame:CGRectMake((contentSize.width - 114.0 * 2) / 2, 490.0 - offset * 2, 114.0 * 2, 16.0 * 2)];
    [restartButton.layer setMagnificationFilter:kCAFilterNearest];
    [restartButton setImage:image];
    [restartButton setUserInteractionEnabled:YES];
    [restartButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(restartGame)]];
    [mainView addSubview:restartButton];
    
    gameOver = YES;

    [rageView setAlpha:0];
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

    [rageView setAlpha:1];
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
        [coin removeFromParentAndCleanup:YES];
    }
    [killedCoins removeAllObjects];

    for (BombSprite *bomb in killedBombs) {
        [bombs removeObject:bomb];
        [bomb removeFromParentAndCleanup:YES];
    }
    [killedBombs removeAllObjects];

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

    for (ScoreAddLabel *label in killedLabels) {
        [labels removeObject:label];
        [label removeFromParentAndCleanup:YES];
    }
    [killedLabels removeAllObjects];

    for (FlyingSkullSprite *skull in killedFlyingSkulls) {
        [flyingSkulls removeObject:skull];
        [skull removeFromParentAndCleanup:YES];
    }
    [killedFlyingSkulls removeAllObjects];
    
    for (Lightning *lightning in killedLightnings) {
        [lightnings removeObject:lightning];
        [lightning removeFromParentAndCleanup:YES];
    }
    [killedLightnings removeAllObjects];

    for (WaterSplash *waterSplash in killedWaterSplashes) {
        [waterSplashes removeObject:waterSplash];
        [waterSplash removeFromParentAndCleanup:YES];
    }
    [killedWaterSplashes removeAllObjects];
    
    for (Trail *trail in killedTrails) {
        [trails removeObject:trail];
        [trail removeFromParentAndCleanup:YES];
    }
    [killedTrails removeAllObjects];
    
    for (BombExplosion *bombExplosion in killedBombExplosions) {
        [bombExplosions removeObject:bombExplosion];
        [bombExplosion removeFromParentAndCleanup:YES];
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

    while (calcTime >= FRAME_TIME_INTERVAL) {

        [self calc:FRAME_TIME_INTERVAL];
        calcTime -= FRAME_TIME_INTERVAL;
    }
}

-(float) slimeSurfacePosY {
    
    return CGRectGetMaxY(slimeSprite.boundingBox);
}


@end