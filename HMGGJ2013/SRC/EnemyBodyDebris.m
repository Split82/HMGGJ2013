//
//  BodyDebris.m
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/26/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "EnemyBodyDebris.h"

#define GRAVITY -2000.0f
#define FRICTION 0.97f
#define BOUNCE_COEF 0.8f
#define LIFE_TIME 3

#define START_BLOOD_EMISSION_RATE 30

@interface EnemyBodyDebris() {

    CGPoint velocity;
    CGRect spaceBounds;
    float elapsedTime;
    float lifeTime;
}

@end


@implementation EnemyBodyDebris

- (id)init:(EnemyType)enemyType velocity:(CGPoint)initVelocity spaceBounds:(CGRect)initSpaceBounds {

    //if (enemyType == kEnemyTypeTap) {

        CCSpriteFrameCache *spriteFrameCache = [CCSpriteFrameCache sharedSpriteFrameCache];        

        NSArray *spriteFrames = @[
        [spriteFrameCache spriteFrameByName:@"BigExplosion1.png"],
        [spriteFrameCache spriteFrameByName:@"BigExplosion2.png"],
        [spriteFrameCache spriteFrameByName:@"BigExplosion3.png"],
        [spriteFrameCache spriteFrameByName:@"BigExplosion4.png"],
        [spriteFrameCache spriteFrameByName:@"BigExplosion5.png"],
        ];
        self = [self initWithSpriteFrame:spriteFrames[rand() % [spriteFrames count]]];
    //}

    if (self) {

        lifeTime = LIFE_TIME + rand() / (float)RAND_MAX;
        self.anchorPoint = ccp(0.5, 0.5);
        velocity = initVelocity;
        spaceBounds = initSpaceBounds;
        self.scale = [UIScreen mainScreen].scale * 2;
    }
    return self;
}

- (void)calc:(ccTime)deltaTime {

    velocity = ccpMult(velocity, FRICTION);
    velocity = ccpAdd(velocity, ccp(0, GRAVITY * deltaTime));

    self.rotation += velocity.x * deltaTime;
    self.position = ccpAdd(self.position, ccpMult(velocity, deltaTime));

    if (self.position.x > CGRectGetMaxX(spaceBounds) - self.boundingBox.size.width * 0.5) {
        CGPoint pos = self.position;
        pos.x = CGRectGetMaxX(spaceBounds) - self.boundingBox.size.width * 0.5;
        self.position = pos;
        velocity.x = -velocity.x;
        velocity = ccpMult(velocity, BOUNCE_COEF);        
    }

    if (self.position.x < CGRectGetMinX(spaceBounds) + self.boundingBox.size.width * 0.5) {
        CGPoint pos = self.position;        
        pos.x = CGRectGetMinX(spaceBounds) + self.boundingBox.size.width * 0.5;
        self.position = pos;        
        velocity.x = -velocity.x;
        velocity = ccpMult(velocity, BOUNCE_COEF);
    }

    if (self.position.y < CGRectGetMinY(spaceBounds) + self.boundingBox.size.height * 0.5) {
        CGPoint pos = self.position;        
        pos.y = CGRectGetMinY(spaceBounds) + self.boundingBox.size.height * 0.5;
        self.position = pos;
        velocity.y = -velocity.y;
        velocity = ccpMult(velocity, BOUNCE_COEF);        
    }

    _bloodParticleSystem.position = self.position;

    elapsedTime += deltaTime;
    if (elapsedTime > lifeTime) {
        self.bloodParticleSystem.emissionRate = 0;
        [_delegate enemyBodyDebrisDidDie:self];
    }
    else {
        self.bloodParticleSystem.emissionRate = START_BLOOD_EMISSION_RATE * (1 - elapsedTime / lifeTime);
    }
}

@end
