//
//  FlyingSkullSprite.m
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/27/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "FlyingSkullSprite.h"

#define SPEED_Y 70
#define LIFE_TIME 1.5

@interface FlyingSkullSprite() {

    CGPoint startPos;
    float elapsedTime;
}

@end


@implementation FlyingSkullSprite

- (id)initWithPos:(CGPoint)pos; {

    self = [self initWithSpriteFrameName:@"skull.png"];

    if (self) {
        startPos = pos;
        self.position = pos;
    }
    return self;
}

- (void)calc:(ccTime)deltaTime {

    self.position = ccpAdd(self.position, ccp(0, SPEED_Y * deltaTime));

    elapsedTime += deltaTime;

    if (elapsedTime > LIFE_TIME) {

        [_delegate flyingSkullSpriteDidFinish:self];
    }
}

@end