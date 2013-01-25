//
//  CoinSprite.m
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/25/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "CoinSprite.h"
#import "GameDataNameDefinitions.h"

#define GRAVITY -500.0f
#define INITIAL_VEL_Y 350.0f
#define FRICTION 0.9f

@interface CoinSprite() {
    
    float lifeTime;
    float groundY;
    CGPoint velocity;
}

@end


@implementation CoinSprite

- (id)initWithStartPos:(CGPoint)startPos {

    self = [self initWithSpriteFrameName:kPlaceholderTextureFrameName];
    if (self) {
        self.anchorPoint = ccp(0.5, 0);
        self.position = startPos;
        groundY = startPos.y;
        velocity = ccp(25 - 50 * (rand() / (float)RAND_MAX), INITIAL_VEL_Y);
    }
    return self;
}

- (void)update:(ccTime)deltaTime {

    velocity = ccpMult(velocity, FRICTION);
    velocity = ccpAdd(velocity, ccp(0, GRAVITY * deltaTime));
    self.position = ccpAdd(self.position, ccpMult(velocity, deltaTime));
    
    if (position_.y < groundY) {

        self.position = ccp(position_.x, groundY);
        velocity = ccp(velocity.x, - velocity.y);
    }

    lifeTime += deltaTime;
}

@end
