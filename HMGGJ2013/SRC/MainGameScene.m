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

    NSMutableArray *killedCoins;
    NSMutableArray *killedTapEnemies;
    NSMutableArray *killedSwipeEnemies;
    NSMutableArray *killedBombs;
    NSMutableArray *killedEnemyBodyDebrises;
    NSMutableArray *killedBubbles;
    NSMutableArray *killedLabels;
    NSMutableArray *killedFlyingSkulls;

    BombSpawner *bombSpawner;
    SlimeSprite *slimeSprite;
    CCSprite *slimeTop;
    MonsterSprite *monsterSprite;
    MonsterHearth *monsterHearth;
    
    NSMutableArray *menuCoins;
    MonsterHearth *menuHeart;
    
    MasterControlProgram *masterControlProgram;
    
    CCParticleBatchNode *particleBatchNode;

    // State vars
    BOOL sceneInitWasPerformed;
    BOOL gameOver;
    
    // UI vars
    UIView *mainView;
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
    CCLayer *menuBackground;
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

    killedCoins = [[NSMutableArray alloc] initWithCapacity:10];
    killedTapEnemies = [[NSMutableArray alloc] initWithCapacity:100];
    killedSwipeEnemies = [[NSMutableArray alloc] initWithCapacity:100];
    killedBombs = [[NSMutableArray alloc] initWithCapacity:10];
    killedEnemyBodyDebrises = [[NSMutableArray alloc] initWithCapacity:50];
    killedBubbles = [[NSMutableArray alloc] initWithCapacity:2];
    killedLabels = [[NSMutableArray alloc] initWithCapacity:4];
    killedFlyingSkulls = [[NSMutableArray alloc] initWithCapacity:4];
    
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
    
    [self initUI];
}

- (void) initUI {
    fontName = @"Visitor TT1 BRK";
    UIFont *font = [UIFont fontWithName:fontName size:20];
    
    UIView *view = [[UIView alloc] initWithFrame:[CCDirector sharedDirector].view.bounds];
    [view setBackgroundColor:[UIColor clearColor]];
    [[CCDirector sharedDirector].view addSubview:view];
    mainView = view;
    
    CGFloat labelWidth = (320.0 - 10.0) / 2;
    CGSize contentSize = [CCDirector sharedDirector].winSize;
    killSprite = [[CCSprite alloc] initWithSpriteFrameName:@"skull.png"];
    killSprite.anchorPoint = ccp(0, 0);
    killSprite.scale = [UIScreen mainScreen].scale * 2;
    killSprite.position = ccp(5.0, contentSize.height - killSprite.contentSize.height * killSprite.scale - 15.0);
    killSprite.zOrder = 5000;
    [self addChild:killSprite];
    
    killsLabel = [[UILabel alloc] initWithFrame:CGRectMake(38.0, 17.0, labelWidth - 28.0, 21.0)];
    [killsLabel setTextAlignment:NSTextAlignmentLeft];
    [killsLabel setTextColor:[UIColor whiteColor]];
    [killsLabel setBackgroundColor:[UIColor clearColor]];
    [killsLabel setFont:font];
    [mainView addSubview:killsLabel];
    
    coinsSprite = [[CCSprite alloc] initWithSpriteFrameName:@"coin1.png"];
    coinsSprite.anchorPoint = ccp(0.5, 0.5);
    coinsSprite.zOrder = 5000;
    coinsSprite.scale = [UIScreen mainScreen].scale * 2;
    coinsSprite.position = ccp(contentSize.width - 20.0, contentSize.height - 26);
    [self addChild:coinsSprite];
    
    coinsLabel = [[UILabel alloc] initWithFrame:CGRectMake(labelWidth + 5, 17.0, labelWidth - 30.0, 21.0)];
    [coinsLabel setTextColor:[UIColor whiteColor]];
    [coinsLabel setTextAlignment:NSTextAlignmentRight];
    [coinsLabel setBackgroundColor:[UIColor clearColor]];
    [coinsLabel setFont:font];
    [mainView addSubview:coinsLabel];
    
    healthLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 215.0, 320.0, 40.0)];
    [healthLabel setTextColor:[UIColor redColor]];
    [healthLabel setFont:[UIFont fontWithName:fontName size:30]];
    [healthLabel setTextAlignment:NSTextAlignmentCenter];
    [healthLabel setBackgroundColor:[UIColor clearColor]];
    //[mainView addSubview:healthLabel];
    
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
    
    image = [UIImage imageNamed:@"pause"];
    image = [UIImage imageWithCGImage:[image CGImage] scale:[[UIScreen mainScreen] scale] * 2 orientation:image.imageOrientation];
    pauseButton = [[UIImageView alloc] initWithFrame:CGRectMake((contentSize.width - 24.0) / 2, 13.0, 24.0, 28.0)];
    [pauseButton.layer setMagnificationFilter:kCAFilterNearest];
    [pauseButton setImage:image];
    [pauseButton setUserInteractionEnabled:YES];
    [pauseButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pauseGame)]];
    [mainView addSubview:pauseButton];
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
    CGFloat offset = 0.0;
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
    else if (kills == 2) {
        [self addScoreAddLabelWithText:@"DOUBLE KILL!" pos:ccp([CCDirector sharedDirector].winSize.width * 0.5f, [CCDirector sharedDirector].winSize.height * 0.5) type:ScoreAddLabelTypeBlinking addSkull:NO];
    }
    else if (kills == 3) {
        [self addScoreAddLabelWithText:@"TRIPLE KILL!" pos:ccp([CCDirector sharedDirector].winSize.width * 0.5f, [CCDirector sharedDirector].winSize.height * 0.5) type:ScoreAddLabelTypeBlinking addSkull:NO];
    }
    else if (kills == 4) {
        [self addScoreAddLabelWithText:@"MEGA KILL!" pos:ccp([CCDirector sharedDirector].winSize.width * 0.5f, [CCDirector sharedDirector].winSize.height * 0.5) type:ScoreAddLabelTypeBlinking addSkull:NO];
    }
    else if (kills > 5) {
        [self addScoreAddLabelWithText:@"GODLIKE!" pos:ccp([CCDirector sharedDirector].winSize.width * 0.5f, [CCDirector sharedDirector].winSize.height * 0.5) type:ScoreAddLabelTypeBlinking addSkull:NO];
    }

    [AppDelegate player].points += kills * kills;
    [self updateUI];

    CCParticleSystemQuad *explosionParticleSystem = [[CCParticleSystemQuad alloc] initWithFile:kExplosionParticleSystemFileName];
    explosionParticleSystem.autoRemoveOnFinish = YES;
    explosionParticleSystem.position = pos;
    [particleBatchNode addChild:explosionParticleSystem];
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

    if ([AppDelegate player].coins < BOMB_COINS_COST) {

        [self addScoreAddLabelWithText:@"NOT ENOUGH COINS!" pos:ccp([CCDirector sharedDirector].winSize.width * 0.5f, [CCDirector sharedDirector].winSize.height * 0.5) type:ScoreAddLabelTypeBlinking addSkull:NO];

        [_bombSpawner cancelSpawning];
    }
    else {

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

#pragma mark - Gestures

- (void)longPressStarted:(CGPoint)pos {

    [bombSpawner startSpawningAtPos:pos];
}

- (void)longPressEnded {

    //NSLog(@"LongPress end");
    [bombSpawner cancelSpawning];
}

- (void)swipeStarted:(CGPoint)pos {

    //NSLog(@"Swipe start");
}

- (void)swipeMoved:(CGPoint)pos {

    //NSLog(@"Swipe moved");
    
    for (EnemySprite *enemy in swipeEnemies) {
        
        if (lineSegmentPointDistance2(gestureRecognizer.lastPos, pos, enemy.position) < SWIPE_MIN_DISTANCE2) {
            
            [enemy throwFromWall];
        }
    }
}

- (void)swipeCancelled {

    //NSLog(@"Swipe cancelled");
}

- (void)swipeEnded:(CGPoint)pos {

    //NSLog(@"Swipe ended");
}

- (void)tapRecognized:(CGPoint)pos {

    [[AudioManager sharedManager] scream];
    [[AudioManager sharedManager] stopBackgroundMusic];

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
        
            [enemy throwFromWall];
        }
        */
    }

    if (nearestEnemy && nearestDistance < TAP_MIN_DISTANCE2) {
        
        [nearestEnemy throwFromWall];

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
    }
}

