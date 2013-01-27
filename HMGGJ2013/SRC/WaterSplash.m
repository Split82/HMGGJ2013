//
//  WaterSplash.m
//  HMGGJ2013
//
//  Created by Loki on 1/27/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "WaterSplash.h"

#define ANIMATION_SPEED 0.1f

@interface WaterSplash() {
    
    NSArray *animationFrames;
    double elapsedTime;
}

@end


@implementation WaterSplash

- (id)init {
    
    self = [self initWithSpriteFrameName:@"waterSplash1.png"];
    if (self) {
        
        CCSpriteFrameCache *spriteFrameCache = [CCSpriteFrameCache sharedSpriteFrameCache];
        animationFrames = @[
        [spriteFrameCache spriteFrameByName:@"waterSplash1.png"],
        [spriteFrameCache spriteFrameByName:@"waterSplash2.png"],
        [spriteFrameCache spriteFrameByName:@"waterSplash3.png"],
        [spriteFrameCache spriteFrameByName:@"waterSplash4.png"],
        ];
    }
    return self;
}

- (void)calc:(ccTime)deltaTime {
    
    elapsedTime += deltaTime;
    
    if (roundf(elapsedTime / ANIMATION_SPEED) >= [animationFrames count]) {
        [_delegate waterSplashDidFinish:self];
    }
    else {
        [self setDisplayFrame:animationFrames[(int)roundf(elapsedTime / ANIMATION_SPEED) % [animationFrames count]]];
    }
}

@end