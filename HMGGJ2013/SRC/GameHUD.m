//
//  GameHUD.m
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 2/2/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "GameHUD.h"
#import "MenuButton.h"

#define HUD_CCNODES_Z_ORDER 2000
#define PAUSE_BUTTON_WIDTH 65
#define PAUSE_BUTTON_HEIGHT 44

#define RAGE_BAR_BOTTOM_PADDING 40
#define RAGE_PROGRESS_VIEW_MAX_WIDTH 272

#define TOP_SPRITE_PADDING 20

@interface GameHUD() {

    UIView *parentView;
    CCNode *parentNode;
    CCNode *parentSpriteBatchNode;
    CGRect bounds;

    CCSprite *scoreSprite;
    CCLabelBMFont *scoreLabel;

    CCSprite *coinsSprite;
    CCLabelBMFont *coinsLabel;

    MenuButton *pauseButton;

    UIView *rageProgressView;
    UIImageView *rageBackgroundView;
}

@end


@implementation GameHUD

- (id)initWithParentView:(UIView*)initParentView parentNode:(CCNode*)initParentNode parentSpriteBatchNode:(CCNode*)initParentSpriteBatchNode bounds:(CGRect)initBounds {

    self = [super init];
    if (self) {
        parentView = initParentView;
        parentNode = initParentNode;
        parentSpriteBatchNode = initParentSpriteBatchNode;
        bounds = initBounds;
    }
    return self;
}

#pragma mark - Helpers

- (void)updateScoreLabel {

    if (!scoreLabel) {
        scoreLabel = [[CCLabelBMFont alloc] initWithString:[NSString stringWithFormat:@"%d", _score] fntFile:@"PixelFont.fnt"];
        scoreLabel.scale = [UIScreen mainScreen].scale * 1.3;
        scoreLabel.anchorPoint = ccp(0.0f, 0.5f);
        scoreLabel.position = ccpAdd(ccp(CGRectGetMaxX(scoreSprite.boundingBox), scoreSprite.position.y), ccp(8, 2));
        scoreLabel.zOrder = HUD_CCNODES_Z_ORDER;
        [parentNode addChild:scoreLabel];
    }

    [scoreLabel setString:[NSString stringWithFormat:@"%d", _score]];
}

- (void)updateCoinsLabel {

    if (!coinsLabel) {
        coinsLabel = [[CCLabelBMFont alloc] initWithString:[NSString stringWithFormat:@"%d", _score] fntFile:@"PixelFont.fnt"];
        coinsLabel.scale = [UIScreen mainScreen].scale * 1.3;
        coinsLabel.anchorPoint = ccp(1, 0.5);
        coinsLabel.position = ccpAdd(ccp(CGRectGetMinX(coinsSprite.boundingBox), coinsSprite.position.y), ccp(-4, 2));
        coinsLabel.zOrder = HUD_CCNODES_Z_ORDER;
        [parentNode addChild:coinsLabel];
    }

    [coinsLabel setString:[NSString stringWithFormat:@"%d", _score]];    
}

- (void)updateRageProgressView {

    if (!rageProgressView) {
        rageProgressView = [[UIView alloc] initWithFrame:CGRectMake(24.0, CGRectGetMaxY(bounds) - RAGE_BAR_BOTTOM_PADDING + 8, 0.0, 8.0)];
        rageProgressView.clipsToBounds = YES;
        [parentView addSubview:rageProgressView];

        UIImageView *rageProgressImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, RAGE_PROGRESS_VIEW_MAX_WIDTH, 8.0)];
        rageProgressImageView.image = [UIImage imageNamed:@"progressBar"];
        rageProgressImageView.layer.contentsScale = [UIScreen mainScreen].scale * 2;
        rageProgressImageView.layer.magnificationFilter = kCAFilterNearest;
        [rageProgressView addSubview:rageProgressImageView];
    }

    CGRect frame = rageProgressView.frame;
    frame.size.width = RAGE_PROGRESS_VIEW_MAX_WIDTH * _rageProgress;
    rageProgressView.frame = frame;
}

#pragma mark - Setters

