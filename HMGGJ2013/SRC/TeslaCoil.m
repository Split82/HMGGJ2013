//
//  TeslaCoil.m
//  HMGGJ2013
//
//  Created by Loki on 1/27/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "TeslaCoil.h"

#define ANIMATION_SPEED 0.1f

#define BOLT_ANIM_TIME_INTERVAL 1.0f

@interface TeslaCoil() {
    
    NSArray *animationFrames;
    double elapsedTime;
    
    float ballTimer;
    float boltsTimer;
    
    float boltAnimTimer;
    
    CCSprite *ballSprite;
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
        [spriteFrameCache spriteFrameByName:@"lightning2.png"],
        ];
        
        /*
        ballSprite = [[CCSprite alloc] initWithSpriteFrame:animationFrames[2]];
        ballSprite.anchorPoint = ccp(0.5, 0.5);
        ballSprite.position = ccp(0, -10);
        ballSprite.visible = NO;
        [self addChild:ballSprite];
        */
        
    }
    return self;
}

- (void)calc:(ccTime)deltaTime {
    
    elapsedTime += deltaTime;
    
    
    // bolts are visible
    if (boltAnimTimer < BOLT_ANIM_TIME_INTERVAL) {
        
        
        boltAnimTimer += deltaTime;
    }
    
//    [self setDisplayFrame:animationFrames[(int)roundf(elapsedTime / ANIMATION_SPEED) % [animationFrames count]]];
}

- (void)electrify {
    
}


@end