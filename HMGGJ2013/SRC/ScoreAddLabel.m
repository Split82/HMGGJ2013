//
//  ScoreAddLabel.m
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/27/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "ScoreAddLabel.h"

#define SPEED_Y 70
#define LIFE_TIME 1.5
#define BLINKING_SPEED 0.2

@interface ScoreAddLabel() {

    CGPoint startPos;
    float elapsedTime;
}

@end


@implementation ScoreAddLabel

- (id)initWithText:(NSString*)text pos:(CGPoint)pos type:(ScoreAddLabelType)type {

    self = [self initWithString:text fntFile:@"PixelFont.fnt"];

    if (self) {
        _type = type;
        startPos = pos;
    }
    return self;
}

- (void)calc:(ccTime)deltaTime {

    if (_type == ScoreAddLabelTypeRising) {
        self.position = ccpAdd(self.position, ccp(0, SPEED_Y * deltaTime));
    }
    else if (_type == ScoreAddLabelTypeBlinking) {
        self.visible = ((int)round(elapsedTime / BLINKING_SPEED) % 2) == 0;
    }

    elapsedTime += deltaTime;

    if (elapsedTime > LIFE_TIME) {

        [_delegate scoreAddLabelDidFinish:self];
    }
}

@end
