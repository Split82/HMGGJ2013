//
//  MainGameScene.m
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/25/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "MainGameScene.h"

#import "TextureNameDefinitions.h"

@interface MainGameScene() {

    CCSpriteBatchNode *spriteBatch;
    CCSprite *testSprite;

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
    
    CCSpriteFrameCache *frameCache = [CCSpriteFrameCache sharedSpriteFrameCache];
    [frameCache addSpriteFramesWithFile:kGameObjectsSpriteFramesFileName];

    CCSpriteFrame *placeholderSpriteFrame = [frameCache spriteFrameByName:kPlaceholderTextureFrameName];

    spriteBatch = [[CCSpriteBatchNode alloc] initWithFile:placeholderSpriteFrame.textureFilename capacity:10];
    [self addChild:spriteBatch];

    testSprite = [CCSprite spriteWithSpriteFrame:placeholderSpriteFrame];
    testSprite.anchorPoint = ccp(0.5f, 0.5f);
    testSprite.position = ccp([CCDirector sharedDirector].winSize.width * 0.5f, [CCDirector sharedDirector].winSize.height * 0.5f);
    [spriteBatch addChild:testSprite];

    [self scheduleUpdate];
}

- (void)update:(ccTime)deltaTime {

    static double elapsedTime = 0;

    elapsedTime += deltaTime;

    CGPoint pos = testSprite.position;
    pos.x = sin(elapsedTime) * 100 + [CCDirector sharedDirector].winSize.width * 0.5f;
    testSprite.position = pos;
}

@end