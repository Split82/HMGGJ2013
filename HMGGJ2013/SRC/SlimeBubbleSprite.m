//
//  SlimeBubbleSprite.m
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/26/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "SlimeBubbleSprite.h"

#define SPEED_Y 30
#define SPEED_Y_RANDOM 10
#define FLOW_X 10
#define FLOW_X_RANDOM 5
#define FLOW_SPEED 2
#define FLOW_SPEED_RANDOM 1

@interface SlimeBubbleSprite() {

    CGFloat startX;
    CGFloat flowX;
    CGFloat speedY;
    float elaspedTime;
    float flowOffset;
    float flowSpeed;
}

@end


@implementation SlimeBubbleSprite

- (id)initWithPos:(CGPoint)pos  {

    if (rand() %2 == 0) {
        self = [self initWithSpriteFrameName:@"bubble1.png"];
    }
    else {
        self = [self initWithSpriteFrameName:@"buble2.png"];
    }

    if (self) {

        self.scale = [UIScreen mainScreen].scale * 2;

        startX = pos.x;
        self.position = pos;

        flowX = FLOW_X + FLOW_X_RANDOM * rand() / (float)RAND_MAX;

        speedY = SPEED_Y + SPEED_Y_RANDOM * rand() / (float)RAND_MAX;

        flowOffset = rand() / (float)RAND_MAX;

        flowSpeed = FLOW_SPEED + FLOW_SPEED_RANDOM * rand() / (float)RAND_MAX;
    }
    return self;
}

- (void)calc:(ccTime)deltaTime {

    CGPoint pos = self.position;
    pos.x = startX + sinf((elaspedTime + flowOffset) * flowSpeed) * flowX;
    pos.y += speedY * deltaTime;
    self.position = pos;

    elaspedTime += deltaTime;
}

@end
