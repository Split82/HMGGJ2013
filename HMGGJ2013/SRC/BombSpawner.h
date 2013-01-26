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

- (id)init;
- (void)startSpawning;
- (void)endSpawning;
- (void)calc:(ccTime)deltaTime;

@end


@protocol BombSpawnerDelegate <NSObject>

- (void)bombSpawnerWantsBombToSpawn:(BombSpawner*)bombSpawner;

@end