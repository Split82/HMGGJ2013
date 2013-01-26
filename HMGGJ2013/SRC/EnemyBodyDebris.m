//
//  BodyDebris.m
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/26/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "EnemyBodyDebris.h"

#define GRAVITY -2000.0f
#define FRICTION 0.92f
#define BOUNCE_COEF 0.7f
#define LIFE_TIME 4

@interface EnemyBodyDebris() {

    CGPoint velocity;
    CGRect spaceBounds;
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
    self.position = ccpAdd(self.position, velocity);

    if (self.position.x > CGRectGetMaxX(spaceBounds)) {
        CGPoint pos = self.position;
        pos.x = CGRectGetMaxX(spaceBounds);
        self.position = pos;
        velocity.x -= velocity.x;
    }

    if (self.position.x < CGRectGetMinX(spaceBounds)) {
        CGPoint pos = self.position;        
        pos.x = CGRectGetMinX(spaceBounds);
        self.position = pos;        
        velocity.x -= velocity.x;
    }

    if (self.position.y < CGRectGetMinY(spaceBounds)) {
        CGPoint pos = self.position;        
        pos.y = CGRectGetMinY(spaceBounds);
        self.position = pos;
        velocity.y -= velocity.y;
    }

    lifeTime += deltaTime;
    if (lifeTime > LIFE_TIME) {
        [_delegate enemyBodyDebrisDidDie:self];
    }
}

@end
