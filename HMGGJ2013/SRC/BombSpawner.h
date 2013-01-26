//
//  BombSpawner.h
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/26/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "CCSprite.h"

@protocol BombSpawnerDelegate;


@interface BombSpawner : CCSprite

@property (nonatomic, readonly) CGPoint pos;
@property (nonatomic, weak) id <BombSpawnerDelegate> delegate;

- (id)init;
- (void)startSpawningAtPos:(CGPoint)pos;
- (void)cancelSpawning;
- (void)calc:(ccTime)deltaTime;

@end


@protocol BombSpawnerDelegate <NSObject>

- (void)bombSpawnerWantsBombToSpawn:(BombSpawner*)bombSpawner;

@end