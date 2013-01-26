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
}

@end


@implementation BombSpawner

- (id)init {

    self = [self initWithSpriteFrameName:@"coin1.png"];
    if (self) {
        self.anchorPoint = ccp(0.5, 0.5);
        self.scale = [UIScreen mainScreen].scale * 2;
        self.visible = NO;
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
            [_delegate bombSpawnerWantsBombToSpawn:self];
        }
    }
}

@end
