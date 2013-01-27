//
//  CoinSprite.m
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/25/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "CoinSprite.h"
#import "GameDataNameDefinitions.h"
#import "AudioManager.h"

#define GRAVITY -2000.0f
#define INITIAL_VEL_Y 800.0f
#define FRICTION 0.97f
#define ANIMATION_SPEED 0.08
#define BLINKING_SPEED 0.12
#define START_BLINKING_TIME 4.5
#define LIFE_TIME 6.0
#define BOUNCE_COEF 0.8f

@interface CoinSprite() {

    CGRect spaceBounds;
    BOOL stable;
}

@end


@implementation CoinSprite

- (id)initWithStartPos:(CGPoint)startPos spaceBounds:(CGRect)initSpaceBounds {

    self = [self initWithSpriteFrameName:@"coin1.png"];
    if (self) {
        
        self.anchorPoint = ccp(0.5, 0.5);
        self.position = startPos;
        self.scale = [UIScreen mainScreen].scale * 2;
        spaceBounds = initSpaceBounds;
        velocity = ccp(1000 - 2000 * (rand() / (float)RAND_MAX), INITIAL_VEL_Y);

        animationOffset = rand() % 14;
        
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

- (void)calc:(ccTime)deltaTime {

    if (!stable) {

        velocity = ccpMult(velocity, FRICTION);
        velocity = ccpAdd(velocity, ccp(0, GRAVITY * deltaTime));
        self.position = ccpAdd(self.position, ccpMult(velocity, deltaTime));
        
        if (self.position.x > CGRectGetMaxX(spaceBounds) - self.boundingBox.size.width * 0.5) {       
            CGPoint pos = self.position;
            pos.x = CGRectGetMaxX(spaceBounds) - self.boundingBox.size.width * 0.5;
            self.position = pos;
            velocity.x = -velocity.x;
            velocity = ccpMult(velocity, BOUNCE_COEF);

            // ccpLength(velocity)
            [[AudioManager sharedManager] coinHit];
        }

        if (self.position.x < CGRectGetMinX(spaceBounds) + self.boundingBox.size.width * 0.5) {
            CGPoint pos = self.position;
            pos.x = CGRectGetMinX(spaceBounds) + self.boundingBox.size.width * 0.5;
            self.position = pos;
            velocity.x = -velocity.x;
            velocity = ccpMult(velocity, BOUNCE_COEF);
            
            [[AudioManager sharedManager] coinHit];
        }

        if (self.position.y < CGRectGetMinY(spaceBounds) + self.boundingBox.size.height * 0.5) {

            if (ccpLengthSQ(velocity) < fabsf(GRAVITY)) {
                stable = YES;
            }
            
            CGPoint pos = self.position;
            pos.y = CGRectGetMinY(spaceBounds) + self.boundingBox.size.height * 0.5;
            self.position = pos;
            velocity.y = -velocity.y;
            velocity = ccpMult(velocity, BOUNCE_COEF);

            if (!stable) {
                [[AudioManager sharedManager] coinHit];
            }
        }
    }

    [self setDisplayFrame:animationFrames[animationIndexes[(animationOffset + (int)round(lifeTime / ANIMATION_SPEED)) % 14]]];

    if (lifeTime > START_BLINKING_TIME) {
        self.visible = ((int)round(lifeTime / BLINKING_SPEED) % 2) == 0;
    }

    if (lifeTime > LIFE_TIME) {
        [_delegate coinDidDie:self];
    }

    lifeTime += deltaTime;
}

@end
