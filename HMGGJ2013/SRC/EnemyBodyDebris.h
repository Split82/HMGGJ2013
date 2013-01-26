//
//  BodyDebris.h
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/26/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "CCSprite.h"
#import "EnemySprite.h"


@protocol EnemyBodyDebrisDelegate;


@interface EnemyBodyDebris : CCSprite


@property (nonatomic, weak) id <EnemyBodyDebrisDelegate> delegate;

- (id)init:(EnemyType)enemyType velocity:(CGPoint)initVelocity spaceBounds:(CGRect)initSpaceBounds;
- (void)calc:(ccTime)deltaTime;

@end


@protocol EnemyBodyDebrisDelegate <NSObject>

- (void)enemyBodyDebrisDidDie:(EnemyBodyDebris*)enemyBodyDebris;

@end