- (void) pauseGame {
    [self setPause:YES];
    
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
    
    menuBackground = [[CCLayerColor alloc] initWithColor:ccc4(0, 0, 0, 0.6 * 255)];
    menuBackground.contentSize = [[CCDirector sharedDirector] winSize];
    menuBackground.zOrder = 2000;
    [self addChild:menuBackground];
    
    gameOver = YES;
    CGSize screen = [CCDirector sharedDirector].winSize;
    gameOverLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, screen.width, screen.height)];
    [gameOverLabel setTextColor:[UIColor whiteColor]];
    [gameOverLabel setTextAlignment:NSTextAlignmentCenter];
    [gameOverLabel setFont:[UIFont fontWithName:fontName size:30]];
    [gameOverLabel setText:@"Game Over, Loser!"];
    [gameOverLabel setBackgroundColor:[UIColor clearColor]];
    [mainView addSubview:gameOverLabel];

    restartButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [restartButton setFrame:CGRectMake((screen.width - 126.0) / 2, (screen.height - 44.0) / 2 + 50.0, 126.0, 44.0)];
    [restartButton setTitle:@"Restart" forState:UIControlStateNormal];
    [restartButton.titleLabel setFont:[UIFont fontWithName:fontName size:20]];
    [restartButton addTarget:self action:@selector(restartGame) forControlEvents:UIControlEventTouchUpInside];
    [mainView addSubview:restartButton];

    [mainView bringSubviewToFront:coinsLabel];
    [mainView bringSubviewToFront:killsLabel];
    [mainView bringSubviewToFront:pauseButton];
    [rageView setAlpha:0];
    [rageBackgroundView setAlpha:0];
    [pauseButton setAlpha:0];
    
    [[AppDelegate player] storeScore:[AppDelegate player].points];
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

    [rageView setAlpha:1];
    [rageBackgroundView setAlpha:1];
    [pauseButton setAlpha:1];
    
    [menuBackground removeFromParentAndCleanup:YES];
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

    // Slime
    [slimeSprite setEnergy:[AppDelegate player].health * 0.01];
    [slimeSprite calc:deltaTime];

    slimeTop.position = ccp([CCDirector sharedDirector].winSize.width * 0.5, CGRectGetMaxY(slimeSprite.boundingBox));    

    // Monster
    [monsterSprite calc:deltaTime];
    [monsterHearth calc:deltaTime];

    // Shake
    [screenShaker calc:deltaTime];
    self.position = screenShaker.offset;

    // Add bubbles
    if (slimeSprite.boundingBox.size.height > 10 && rand() % 100 == 0) {
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

-(float) slimeSurfacePosY {
    
    return CGRectGetMaxY(slimeSprite.boundingBox);
}


@end