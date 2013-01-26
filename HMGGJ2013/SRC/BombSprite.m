//
//  BombSprite.m
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/26/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "BombSprite.h"

#define START_BLINKING_TIME 2.0f
#define LIFE_TIME 3.0f
#define FRICTION 0.99f
#define GRAVITY -1000.0f
#define BLINKING_SPEED 0.12f
#define BOUNCE_COEF 0.5f

@interface BombSprite() {

    float groundY;
    CGPoint velocity;
    NSTimeInterval lifeTime;
    NSArray *animationFrames;
    BOOL scaleChange;
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

    if (lifeTime > START_BLINKING_TIME) {
        [self setDisplayFrame:animationFrames[(int)round(lifeTime / BLINKING_SPEED) % 2]];
        [self setScale:self.scale + (scaleChange ? 0.15 : -0.15)];
        scaleChange = !scaleChange;
    }

    if (lifeTime > LIFE_TIME) {
        [_delegate bombDidDie:self];
    }

    lifeTime += deltaTime;
}

@end
