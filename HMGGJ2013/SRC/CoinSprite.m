//
//  CoinSprite.m
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/25/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "CoinSprite.h"
#import "GameDataNameDefinitions.h"

#define GRAVITY -2000.0f
#define INITIAL_VEL_Y 800.0f
#define FRICTION 0.91f
#define ANIMATION_SPEED 0.08
#define BLINKING_SPEED 0.12
#define START_BLINKING_TIME 4.5
#define LIFE_TIME 6.0

@interface CoinSprite() {
    
    float lifeTime;
    float groundY;
    CGPoint velocity;

    NSArray *animationFrames;
    int animationIndexes[14];
}

@end


@implementation CoinSprite

- (id)initWithStartPos:(CGPoint)startPos {

    self = [self initWithSpriteFrameName:@"coin1.png"];
    if (self) {
        self.anchorPoint = ccp(0.5, 0);
        self.position = startPos;
        self.scale = [UIScreen mainScreen].scale * 2;
        groundY = startPos.y;
        velocity = ccp(25 - 50 * (rand() / (float)RAND_MAX), INITIAL_VEL_Y);

        CCSpriteFrameCache *spriteFrameCache = [CCSpriteFrameCache sharedSpriteFrameCache];
        animationFrames = @[
        [spriteFrameCache spriteFrameByName:@"coin1.png"],
        [spriteFrameCache spriteFrameByName:@"coin2.png"],
        [spriteFrameCache spriteFrameByName:@"coin3.png"],
        [spriteFrameCache spriteFrameByName:@"coin4.png"],
        [spriteFrameCache spriteFrameByName:@"coin5.png"],
        [spriteFrameCache spriteFrameByName:@"coin6.png"],
        [spriteFrameCache spriteFrameByName:@"coin7.png"],
        [spriteFrameCache spriteFrameByName:@"coin8.png"],
        ];

        animationIndexes[0] = 0;
        animationIndexes[1] = 1;
        animationIndexes[2] = 2;
        animationIndexes[3] = 3;
        animationIndexes[4] = 7;
        animationIndexes[5] = 6;
        animationIndexes[6] = 5;
        animationIndexes[7] = 4;
        animationIndexes[8] = 5;
        animationIndexes[9] = 6;
        animationIndexes[10] = 7;
        animationIndexes[11] = 3;
        animationIndexes[12] = 2;
        animationIndexes[13] = 1;
    }
    return self;
}

- (void)update:(ccTime)deltaTime {

    velocity = ccpMult(velocity, FRICTION);
    velocity = ccpAdd(velocity, ccp(0, GRAVITY * deltaTime));
    self.position = ccpAdd(self.position, ccpMult(velocity, deltaTime));
    
    if (position_.y < groundY) {

        self.position = ccp(position_.x, groundY);
        velocity = ccp(velocity.x, - velocity.y);
    }

    [self setDisplayFrame:animationFrames[animationIndexes[(int)round(lifeTime / ANIMATION_SPEED) % 14]]];

    if (lifeTime > START_BLINKING_TIME) {
        self.visible = ((int)round(lifeTime / BLINKING_SPEED) % 2) == 0;
    }

    if (lifeTime > LIFE_TIME) {
        [_delegate coinDidDie:self];
    }

    lifeTime += deltaTime;
}

@end
