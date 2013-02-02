//
//  MainMenu.m
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 2/2/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "MainMenu.h"
#import "MenuButton.h"
#import "MenuCoinSprite.h"

#define MENU_CCNODES_Z_ORDER 3000

#define MAIN_MENU_BUTTON_SEPARATOR 10
#define MAIN_MENU_BUTTON_HEIGHT 48
#define MAIN_MENU_BUTTON_WIDTH 200

#define COIN_HORIZONTAL_PADDING 30

#define IMAGE_BUTTON_HORIZONTAL_SEPARATOR 6
#define IMAGE_BUTTON_SIZE 50

@interface MainMenu() {

    UIView *parentView;
    CCNode *parentNode;
    CGRect bounds;

    // UIKit elements
    UIImageView *logoImageView;
    MenuButton *newGameButton;
    MenuButton *removeAdsButton;
    MenuButton *creditsButton;
    MenuButton *achievementsButton;
    MenuButton *leaderboardsButton;
    MenuButton *soundButton;

    // Cocos elements
    CCLayerColor *backgroundLayer;
    MenuCoinSprite *leftCoinSprite;
    MenuCoinSprite *rightCoinSprite;

    BOOL visible;
}

@end

@implementation MainMenu

- (id)initWithParentView:(UIView*)initParentView parentNode:(CCNode*)initParentNode bounds:(CGRect)initBounds {

    self = [super init];
    if (self) {
        bounds = initBounds;
        parentView = initParentView;
        parentNode = initParentNode;
    }
    return self;
}

#pragma mark - Actions