- (void)setScore:(int)score {

    if (score == _score) {
        return;
    }

    _score = score;
    [self updateScoreLabel];
}

- (void)setNumberOfCoins:(int)numberOfCoins {

    if (numberOfCoins == _numberOfCoins) {
        return;
    }

    _numberOfCoins = numberOfCoins;
    [self updateCoinsLabel];
}

- (void)setRageProgress:(float)rageProgress {

    if (rageProgress == _rageProgress) {
        return;
    }

    _rageProgress = rageProgress;
    [self updateRageProgressView];
}

#pragma mark - Getters

- (CGPoint)coinsSpritePosition {

    CGFloat topOffset = [CCDirector sharedDirector].winSize.height - bounds.origin.y;    
    return ccp(bounds.size.width - TOP_SPRITE_PADDING, topOffset - TOP_SPRITE_PADDING);
}

#pragma mark - Actions

- (void)show {

    CGFloat topOffset = [CCDirector sharedDirector].winSize.height - bounds.origin.y;

    if (!scoreSprite) {
        scoreSprite = [[CCSprite alloc] initWithSpriteFrameName:@"skull.png"];
        scoreSprite.scale = [UIScreen mainScreen].scale * 2;        
        scoreSprite.anchorPoint = ccp(0.5f, 0.5f);
        scoreSprite.position = ccp(TOP_SPRITE_PADDING, topOffset - TOP_SPRITE_PADDING);        
        scoreSprite.zOrder = HUD_CCNODES_Z_ORDER;
        [parentSpriteBatchNode addChild:scoreSprite];
    }
    scoreSprite.visible = YES;
    
    [self updateScoreLabel];
    scoreLabel.visible = YES;

    if (!coinsSprite) {
        coinsSprite = [[CCSprite alloc] initWithSpriteFrameName:@"coin1.png"];
        coinsSprite.scale = [UIScreen mainScreen].scale * 2;
        coinsSprite.anchorPoint = ccp(0.5, 0.5);
        coinsSprite.position = ccp(bounds.size.width - TOP_SPRITE_PADDING, topOffset - TOP_SPRITE_PADDING);
        coinsSprite.zOrder = HUD_CCNODES_Z_ORDER;
        [parentSpriteBatchNode addChild:coinsSprite];
    }
    coinsSprite.visible = YES;

    [self updateCoinsLabel];
    coinsLabel.visible = YES;

    if (!pauseButton) {
        pauseButton = [[MenuButton alloc] initWithFrame:CGRectMake(roundf(bounds.size.width * 0.5 - PAUSE_BUTTON_WIDTH * 0.5), bounds.origin.y, PAUSE_BUTTON_WIDTH, PAUSE_BUTTON_HEIGHT)];
        [pauseButton setImage:[UIImage imageNamed:@"pause"]];
        [pauseButton setHighlightedImage:[UIImage imageNamed:@"pause-h"]];
        [pauseButton addTarget:self action:@selector(pauseButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [parentView addSubview:pauseButton];
    }
    pauseButton.hidden = NO;

    if (!rageBackgroundView) {
        rageBackgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(16.0, CGRectGetMaxY(bounds) - RAGE_BAR_BOTTOM_PADDING, 288.0, 24.0)];
        rageBackgroundView.image = [UIImage imageNamed:@"progressBarBack"];
        rageBackgroundView.layer.contentsScale = [UIScreen mainScreen].scale * 2;
        rageBackgroundView.layer.magnificationFilter = kCAFilterNearest;
        [parentView addSubview:rageBackgroundView];
    }
    rageBackgroundView.hidden = NO;

    [self updateRageProgressView];
    rageProgressView.hidden = NO;
}

- (void)hide {

    scoreSprite.visible = NO;
    scoreLabel.visible = NO;
    coinsSprite.visible = NO;
    coinsLabel.visible = NO;
    pauseButton.hidden = YES;
    rageBackgroundView.hidden = YES;
    rageProgressView.hidden = YES;

}

- (void)pauseButtonPressed {

    [_delegate gameHUDPauseButtonWasPressed:self];
}

@end
