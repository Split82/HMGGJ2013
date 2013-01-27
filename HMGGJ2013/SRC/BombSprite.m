//
//  BombSprite.m
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/26/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "BombSprite.h"

#define START_BLINKING_TIME 0.0f
#define LIFE_TIME 2.0f
#define FRICTION 0.97f
#define GRAVITY -2000.0f
#define BLINKING_SPEED 0.12f
#define BOUNCE_COEF 0.8f
#define GROW_SPEED 0.1

@interface BombSprite() {

    float groundY;
    CGPoint velocity;
    NSTimeInterval elapsedTime;
    NSArray *animationFrames;
    BOOL scaleChange;
    float blinkingOffset;
}

@end

@implementation BombSprite

- (id)initWithStartPos:(CGPoint)startPos groundY:(CGFloat)initGroundY {

    self = [self initWithSpriteFrameName:@"BombNormal.png"];
    if (self) {
        self.anchorPoint = ccp(0.5, 0);
        self.position = startPos;
        self.scale = [UIScreen mainScreen].scale * 2;
        groundY = initGroundY;
        blinkingOffset = rand() / (float)RAND_MAX;

        CCSpriteFrameCache *spriteFrameCache = [CCSpriteFrameCache sharedSpriteFrameCache];
        animationFrames = @[
        [spriteFrameCache spriteFrameByName:@"BombNormal.png"],
        [spriteFrameCache spriteFrameByName:@"BombDetonate.png"]
        ];
    }
    return self;
}

- (void)calc:(ccTime)deltaTime {

    velocity = ccpMult(velocity, FRICTION);
    velocity = ccpAdd(velocity, ccp(0, GRAVITY * deltaTime));
    self.position = ccpAdd(self.position, ccpMult(velocity, deltaTime));

    if (position_.y < groundY) {

        self.position = ccp(position_.x, groundY);
        velocity = ccp(velocity.x, - velocity.y * BOUNCE_COEF);
    }

    if (elapsedTime > START_BLINKING_TIME) {
        
        [self setDisplayFrame:animationFrames[(int)round(blinkingOffset + elapsedTime / BLINKING_SPEED) % 2]];
        
        [self setScale:self.scale + GROW_SPEED * deltaTime];
        scaleChange = !scaleChange;
    }

    if (elapsedTime > LIFE_TIME) {
        [_delegate bombDidDie:self];
    }

    elapsedTime += deltaTime;
}

@end
