//
//  MenuCoinSprite.m
//  HMGGJ2013
//
//  Created by Lukáš Foldýna on 26.01.13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "MenuCoinSprite.h"

#define ANIMATION_SPEED 0.08

@implementation MenuCoinSprite

- (void)calc:(ccTime)deltaTime {
    [self setDisplayFrame:animationFrames[animationIndexes[(animationOffset + (self.position.x > 200 ? 2 : 0) + (int)round(lifeTime / ANIMATION_SPEED)) % 14]]];
    
    lifeTime += deltaTime;
}

@end
