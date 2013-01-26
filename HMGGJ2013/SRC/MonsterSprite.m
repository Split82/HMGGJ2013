//
//  MonsterSprite.m
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/26/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "MonsterSprite.h"

#define ANIMATION_SPEED 0.07f

@interface MonsterSprite() {

    NSArray *animationFrames;
    int animationIndexes[8];

    float nextBlinkCountDown;
    BOOL blinking;
    float blinkTimer;
}

@end


@implementation MonsterSprite

- (id)init {

    self = [self initWithSpriteFrameName:@"monster1.png"];
    if (self) {

        self.scale = [UIScreen mainScreen].scale * 2;

        CCSpriteFrameCache *spriteFrameCache = [CCSpriteFrameCache sharedSpriteFrameCache];
        animationFrames = @[
        [spriteFrameCache spriteFrameByName:@"monster1.png"],
        [spriteFrameCache spriteFrameByName:@"monster2.png"],
        [spriteFrameCache spriteFrameByName:@"monster3.png"],
        [spriteFrameCache spriteFrameByName:@"monster4.png"],
        [spriteFrameCache spriteFrameByName:@"monster5.png"],
        ];

        animationIndexes[0] = 0;
        animationIndexes[1] = 1;
        animationIndexes[2] = 2;
        animationIndexes[3] = 3;
        animationIndexes[4] = 4;
        animationIndexes[5] = 3;
        animationIndexes[6] = 2;
        animationIndexes[7] = 1;

        nextBlinkCountDown = 1.0f;
    }
    return self;
}

- (void)planNewBlinking {

    nextBlinkCountDown = (rand() / (float)RAND_MAX) * 5;
}

- (void)startBlinking {

    blinking = YES;
    blinkTimer = 0;
}

- (void)calc:(ccTime)deltaTime {

    if (!blinking) {
        nextBlinkCountDown -= deltaTime;
    }

    if (!blinking && nextBlinkCountDown <= 0) {
        [self startBlinking];
    }

    if (blinking) {
        [self setDisplayFrame:animationFrames[animationIndexes[((int)round(blinkTimer / ANIMATION_SPEED)) % 8]]];
        blinkTimer += deltaTime;

        if (blinkTimer / ANIMATION_SPEED > 7) {
            blinking = NO;
            [self setDisplayFrame:animationFrames[0]];
            [self planNewBlinking];
        }
    }
}

@end
