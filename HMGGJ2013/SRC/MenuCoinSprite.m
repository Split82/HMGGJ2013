//
//  MenuCoinSprite.m
//  HMGGJ2013
//
//  Created by Lukáš Foldýna on 26.01.13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "MenuCoinSprite.h"

#define ANIMATION_SPEED 0.08
#define NUMBER_OF_ANIMATION_FRAMES 16

@interface MenuCoinSprite() {

    float elapsedTime;

    NSArray *animationFrames;
    int animationIndexes[NUMBER_OF_ANIMATION_FRAMES];
    int animationOffset;
}

@end

@implementation MenuCoinSprite

- (id)init {

    self = [self initWithSpriteFrameName:@"coin1.png"];
    if (self) {

        self.scale = [UIScreen mainScreen].scale * 2;        

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

    [self setDisplayFrame:animationFrames[animationIndexes[(animationOffset + (int)round(elapsedTime / ANIMATION_SPEED)) % NUMBER_OF_ANIMATION_FRAMES]]];
    
    elapsedTime += deltaTime;
}

@end
