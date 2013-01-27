//
//  BombExplosion.h
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/27/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "CCSprite.h"

@protocol BombExplosionDelegate;


@interface BombExplosion : CCSprite

@property (nonatomic, weak) id <BombExplosionDelegate> delegate;

- (void)calc:(ccTime)deltaTime;

@end


@protocol BombExplosionDelegate <NSObject>

- (void)bombExplosionDidFinish:(BombExplosion*)bombExplosion;

@end