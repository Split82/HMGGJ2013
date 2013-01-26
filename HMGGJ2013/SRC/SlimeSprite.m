//
//  SlimeSprite.m
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/26/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "SlimeSprite.h"

#define ENERGY_CHANGE_SPEED 0.2

@interface SlimeSprite() {

    CGFloat maxHeight;
    CGFloat destinationEnergy;
    CGFloat actualEnergy;
}

@end


@implementation SlimeSprite

- (id)initWithWidth:(CGFloat)width maxHeight:(CGFloat)initMaxHeight {

    self = [self initWithSpriteFrameName:@"tankWater.png"];
    if (self) {
        maxHeight = initMaxHeight;

        // Slime
        self.scaleX = width / self.contentSize.width;
        self.scaleY = maxHeight/ self.contentSize.height;

        destinationEnergy = 1;
        actualEnergy = 1;
    }
    return self;
}

- (void)setEnergy:(CGFloat)energy {

    destinationEnergy = energy;
}

- (void)calc:(ccTime)deltaTime {

    if (destinationEnergy < actualEnergy) {

        actualEnergy -= deltaTime * ENERGY_CHANGE_SPEED;
        if (destinationEnergy > actualEnergy) {
            actualEnergy = destinationEnergy;
        }

        self.scaleY = actualEnergy * maxHeight/ self.contentSize.height;
    }
    else if (destinationEnergy > actualEnergy) {

        actualEnergy += deltaTime * ENERGY_CHANGE_SPEED;
        if (destinationEnergy < actualEnergy) {
            actualEnergy = destinationEnergy;
        }

        self.scaleY = actualEnergy * maxHeight/ self.contentSize.height;        
    }
}

@end
