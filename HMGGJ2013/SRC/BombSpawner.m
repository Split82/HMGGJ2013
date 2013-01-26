//
//  BombSpawner.m
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/26/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "BombSpawner.h"

@implementation BombSpawner

- (id)initWithPos:(CGPoint)pos {

    self = [self initWithSpriteFrameName:@"coin1.png"];
    if (self) {
        self.anchorPoint = ccp(0.5, 0.5);
        self.position = pos;
        self.scale = [UIScreen mainScreen].scale * 2;
    }
    return self;
}

@end
