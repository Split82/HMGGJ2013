//
//  BombExplosion.m
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/27/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "BombExplosion.h"

#define ANIMATION_SPEED 0.05f

@interface BombExplosion() {

    NSArray *animationFrames;
    double elapsedTime;
}

@end


@implementation BombExplosion

- (id)init {

    self = [self initWithSpriteFrameName:@"exp1.png"];
    if (self) {

        CCSpriteFrameCache *spriteFrameCache = [CCSpriteFrameCache sharedSpriteFrameCache];
        animationFrames = @[
        [spriteFrameCache spriteFrameByName:@"exp1.png"],
        [spriteFrameCache spriteFrameByName:@"exp2.png"],
        [spriteFrameCache spriteFrameByName:@"exp3.png"],
        [spriteFrameCache spriteFrameByName:@"exp4.png"],
        [spriteFrameCache spriteFrameByName:@"exp5.png"],
        [spriteFrameCache spriteFrameByName:@"exp6.png"],
        [spriteFrameCache spriteFrameByName:@"exp7.png"],
        [spriteFrameCache spriteFrameByName:@"exp8.png"],
        [spriteFrameCache spriteFrameByName:@"exp9.png"],
        [spriteFrameCache spriteFrameByName:@"exp10.png"],             
        ];
    }
    return self;
}

- (void)calc:(ccTime)deltaTime {

    elapsedTime += deltaTime;

    if (roundf(elapsedTime / ANIMATION_SPEED) >= [animationFrames count]) {
        [_delegate bombExplosionDidFinish:self];
    }
    else {
        [self setDisplayFrame:animationFrames[(int)roundf(elapsedTime / ANIMATION_SPEED) % [animationFrames count]]];
    }
}

@end