//
//  BombSpawner.m
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/26/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "BombSpawner.h"

#define SPEED 1.7f

@interface BombSpawner() {

    float progress;
    BOOL spawning;
    NSArray *animationFrames;    
}

@end


@implementation BombSpawner

- (id)init {

    self = [self initWithSpriteFrameName:@"progress1.png"];
    if (self) {
        self.anchorPoint = ccp(0.5, 0.5);
        self.scale = [UIScreen mainScreen].scale * 2;
        self.visible = NO;

        CCSpriteFrameCache *spriteFrameCache = [CCSpriteFrameCache sharedSpriteFrameCache];
        animationFrames = @[
        [spriteFrameCache spriteFrameByName:@"progress1.png"],
        [spriteFrameCache spriteFrameByName:@"progress2.png"],
        [spriteFrameCache spriteFrameByName:@"progress3.png"],
        [spriteFrameCache spriteFrameByName:@"progress4.png"],
        [spriteFrameCache spriteFrameByName:@"progress5.png"],
        [spriteFrameCache spriteFrameByName:@"progress6.png"],
        [spriteFrameCache spriteFrameByName:@"progress7.png"],
        [spriteFrameCache spriteFrameByName:@"progress8.png"],         
        ];
    }
    return self;
}

- (void)startSpawningAtPos:(CGPoint)pos {

    _pos = pos;
    spawning = YES;
    progress = 0;
}

- (void)cancelSpawning {

    spawning = NO;
}

- (void)calc:(ccTime)deltaTime {

    if (spawning) {
        progress += deltaTime * SPEED;

        if (progress >= 1) {
            spawning = NO;
            progress = 1;
            [_delegate bombSpawnerWantsBombToSpawn:self];
        }

        [self setDisplayFrame:animationFrames[(int)roundf(progress * ([animationFrames count] - 1))]];
    }
}

@end
