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
#import "CoinSprite.h"
#import "SlimeSprite.h"
#import "MonsterSprite.h"
#import "MasterControlProgram.h"
#import "ScreenShaker.h"
#import "MonsterHearth.h"
#import "MainMenuGameScene.h"
#import "MenuCoinSprite.h"
#import "MenuButton.h"
#import "Geom.h"

#define MAX_DELTA_TIME 0.1f
#define MAX_CALC_TIME 0.1f
#define FRAME_TIME_INTERVAL (1.0f / 60)

#define GAME_OBJECTS_Z_ORDER 30

#define BOMB_COINS_COST 2

#define TAP_MIN_DISTANCE2 (60*60)
#define TAP_THROW_MIN_DISTANCE2 (60*60)
#define TAP_PICK_COIN_MIN_DISTANCE2 (50*50)
#define SWIPE_MIN_DISTANCE2 (30*30)

#define SLIME_WIDTH 280
#define SLIME_GROUND_Y (GROUND_Y + 1)
#define SLIME_MAX_HEIGHT 300

@interface MainGameScene() {

    float calcTime;

    // Sprite batch
    CCSpriteBatchNode *mainSpriteBatch;

    // Particle batch
    CCParticleBatchNode *particleBatchNode;
    
    // HUD
    GameHUD *gameHUD;

    // Menu
    MainMenu *mainMenu;
    id <Menu> activeMenu;

    // Game enviroment
    SlimeSprite *slimeSprite;
    CCSprite *slimeTopSprite;
    MonsterSprite *monsterSprite;
    MonsterHearth *monsterHearth;

    // Helpers
    MasterControlProgram *masterControlProgram;    
    BombSpawner *bombSpawner;
    ScreenShaker *screenShaker;
    GestureRecognizer *gestureRecognizer;

    // State vars
    BOOL sceneInitWasPerformed;

    // Data
    NSArray *killingStreakTexts;

    // Game object manager
    GameObjectManager *gameObjectManager;

    // Leaderboard
    GKLeaderboard *leaderboard;
}

@end


@implementation MainGameScene

- (void)onEnter {

    [super onEnter];

    [self initScene];
}

- (void)onExit {

}

- (void)initScene {

    if (sceneInitWasPerformed) {
        return;
    }
    sceneInitWasPerformed = YES;

    // Gestures
    gestureRecognizer = [[GestureRecognizer alloc] init];
    gestureRecognizer.delegate = self;
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:gestureRecognizer priority:0 swallowsTouches:YES];

    // Leaderboard
    leaderboard = [[GKLeaderboard alloc] init];
    
    // Screen shaker
    screenShaker = [[ScreenShaker alloc] init];

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

    slimeTopSprite = [[CCSprite alloc] initWithSpriteFrameName:@"tankWaterLevel.png"];
    slimeTopSprite.scale = [UIScreen mainScreen].scale * 2;    
    slimeTopSprite.anchorPoint = ccp(0.5, 0);
    slimeTopSprite.position = ccp([CCDirector sharedDirector].winSize.width * 0.5, CGRectGetMaxY(slimeSprite.boundingBox));
    slimeTopSprite.zOrder = 11;
    [mainSpriteBatch addChild:slimeTopSprite];

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

    // HUD
    gameHUD = [[GameHUD alloc] initWithParentView:[CCDirector sharedDirector].view parentNode:self parentSpriteBatchNode:mainSpriteBatch bounds:[CCDirector sharedDirector].view.bounds];
    gameHUD.delegate = self;

    // Game object manager
    gameObjectManager = [[GameObjectManager alloc] initWithParentNode:self spriteBatchNode:mainSpriteBatch particleBatchNode:particleBatchNode];
    gameObjectManager.delegate = self;
    gameObjectManager.zOrder = GAME_OBJECTS_Z_ORDER;
    gameObjectManager.groundY = GROUND_Y;
    gameObjectManager.coinPickupAnimationDestinationPos = gameHUD.coinsSpritePosition;

    // Data
    killingStreakTexts = @[@"", @"Double Kill!", @"Triple Kill!", @"Quadro Kill!", @"Mega Kill!", @"Unbelievable!", @"Mega Kill!", @"Giga Kill!", @"Godlike!"];

    // Audio
    [[AudioManager sharedManager] startBackgroundMusic];

    // Update
    [self scheduleUpdate];

    // Start with main menu
    [self presentMainMenu];
}

