//
//  TeslaCoil.m
//  HMGGJ2013
//
//  Created by Loki on 1/27/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "TeslaCoil.h"

#define ANIMATION_SPEED 0.1f

@interface TeslaCoil() {
    
    NSArray *animationFrames;
    double elapsedTime;
    
    float ballTimer;
    float boltsTimer;
    
    float boltAnimTimer;
}

@end


@implementation TeslaCoil

- (id)init {
    
    self = [self initWithSpriteFrameName:@"lightning1.png"];
    if (self) {
        
        CCSpriteFrameCache *spriteFrameCache = [CCSpriteFrameCache sharedSpriteFrameCache];
        animationFrames = @[
        [spriteFrameCache spriteFrameByName:@"lightning1.png"],
        [spriteFrameCache spriteFrameByName:@"lightning2.png"],
        ];
    }
    return self;
}

- (void)calc:(ccTime)deltaTime {
    
    elapsedTime += deltaTime;
    
//    [self setDisplayFrame:animationFrames[(int)roundf(elapsedTime / ANIMATION_SPEED) % [animationFrames count]]];
}

- (void)electrify {
    
}


@end