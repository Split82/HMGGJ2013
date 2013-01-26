//
//  Enemy.h
//  HMGGJ2013
//
//  Created by Loki on 1/25/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    kEnemyTypeSwipe,
    kEnemyTypeTap,
} EnemyType;

typedef enum {
    kEnemyStateWalking,
    kEnemyStateClimbing,
    kEnemyStateFalling,
} EnemyState;

@protocol EnemySpriteDelegate;

@interface EnemySprite : CCSprite


-(id) initWithType:(EnemyType)type;
-(void) update:(ccTime)time;
-(void) throwFromWall;

@property (nonatomic, weak) NSObject <EnemySpriteDelegate> *delegate;
@property (nonatomic, assign) EnemyType type;
@property (nonatomic, assign) EnemyState state;

@end


@protocol EnemySpriteDelegate

- (void)enemyDidClimbWall:(EnemySprite*)enemy;

@end