//
//  GestureRecognizer.m
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/25/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "GestureRecognizer.h"

#define LONG_PRESS_START_DELAY 0.3
#define MAX_TAP_TIME 0.5
#define MIN_SWIPE_DISTANCE 30

typedef enum {

    GestureRecognizerStateAllPossible,
    GestureRecognizerStateRecognizingSwipe,
    GestureRecognizerStateRecognizingLongPress,
    GestureRecognizerStateNothingPossible,
} GestureRecognizerState;

@interface GestureRecognizer() {

    CGPoint startPos;
    CGPoint lastPos;
    float distanceTravelled;
    NSTimeInterval touchStartTime;
    
    NSTimeInterval elapsedTime;

    BOOL movedToFar; // Too far fow tap or long press
    BOOL fingerIsDown;

    CGPoint swipeStartVector;

    GestureRecognizerState state;
}

@end

@implementation GestureRecognizer

@synthesize lastPos, startPos;

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {

    fingerIsDown = YES;

    state = GestureRecognizerStateAllPossible;

    distanceTravelled = 0;

    CCDirector *director = [CCDirector sharedDirector];
    CGPoint pos = [director convertToGL:[touch locationInView:director.view]];

    startPos = pos;
    lastPos = pos;
    touchStartTime = elapsedTime;

    return YES;
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event {

    CCDirector *director = [CCDirector sharedDirector];
    CGPoint pos = [director convertToGL:[touch locationInView:director.view]];

    distanceTravelled += sqrtf(powf(pos.x - lastPos.x, 2) + powf(pos.y - lastPos.y, 2));

    if ((state == GestureRecognizerStateAllPossible || state == GestureRecognizerStateRecognizingLongPress) && distanceTravelled > MIN_SWIPE_DISTANCE) {

        if (state == GestureRecognizerStateRecognizingLongPress) {
            [_delegate longPressEnded];
        }

        state = GestureRecognizerStateRecognizingSwipe;
        swipeStartVector = ccpSub(pos, startPos);
        [_delegate swipeStarted:startPos];
    }
    else if (state == GestureRecognizerStateRecognizingSwipe) {

        if (fabsf(ccpAngle(swipeStartVector, ccpSub(pos, lastPos))) > M_PI_4) {
            state = GestureRecognizerStateNothingPossible;
            [_delegate swipeEnded:pos];
        }
        else {
            [_delegate swipeMoved:pos];
        }
    }

    lastPos = pos;
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {

    CCDirector *director = [CCDirector sharedDirector];
    CGPoint pos = [director convertToGL:[touch locationInView:director.view]];

    fingerIsDown = NO;

    if (state == GestureRecognizerStateAllPossible && elapsedTime - touchStartTime < MAX_TAP_TIME) {
        [_delegate tapRecognized:startPos];
    }
    else if (state == GestureRecognizerStateRecognizingLongPress && elapsedTime - touchStartTime < MAX_TAP_TIME) {

        [_delegate longPressEnded];
        [_delegate tapRecognized:startPos];
    }
    else if (state == GestureRecognizerStateRecognizingLongPress) {
        [_delegate longPressEnded];
    }
    else if (state == GestureRecognizerStateRecognizingSwipe) {
        [_delegate swipeEnded:pos];
    }
}

- (void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event {


    fingerIsDown = NO;

    if (state == GestureRecognizerStateRecognizingLongPress) {
        [_delegate longPressEnded];
    }
    else if (state == GestureRecognizerStateRecognizingSwipe) {
        [_delegate swipeCancelled];
    }
}

- (void)update:(ccTime)deltaTime {

    elapsedTime += deltaTime;

    if (fingerIsDown) {

        if (state == GestureRecognizerStateAllPossible && elapsedTime - touchStartTime > LONG_PRESS_START_DELAY && !movedToFar) {
            state = GestureRecognizerStateRecognizingLongPress;
            [_delegate longPressStarted:startPos];
        }
    }
}

@end
