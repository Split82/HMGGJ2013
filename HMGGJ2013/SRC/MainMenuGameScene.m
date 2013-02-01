//
//  MenuGameScene.m
//  HMGGJ2013
//
//  Created by Lukáš Foldýna on 26.01.13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "MainMenuGameScene.h"
#import "AboutViewController.h"
#import "AppDelegate.h"
#import "PlayerModel.h"
#import "CCDirector.h"
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
#import "MainGameScene.h"
#import "MenuCoinSprite.h"
#import "MonsterHearth.h"
#import "MenuButton.h"
#import <GameKit/GameKit.h>
#import "AudioManager.h"


#define GAME_OBJECTS_Z_ORDER 30

#define MAX_DELTA_TIME 0.1f
#define MAX_CALC_TIME 0.1f
#define FRAME_TIME_INTERVAL (1.0f / 60)

#define SLIME_WIDTH 280
#define SLIME_GROUND_Y (GROUND_Y + 1)
#define SLIME_MAX_HEIGHT 300


@interface MainMenuGameScene () <GKLeaderboardViewControllerDelegate, GKAchievementViewControllerDelegate>
{
    float calcTime;
    
    NSMutableArray *coins;
    NSMutableArray *bubbles;
    NSMutableArray *killedBubbles;
    
    MenuButton *newgame;
    
    CCSpriteBatchNode *mainSpriteBatch;
    SlimeSprite *slimeSprite;
    MonsterSprite *monsterSprite;
    MonsterHearth *monsterHearth;
    
    CCParticleBatchNode *particleBatchNode;
    
    BOOL sceneInitWasPerformed;
    
    UIView *mainView;
}

@end

@implementation MainMenuGameScene

@synthesize mainView = mainView;

- (void)onEnter {
    
    [super onEnter];
    
    [self initScene];
}

- (void)initScene {
    
    if (sceneInitWasPerformed) {
        if (![mainView superview]) {
            [[CCDirector sharedDirector].view addSubview:mainView];
        }
        return;
    }
    sceneInitWasPerformed = YES;
    
    // Game objects
    coins = [[NSMutableArray alloc] initWithCapacity:100];
    bubbles = [[NSMutableArray alloc] initWithCapacity:40];
    
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
    
    // Slime
    slimeSprite = [[SlimeSprite alloc] initWithWidth:SLIME_WIDTH maxHeight:SLIME_MAX_HEIGHT];
    [slimeSprite setActualEnergy:0.5];
    slimeSprite.anchorPoint = ccp(0.5, 0);
    slimeSprite.position = ccp([CCDirector sharedDirector].winSize.width * 0.5, SLIME_GROUND_Y);
    slimeSprite.zOrder = 10;
    [mainSpriteBatch addChild:slimeSprite];
    
    // Monster
    monsterSprite = [[MonsterSprite alloc] init];
    monsterSprite.anchorPoint = ccp(0.5, 0);
    monsterSprite.position = ccp([CCDirector sharedDirector].winSize.width * 0.5, GROUND_Y + 2);
    monsterSprite.zOrder = 3;
    [mainSpriteBatch addChild:monsterSprite];
    
    monsterHearth = [[MonsterHearth alloc] init];
    monsterHearth.anchorPoint = ccp(0.5, 0);
    monsterHearth.position = ccp([CCDirector sharedDirector].winSize.width * 0.5, CGRectGetMaxY(monsterSprite.boundingBox) + 123.0);
    monsterHearth.zOrder = 5000;
    [self addChild:monsterHearth];
    
    // Foreground
    CCSprite *foregroundSprite = [[CCSprite alloc] initWithSpriteFrameName:@"tankGraphic.png"];
    foregroundSprite.anchorPoint = ccp(0.5, 0);
    foregroundSprite.position = ccp([CCDirector sharedDirector].winSize.width * 0.5, GROUND_Y - 1);
    foregroundSprite.scale = [UIScreen mainScreen].scale * 2;
    foregroundSprite.zOrder = 20;
    [mainSpriteBatch addChild:foregroundSprite];
    
    // Floor
    CCSprite *floorSprite = [[CCSprite alloc] initWithSpriteFrameName:@"Floor.png"];
    floorSprite.zOrder = 30;
    floorSprite.anchorPoint = ccp(0.5, 1);
    floorSprite.position = ccp([CCDirector sharedDirector].winSize.width * 0.5, GROUND_Y - 1);
    floorSprite.scale = [UIScreen mainScreen].scale * 2;
    [self addChild:floorSprite];
    
    CCLayer *layer = [[CCLayerColor alloc] initWithColor:ccc4(0, 0, 0, 0.6 * 255)];
    layer.contentSize = [[CCDirector sharedDirector] winSize];
    layer.zOrder = 2000;
    [self addChild:layer];
    
    [[AudioManager sharedManager] startMenuMusic];
    
    // Update
    [self scheduleUpdate];
    
    [self initUI];
}

