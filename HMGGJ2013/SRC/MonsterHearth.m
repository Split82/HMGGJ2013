//
//  MonsterHearth.m
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/27/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "MonsterHearth.h"

#define ANIMATION_SPEED 0.12f

@interface MonsterHearth() {

    NSArray *animationFrames;
    int animationIndexes[6];
    double elapsedTime;
}

@end


@implementation MonsterHearth

- (id)init {

    self = [self initWithSpriteFrameName:@"heart1.png"];
    if (self) {

        self.scale = [UIScreen mainScreen].scale * 2;

        CCSpriteFrameCache *spriteFrameCache = [CCSpriteFrameCache sharedSpriteFrameCache];
        animationFrames = @[
        [spriteFrameCache spriteFrameByName:@"heart1.png"],
        [spriteFrameCache spriteFrameByName:@"heart2.png"],
        [spriteFrameCache spriteFrameByName:@"heart3.png"],
        [spriteFrameCache spriteFrameByName:@"heart4.png"],
        ];

        animationIndexes[0] = 0;
        animationIndexes[1] = 1;
        animationIndexes[2] = 2;
        animationIndexes[3] = 3;
        animationIndexes[4] = 2;
        animationIndexes[5] = 1;
        
        _infarkt = 0;
    }
    return self;
}

- (void)calc:(ccTime)deltaTime {

    elapsedTime += deltaTime;
    float h = 0.11 * _infarkt;
    [self setDisplayFrame:animationFrames[animationIndexes[((int)round(elapsedTime / (ANIMATION_SPEED - h))) % 6]]];
}

@end