- (void)show{

    if (visible) {
        return;
    }
    visible = YES;

    CGRect frame;

    // BG
    if (!backgroundLayer) {
        backgroundLayer = [[CCLayerColor alloc] initWithColor:ccc4(0, 0, 0, 150) width:[CCDirector sharedDirector].winSize.width height:[CCDirector sharedDirector].winSize.height];
        backgroundLayer.zOrder = MENU_CCNODES_Z_ORDER;
        [parentNode addChild:backgroundLayer];
    }

    // Logo
    if (!logoImageView) {
        logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"menu-logo"]];
        logoImageView.layer.contentsScale = [UIScreen mainScreen].scale * 2;
        logoImageView.layer.magnificationFilter = kCAFilterNearest;
        [parentView addSubview:logoImageView];
    }
    frame = logoImageView.frame;
    frame.size.width *= 2;
    frame.size.height *= 2;
    frame.origin.x = roundf((bounds.size.width - frame.size.width) * 0.5f);
    frame.origin.y = bounds.origin.y + 30.0f;
    logoImageView.frame = frame;
    logoImageView.hidden = NO;

    // Buttons
    int numberOfButtons = 3;
    CGPoint buttonOffset;
    buttonOffset.x = roundf(bounds.size.width * 0.5f - MAIN_MENU_BUTTON_WIDTH * 0.5f);
    buttonOffset.y = roundf(bounds.size.height * 0.5f - (MAIN_MENU_BUTTON_SEPARATOR * (numberOfButtons - 1) + MAIN_MENU_BUTTON_HEIGHT * numberOfButtons) * 0.5f);
    
    if (!newGameButton) {
        newGameButton = [[MenuButton alloc] initWithFrame:CGRectZero];
        [newGameButton setImage:[UIImage imageNamed:@"menu-newgame"]];
        [newGameButton setHighlightedImage:[UIImage imageNamed:@"menu-newgame-h"]];
        [newGameButton addTarget:self action:@selector(newGameButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [parentView addSubview:newGameButton];
    }
    newGameButton.frame = CGRectMake(buttonOffset.x, buttonOffset.y, MAIN_MENU_BUTTON_WIDTH, MAIN_MENU_BUTTON_HEIGHT);    
    newGameButton.hidden = NO;

    buttonOffset.y += MAIN_MENU_BUTTON_SEPARATOR + MAIN_MENU_BUTTON_HEIGHT;

    if (!removeAdsButton) {
        removeAdsButton = [[MenuButton alloc] initWithFrame:CGRectZero];
        [removeAdsButton setImage:[UIImage imageNamed:@"RemoveAdsButton.png"]];
        [removeAdsButton setHighlightedImage:[UIImage imageNamed:@"RemoveAdsButtonHL.png"]];
        [removeAdsButton addTarget:self action:@selector(startGameButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [parentView addSubview:removeAdsButton];
    }
    removeAdsButton.frame = CGRectMake(buttonOffset.x, buttonOffset.y, MAIN_MENU_BUTTON_WIDTH, MAIN_MENU_BUTTON_HEIGHT);
    removeAdsButton.hidden = NO;

    buttonOffset.y += MAIN_MENU_BUTTON_SEPARATOR + MAIN_MENU_BUTTON_HEIGHT;

    if (!creditsButton) {
        creditsButton = [[MenuButton alloc] initWithFrame:CGRectZero];
        [creditsButton setImage:[UIImage imageNamed:@"CreditsButton.png"]];
        [creditsButton setHighlightedImage:[UIImage imageNamed:@"CreditsButtonHL.png"]];
        [creditsButton addTarget:self action:@selector(creditsButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [parentView addSubview:creditsButton];
    }
    creditsButton.frame = CGRectMake(buttonOffset.x, buttonOffset.y, MAIN_MENU_BUTTON_WIDTH, MAIN_MENU_BUTTON_HEIGHT);
    creditsButton.hidden = NO;

    if (!achievementsButton) {
        achievementsButton = [[MenuButton alloc] initWithFrame:CGRectZero];
        [achievementsButton setImage:[UIImage imageNamed:@"AchievementsButton.png"]];
        [achievementsButton setHighlightedImage:[UIImage imageNamed:@"AchievementsButtonHL.png"]];
        [achievementsButton addTarget:self action:@selector(startGameButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [parentView addSubview:achievementsButton];
    }
    achievementsButton.frame = CGRectMake(bounds.origin.x + IMAGE_BUTTON_HORIZONTAL_SEPARATOR, CGRectGetMaxY(bounds) - IMAGE_BUTTON_SIZE - 2, IMAGE_BUTTON_SIZE, IMAGE_BUTTON_SIZE);
    achievementsButton.hidden = NO;

    if (!leaderboardsButton) {
        leaderboardsButton = [[MenuButton alloc] initWithFrame:CGRectZero];
        [leaderboardsButton setImage:[UIImage imageNamed:@"LeaderboardsButton.png"]];
        [leaderboardsButton setHighlightedImage:[UIImage imageNamed:@"LeaderboardsButtonHL.png"]];
        [leaderboardsButton addTarget:self action:@selector(startGameButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [parentView addSubview:leaderboardsButton];
    }
    leaderboardsButton.frame = CGRectMake(CGRectGetMaxX(achievementsButton.frame) + IMAGE_BUTTON_HORIZONTAL_SEPARATOR, CGRectGetMaxY(bounds) - IMAGE_BUTTON_SIZE - 2, IMAGE_BUTTON_SIZE, IMAGE_BUTTON_SIZE);
    leaderboardsButton.hidden = NO;

    if (!soundButton) {
        soundButton = [[MenuButton alloc] initWithFrame:CGRectZero];
        [soundButton setImage:[UIImage imageNamed:@"SoundButton.png"]];
        [soundButton setHighlightedImage:[UIImage imageNamed:@"SoundButtonHL.png"]];
        [soundButton addTarget:self action:@selector(startGameButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [parentView addSubview:soundButton];
    }
    soundButton.frame = CGRectMake(CGRectGetMaxX(bounds) - IMAGE_BUTTON_HORIZONTAL_SEPARATOR - IMAGE_BUTTON_SIZE, CGRectGetMaxY(bounds) - IMAGE_BUTTON_SIZE - 2, 50, IMAGE_BUTTON_SIZE);
    soundButton.hidden = NO;

    // Coins
    if (!leftCoinSprite) {
        leftCoinSprite = [[MenuCoinSprite alloc] init];
        leftCoinSprite.anchorPoint = ccp(0.5f, 0.5f);
        leftCoinSprite.zOrder = MENU_CCNODES_Z_ORDER;
        [parentNode addChild:leftCoinSprite];
    }
    leftCoinSprite.position = ccp(CGRectGetMinX(logoImageView.frame) - COIN_HORIZONTAL_PADDING, [CCDirector sharedDirector].winSize.height - CGRectGetMidY(logoImageView.frame));
    leftCoinSprite.visible = YES;

    if (!rightCoinSprite) {
        rightCoinSprite = [[MenuCoinSprite alloc] init];
        rightCoinSprite.anchorPoint = ccp(0.5f, 0.5f);
        rightCoinSprite.zOrder = MENU_CCNODES_Z_ORDER;
        [parentNode addChild:rightCoinSprite];
    }
    rightCoinSprite.position = ccp(CGRectGetMaxX(logoImageView.frame) + COIN_HORIZONTAL_PADDING, [CCDirector sharedDirector].winSize.height - CGRectGetMidY(logoImageView.frame));    
    rightCoinSprite.visible = YES;
}

- (void)hide {

    if (!visible) {
        return;
    }
    visible = NO;

    logoImageView.hidden = YES;
    newGameButton.hidden = YES;
    removeAdsButton.hidden = YES;
    creditsButton.hidden = YES;
    achievementsButton.hidden = YES;
    leaderboardsButton.hidden = YES;
    soundButton.hidden = YES;
    leftCoinSprite.visible = NO;
    rightCoinSprite.visible = NO;
    backgroundLayer.visible = NO;
}

- (void)showEndGameMenuWithScore:(int)score {
/*
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
*/
}

- (void)newGameButtonPressed {

    [_delegate mainMenuNewGameButtonWasPressed:self];
}

- (void)creditsButtonPressed {

    [_delegate mainMenuCreditsButtonWasPressed:self];
}

- (void)calc:(ccTime)deltaTime {

    if (leftCoinSprite.visible) {
        [leftCoinSprite calc:deltaTime];
    }

    if (rightCoinSprite.visible) {
        [rightCoinSprite calc:deltaTime];
    }
}

@end