#pragma mark - GameObjectManagerDelegate

- (void)gameObjectManager:(GameObjectManager*)gameObjectManager bombDidDie:(BombSprite*)bombSprite {

    [screenShaker shake];
}

- (CGFloat)gameObjectManagerSlimeSurfacePosY:(GameObjectManager*)gameObjectManager {

    return CGRectGetMaxY(slimeSprite.boundingBox);    
}

#pragma mark - Menu

- (void)presentMainMenu {

    if (!mainMenu) {
        mainMenu = [[MainMenu alloc] initWithParentView:[CCDirector sharedDirector].view parentNode:self bounds:[CCDirector sharedDirector].view.bounds];
        mainMenu.delegate = self;
    }
    [mainMenu show];
    activeMenu = mainMenu;

    [gameHUD hide];
}

- (void)startNewGame {

    [activeMenu hide];
    activeMenu = nil;

    [gameHUD show];
}

#pragma mark - BombSpawnerDelegate

- (void)bombSpawnerWantsBombToSpawn:(BombSpawner *)_bombSpawner {

    if ([AppDelegate player].coins < BOMB_COINS_COST) {

        [gameObjectManager addScoreAddLabelWithText:@"NOT ENOUGH COINS!" pos:ccp([CCDirector sharedDirector].winSize.width * 0.5f, [CCDirector sharedDirector].winSize.height * 0.5) type:ScoreAddLabelTypeBlinking addSkull:NO];

        [_bombSpawner cancelSpawning];
    }
    else {

        [[AudioManager sharedManager] bombReleased];
        [gameObjectManager addBombAtPosX:bombSpawner.pos.x];

        [[AppDelegate player] updateDropBombCount:1];

        [AppDelegate player].coins -= BOMB_COINS_COST;

        [_bombSpawner startEndAnimation];
    }
}

#pragma mark - AboutViewControllerDelegate

