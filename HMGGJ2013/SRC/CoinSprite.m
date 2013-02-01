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

#define NUMBER_OF_ANIMATION_FRAMES 16

@interface CoinSprite() {

    CGRect spaceBounds;
    BOOL stable;

    float elapsedTime;
    float groundY;
    CGPoint velocity;

    NSArray *animationFrames;
    int animationIndexes[NUMBER_OF_ANIMATION_FRAMES];
    int animationOffset;
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

        animationOffset = rand() % NUMBER_OF_ANIMATION_FRAMES;
        
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
        [spriteFrameCache spriteFrameByName:@"coin9.png"],        
        ];

        animationIndexes[0] = 0;
        animationIndexes[1] = 1;
        animationIndexes[2] = 2;
        animationIndexes[3] = 3;
        animationIndexes[4] = 8;
        animationIndexes[5] = 7;
        animationIndexes[6] = 6;
        animationIndexes[7] = 5;
        animationIndexes[8] = 4;
        animationIndexes[9] = 5;
        animationIndexes[10] = 6;
        animationIndexes[11] = 7;
        animationIndexes[12] = 8;
        animationIndexes[13] = 3;
        animationIndexes[14] = 2;
        animationIndexes[15] = 1;
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

    [self setDisplayFrame:animationFrames[animationIndexes[(animationOffset + (int)round(elapsedTime / ANIMATION_SPEED)) % NUMBER_OF_ANIMATION_FRAMES]]];

    if (elapsedTime > START_BLINKING_TIME) {
        self.visible = ((int)round(elapsedTime / BLINKING_SPEED) % 2) == 0;
    }

    if (elapsedTime > LIFE_TIME) {
        [_delegate coinDidDie:self];
    }

    elapsedTime += deltaTime;
}

@end
