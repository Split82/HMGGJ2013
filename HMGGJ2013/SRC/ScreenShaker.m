//
//  ScreenShaker.m
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/26/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "ScreenShaker.h"

#define SHAKE_SIZE 10

@interface ScreenShaker() {

    float skaheTimeRemaining;
}

@end


@implementation ScreenShaker

- (void)shake {

    skaheTimeRemaining = 0.5f;
}

- (void)calc:(ccTime)deltaTime {

    if (skaheTimeRemaining > 0) {
        skaheTimeRemaining -= deltaTime;
        _offset = ccp(SHAKE_SIZE * skaheTimeRemaining * rand() / (float)RAND_MAX, SHAKE_SIZE * skaheTimeRemaining * rand() / (float)RAND_MAX);
    }
    else {
        _offset = ccp(0, 0);
    }
}



@end