- (void)aboutViewControllerDidFinish:(AboutViewController *)viewController {

    [viewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - MainFrame

- (void)masterControlProgram:(MasterControlProgram*)masterControlProgram addEnemy:(EnemyType)type {

    [gameObjectManager addEnemy:type];
}

- (int)masterControlProgramNumberOfTapEnemies:(MasterControlProgram*)masterControlProgram {

    return [gameObjectManager.tapEnemies count];
}

- (int)masterControlProgramNumberOfSwipeEnemies:(MasterControlProgram*)masterControlProgram {

    return [gameObjectManager.swipeEnemies count];
}

- (void)masterControlProgram:(MasterControlProgram*)masterControlProgram addCoinAtPos:(CGPoint)pos {

    [gameObjectManager addCoinAtPos:pos];
}

- (int)masterControlProgramNumberOfPlayerCoins:(MasterControlProgram*)masterControlProgram {

    return [AppDelegate player].coins;    
}

#pragma mark - MainMenuDelegate 

- (void)mainMenuNewGameButtonWasPressed:(MainMenu*)menu {

    [self startNewGame];
}

- (void)mainMenuCreditsButtonWasPressed:(MainMenu*)menu {

    AboutViewController *newViewController = [[AboutViewController alloc] initWithNibName:@"AboutViewController" bundle:nil];
    newViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    newViewController.delegate = self;
    [[CCDirector sharedDirector] presentViewController:newViewController animated:YES completion:nil];
}

- (void)mainMenuRemoveAdsButtonWasPressed:(MainMenu*)menu {

}

- (void)mainMenuAchievementsButtonWasPressed:(MainMenu*)menu {

}

- (void)mainMenuLeaderboardsButtonWasPressed:(MainMenu*)menu {

}

- (void)mainMenuSoundButtonWasPressed:(MainMenu*)menu {

}

#pragma mark - GameHUDDelegate

- (void)gameHUDPauseButtonWasPressed:(GameHUD *)gameHUD {

    [self presentMainMenu];
}

#pragma mark - Gestures

- (void)longPressStarted:(CGPoint)pos {

    [[AudioManager sharedManager] bombSpawningStarted];
    
    [bombSpawner startSpawningAtPos:pos];
}

- (void)longPressEnded {
    
    if (bombSpawner.spawning) {
        [[AudioManager sharedManager] bombSpawningCancelled];
    }
    
    [bombSpawner cancelSpawning];
}

- (void)swipeStarted:(CGPoint)pos {

}

- (void)swipeMoved:(CGPoint)pos {
    
    for (EnemySprite *enemy in gameObjectManager.swipeEnemies) {
        
        if (lineSegmentPointDistance2(gestureRecognizer.lastPos, pos, enemy.position) < SWIPE_MIN_DISTANCE2) {
            
            [gameObjectManager sliceEnemyFromWall:enemy direction:ccpSub(pos, gestureRecognizer.lastPos)];
        }
    }
    
    [gameObjectManager updateTrailWithStartPos:gestureRecognizer.startPos endPos:pos];
}

- (void)swipeCancelled {

    [gameObjectManager cancelTrail];
}

- (void)swipeEnded:(CGPoint)pos {

    [gameObjectManager cancelTrail];
}

- (void)tapRecognized:(CGPoint)pos {

    CoinSprite *nearestCoin = nil;
    float nearestDistance = -1;
    
    NSMutableArray *pickedCoins = [[NSMutableArray alloc] initWithCapacity:10];
    
    for (CoinSprite *coin in gameObjectManager.coins) {
        
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
        
        [gameObjectManager pickupCoin:nearestCoin];
        
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
    for (EnemySprite *enemy in gameObjectManager.tapEnemies) {
        
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
        
        [gameObjectManager throwEnemyFromWall:nearestEnemy];
        return;
    }

    nearestEnemy = nil;
    nearestDistance = - 1;
    for (EnemySprite *enemy in gameObjectManager.swipeEnemies) {
        
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
        
        [gameObjectManager throwEnemyFromWall:nearestEnemy];
        return;
    }
}

#pragma mark - Update

- (void)calc:(ccTime)deltaTime {

    // Gestures
    [gestureRecognizer update:deltaTime];

    // Game objects
    [gameObjectManager calc:deltaTime];
    [bombSpawner calc:deltaTime];

    // Master control
    [masterControlProgram calc:deltaTime];
    
    if ([AppDelegate player].rage >= 1.0) {
        [gameObjectManager addBombAtPosX:80.0];
        [gameObjectManager addBombAtPosX:160.0];
        [gameObjectManager addBombAtPosX:240.0];
        [[AppDelegate player] updateDropBombCount:3];
        [AppDelegate player].rage = 0;
    }

    // Player Model
    [[AppDelegate player] calc:deltaTime];

    // Slime
    [slimeSprite setEnergy:[AppDelegate player].health * 0.01];
    [slimeSprite calc:deltaTime];

    slimeTopSprite.position = ccp([CCDirector sharedDirector].winSize.width * 0.5, CGRectGetMaxY(slimeSprite.boundingBox));    

    // Monster
    [monsterSprite calc:deltaTime];
    [monsterHearth calc:deltaTime];

    // Shake
    [screenShaker calc:deltaTime];
    self.position = screenShaker.offset;

    // Add bubbles
    if (slimeSprite.boundingBox.size.height > 10 && rand() % 100 == 0) {
        [gameObjectManager addBubble:ccp(slimeSprite.boundingBox.origin.x + (slimeSprite.boundingBox.size.width - 40) * rand() / RAND_MAX + 20, GROUND_Y + 5 + rand() % 7)];
    }

    // Killing texts
    if (gameObjectManager.numberOfKillsInLastCalc > 0 && gameObjectManager.numberOfKillsInLastCalc - 1 < [killingStreakTexts count] && [killingStreakTexts[gameObjectManager.numberOfKillsInLastCalc - 1] length] > 0) {
        [gameObjectManager addScoreAddLabelWithText:killingStreakTexts[gameObjectManager.numberOfKillsInLastCalc - 1] pos:ccp([CCDirector sharedDirector].winSize.width * 0.5f, [CCDirector sharedDirector].winSize.height * 0.5) type:ScoreAddLabelTypeBlinking addSkull:NO];
    }

    // Menu
    [activeMenu calc:deltaTime];
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
    // deltaTime = FRAME_TIME_INTERVAL * 2;

    while (calcTime >= FRAME_TIME_INTERVAL) {

        [self calc:FRAME_TIME_INTERVAL];
        calcTime -= FRAME_TIME_INTERVAL;
    }

    // static int frameNum = 0;
    // [CaptureScreen saveAndCaptureScreen:frameNum];
    // frameNum++;
}

@end