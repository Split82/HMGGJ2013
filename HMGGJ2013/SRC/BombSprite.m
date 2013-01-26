//
//  BombSprite.m
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/26/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "BombSprite.h"

#define START_BLINKING_TIME 4.5f
#define LIFE_TIME 6.0f
#define FRICTION 0.99f
#define GRAVITY -1000.0f
#define BLINKING_SPEED 0.12f
#define BOUNCE_COEF 0.5f

@interface BombSprite() {

    float groundY;
    CGPoint velocity;
    NSTimeInterval lifeTime;
}

@end

@implementation BombSprite

- (id)initWithStartPos:(CGPoint)startPos groundY:(CGFloat)initGroundY {

    self = [self initWithSpriteFrameName:@"coin1.png"];
    if (self) {
        self.anchorPoint = ccp(0.5, 0);
        self.position = startPos;
        self.scale = [UIScreen mainScreen].scale * 2;
        groundY = initGroundY;
    }
    return self;
}

- (void)calc:(ccTime)deltaTime {

    velocity = ccpMult(velocity, FRICTION);
    velocity = ccpAdd(velocity, ccp(0, GRAVITY * deltaTime));
    self.position = ccpAdd(self.position, ccpMult(velocity, deltaTime));

    if (position_.y < groundY) {

        self.position = ccp(position_.x, groundY);
        velocity = ccp(velocity.x, - velocity.y * BOUNCE_COEF);
    }

    if (lifeTime > START_BLINKING_TIME) {
        self.visible = ((int)round(lifeTime / BLINKING_SPEED) % 2) == 0;
    }

    if (lifeTime > LIFE_TIME) {
        [_delegate bombDidDie:self];
    }

    lifeTime += deltaTime;
}

@end