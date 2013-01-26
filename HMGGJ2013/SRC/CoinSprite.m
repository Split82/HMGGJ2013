//
//  CoinSprite.m
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/25/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "CoinSprite.h"
#import "GameDataNameDefinitions.h"

#define GRAVITY -500.0f
#define INITIAL_VEL_Y 350.0f
#define FRICTION 0.9f
#define ANIMATION_SPEED 0.2
#define BLINKING_SPEED 0.15
#define START_BLINKING_TIME 6.0
#define LIFE_TIME 8.0

@interface CoinSprite() {
    
    float lifeTime;
    float groundY;
    CGPoint velocity;

    NSArray *animationFrames;
    int animationIndexes[6];
}

@end


@implementation CoinSprite

- (id)initWithStartPos:(CGPoint)startPos {

    self = [self initWithSpriteFrameName:@"coin1.png"];
    if (self) {
        self.anchorPoint = ccp(0.5, 0);
        self.position = startPos;
        self.scale = 2;
        groundY = startPos.y;
        velocity = ccp(25 - 50 * (rand() / (float)RAND_MAX), INITIAL_VEL_Y);

        CCSpriteFrameCache *spriteFrameCache = [CCSpriteFrameCache sharedSpriteFrameCache];
        animationFrames = @[
            [spriteFrameCache spriteFrameByName:@"coin1.png"],
            [spriteFrameCache spriteFrameByName:@"coin2.png"],
            [spriteFrameCache spriteFrameByName:@"coin3.png"],
            [spriteFrameCache spriteFrameByName:@"coin4.png"],
        ];

        animationIndexes[0] = 0;
        animationIndexes[1] = 1;
        animationIndexes[2] = 2;
        animationIndexes[3] = 3;
        animationIndexes[4] = 2;
        animationIndexes[5] = 1;
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

    [self setDisplayFrame:animationFrames[animationIndexes[(int)round(lifeTime / ANIMATION_SPEED) % 6]]];

    if (lifeTime > START_BLINKING_TIME) {
        self.visible = ((int)round(lifeTime / BLINKING_SPEED) % 2) == 0;
    }

    if (lifeTime > LIFE_TIME) {
        [_delegate performSelector:@selector(coinDidDie:) withObject:self afterDelay:0.0];
    }

    lifeTime += deltaTime;
}

@end