- (void)initUI {
    
    mainView = [[UIView alloc] initWithFrame:[CCDirector sharedDirector].view.bounds];
    mainView.backgroundColor = [UIColor clearColor];
    [[CCDirector sharedDirector].view addSubview:mainView];
    
    CGFloat offset = 0.0;
    if (!IS_WIDESCREEN) {
        offset = 44.0;   
    }
    UIImageView *nameView = [[UIImageView alloc] initWithImage:[MenuButton rasterizedImage:@"menu-logo"]];
    [nameView setFrame:[MenuButton rectWithSize:CGSizeMake(80, 39) originY:128.0 - offset]];
    [nameView.layer setMagnificationFilter:kCAFilterNearest];
    [mainView addSubview:nameView];
    
    CGFloat offsetY = 270.0 - offset - 6.0;
    CGRect frame = CGRectMake(60.0, offsetY, 200.0, 48.0);
    newgame = [[MenuButton alloc] initWithFrame:frame];
    [newgame setImage:[UIImage imageNamed:@"menu-newgame"]];
    [newgame setHighlightedImage:[UIImage imageNamed:@"menu-newgame-h"]];
    [newgame addTarget:self action:@selector(startGameButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [mainView addSubview:newgame];
    
    frame.origin.y += frame.size.height + 5.0;
    MenuButton *leaderboard = [[MenuButton alloc] initWithFrame:frame];
    [leaderboard setImage:[UIImage imageNamed:@"menu-topscore"]];
    [leaderboard setHighlightedImage:[UIImage imageNamed:@"menu-topscore-h"]];
    [leaderboard addTarget:self action:@selector(showLeaderboardButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [mainView addSubview:leaderboard];
    
    frame.origin.y += frame.size.height + 5.0;
    MenuButton *achievements = [[MenuButton alloc] initWithFrame:frame];
    [achievements setImage:[UIImage imageNamed:@"menu-achievements"]];
    [achievements setHighlightedImage:[UIImage imageNamed:@"menu-achievements-h"]];
    [achievements addTarget:self action:@selector(showAchievementsButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [mainView addSubview:achievements];
    
   frame.origin.y += frame.size.height + 5.0;
    MenuButton *aboutView = [[MenuButton alloc] initWithFrame:frame];
    [aboutView setImage:[UIImage imageNamed:@"menu-about"]];
    [aboutView setHighlightedImage:[UIImage imageNamed:@"menu-about-h"]];
    [aboutView addTarget:self action:@selector(showAboutButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [mainView addSubview:aboutView];
    
    [self addCoinAtPos:CGPointMake(60.0, 400.0 - offset)];
    [self addCoinAtPos:CGPointMake(260.0, 400.0 - offset)];
}

- (void) setGame:(BOOL)game
{
    if (!_game && game) {
        [newgame setImage:[UIImage imageNamed:@"menu-resume"]];
        [newgame setHighlightedImage:[UIImage imageNamed:@"menu-resume-h"]];
    }
    _game = game;
}

#pragma mark - Objects

- (void)addBubble:(CGPoint)pos {
    
    SlimeBubbleSprite *newBubble = [[SlimeBubbleSprite alloc] initWithPos:pos];
    newBubble.zOrder = 7;
    [mainSpriteBatch addChild:newBubble];
    [bubbles addObject:newBubble];
}

- (void)addCoinAtPos:(CGPoint)pos {
    
    MenuCoinSprite *newCoin = [[MenuCoinSprite alloc] init];
    newCoin.anchorPoint = ccp(0.5f, 0.5f);
    newCoin.position = pos;
    newCoin.zOrder = 3000;
    [coins addObject:newCoin];
    [self addChild:newCoin];
}

-(void)coinEndedCashingAnimation:(MenuCoinSprite*)coin {
    
    [coin removeFromParentAndCleanup:YES];
}

#pragma mark - Update

- (void)calc:(ccTime)deltaTime {
    
    for (MenuCoinSprite *coin in coins) {
        [coin calc:deltaTime];
    }
    
    for (SlimeBubbleSprite *bubble in bubbles) {
        [bubble calc:deltaTime];
        if (bubble.position.y > CGRectGetMaxY(slimeSprite.boundingBox) - bubble.boundingBox.size.height) {
            [killedBubbles addObject:bubble];
        }
    }
    
    for (SlimeBubbleSprite *bubble in killedBubbles) {
        [bubbles removeObject:bubble];
        [bubble removeFromParentAndCleanup:YES];
    }
    [killedBubbles removeAllObjects];

    [slimeSprite calc:deltaTime];
    
    [monsterSprite calc:deltaTime];
    [monsterHearth calc:deltaTime];
    
    // Add bubbles
    if (rand() % 100 == 0) {
        [self addBubble:ccp(slimeSprite.boundingBox.origin.x + (slimeSprite.boundingBox.size.width - 40) * rand() / RAND_MAX + 20, GROUND_Y + 5 + rand() % 7)];
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

#pragma mark -

- (void)setDisplayGameCenter:(BOOL)displayGameCenter {
    _displayGameCenter = displayGameCenter;
    [self.topScoreButton setEnabled:displayGameCenter];
    [self.achievementsButton setEnabled:displayGameCenter];
}

- (IBAction)startGameButtonPressed:(id)sender {
    if ([self game]) {
        MainGameScene *scene = (MainGameScene *)[[CCDirector sharedDirector] runningScene];
        [scene.menuBackground removeFromParentAndCleanup:YES];
        [scene.mainView setAlpha:0];
        [scene setPause:NO];
        [[CCDirector sharedDirector].view addSubview:scene.mainView];
        
        [UIView animateWithDuration:0.25 animations:^{
            [mainView setAlpha:0];
            [scene.mainView setAlpha:1];
        } completion:^(BOOL finished) {
            [mainView setAlpha:1];
            [mainView removeFromSuperview];
        }];
        [[CCDirector sharedDirector] resume];
    } else {
        MainGameScene *scene = [[MainGameScene alloc] init];
        
        [UIView animateWithDuration:0.25 animations:^{
            [mainView setAlpha:0];
        } completion:^(BOOL finished) {
            [mainView setAlpha:1];
            [mainView removeFromSuperview];
        }];
        [[CCDirector sharedDirector] pushScene:scene];
        
        [[AppDelegate player] gameStarted];
    }
}

- (IBAction)showLeaderboardButtonPressed:(id)sender {
    GKLeaderboardViewController *controller = [[GKLeaderboardViewController alloc] init];
    [controller setCategory:kTopScoreName];
    [controller setLeaderboardDelegate:self];
    [[CCDirector sharedDirector] presentViewController:controller animated:YES completion:NULL];
}

- (IBAction)showAchievementsButtonPressed:(id)sender {
    GKAchievementViewController *controller = [[GKAchievementViewController alloc] init];
    [controller setAchievementDelegate:self];
    [[CCDirector sharedDirector] presentViewController:controller animated:YES completion:NULL];
}

- (IBAction)showAboutButtonPressed:(id)sender {
    AboutViewController *controller = [[AboutViewController alloc] init];
    [controller setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
    [[CCDirector sharedDirector] presentViewController:controller animated:YES completion:NULL];
}

#pragma mark GKLeaderboardViewControllerDelegate

- (void)leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController {
    [[CCDirector sharedDirector] dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark GKAchievementViewControllerDelegate

- (void)achievementViewControllerDidFinish:(GKAchievementViewController *)viewController {
    [[CCDirector sharedDirector] dismissViewControllerAnimated:YES completion:NULL];
}

@end
