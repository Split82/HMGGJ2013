//
//  MainGameScene.m
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/25/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "MainGameScene.h"
#import "TextureNameDefinitions.h"

#define PIXEL_ART_SPRITE_SCALE 4

#define TOP_HEIGHT 80

@interface MainGameScene() {

    CCSpriteBatchNode *mainSpriteBatch;
    NSMutableArray *tapEnemies;
    NSMutableArray *swipeEnemies;
    NSMutableArray *coins;

    BOOL sceneInitWasPerformed;
}

@end


@implementation MainGameScene

- (void)onEnter {

    [super onEnter];

    [self initScene];
}

- (void)initScene {

    if (sceneInitWasPerformed) {
        return;
    }

    sceneInitWasPerformed = YES;

    // Load texture atlas
    CCSpriteFrameCache *frameCache = [CCSpriteFrameCache sharedSpriteFrameCache];
    [frameCache addSpriteFramesWithFile:kGameObjectsSpriteFramesFileName];

    CCSpriteFrame *placeholderSpriteFrame = [frameCache spriteFrameByName:kPlaceholderTextureFrameName];

    // Batch
    mainSpriteBatch = [[CCSpriteBatchNode alloc] initWithFile:placeholderSpriteFrame.textureFilename capacity:100];
    [mainSpriteBatch.texture setAliasTexParameters];
    [self addChild:mainSpriteBatch];

    CGSize size;

    // Background
    CCSprite *backgroundSprite = [[CCSprite alloc] initWithSpriteFrameName:kPlaceholderTextureFrameName];
    backgroundSprite.anchorPoint = ccp(0, 1);
    backgroundSprite.position = ccp(0, [CCDirector sharedDirector].winSize.height);
    size = backgroundSprite.contentSize;
    backgroundSprite.scaleX = [CCDirector sharedDirector].winSize.width / backgroundSprite.contentSize.width;
    backgroundSprite.scaleY = TOP_HEIGHT / backgroundSprite.contentSize.height;
    [mainSpriteBatch addChild:backgroundSprite];

    // Foreground
    CCSprite *foregroundSprite = [[CCSprite alloc] initWithSpriteFrameName:kPlaceholderTextureFrameName];
    foregroundSprite.anchorPoint = ccp(0, 0);
    foregroundSprite.position = ccp(0, 0);
    foregroundSprite.scale = PIXEL_ART_SPRITE_SCALE;
    [mainSpriteBatch addChild:foregroundSprite];

    [self scheduleUpdate];
}

- (void)update:(ccTime)deltaTime {

}

@end