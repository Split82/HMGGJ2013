//
//  BombSpawner.m
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/26/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "BombSpawner.h"

#define SPEED 1.7f
#define END_ANIMATION_TIME_INTERVAL 0.3
#define END_ANIMATION_ROTATION 30
#define END_ANIMATION_SCALE 0

@interface BombSpawner() {

    float progress;
    BOOL spawning;
    NSArray *animationFrames;

    float defaultScale;
    float endAnimationCountDown;
}

@end


@implementation BombSpawner

@synthesize spawning;

- (id)init {

    self = [self initWithSpriteFrameName:@"progress1.png"];
    if (self) {
        self.anchorPoint = ccp(0.5, 0.5);
        self.scale = [UIScreen mainScreen].scale * 2;
        defaultScale = self.scale;
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
    self.position = pos;

    self.visible = YES;

    self.rotation = 0;
    self.scale = defaultScale;
}

- (void)cancelSpawning {

    if (spawning) {
        spawning = NO;

        self.visible = NO;
    }
}

- (void)startEndAnimation {

    spawning = NO;
    progress = 1.0f;
    endAnimationCountDown = END_ANIMATION_TIME_INTERVAL;
}

- (void)calc:(ccTime)deltaTime {

    if (spawning) {
        progress += deltaTime * SPEED;

        if (progress >= 1) {
            [_delegate bombSpawnerWantsBombToSpawn:self];
        }

        [self setDisplayFrame:animationFrames[(int)roundf(progress * ([animationFrames count] - 1))]];
    }
    else if (endAnimationCountDown > 0) {

        self.rotation = (1 - endAnimationCountDown / END_ANIMATION_TIME_INTERVAL) * END_ANIMATION_ROTATION;
        self.scale = defaultScale + (END_ANIMATION_SCALE - defaultScale) * (1 - endAnimationCountDown / END_ANIMATION_TIME_INTERVAL);
        endAnimationCountDown -= deltaTime;

        if (endAnimationCountDown < 0) {
            self.visible = NO;
        }
    }
}

@end
