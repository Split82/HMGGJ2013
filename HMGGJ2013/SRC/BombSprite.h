//
//  BombSprite.h
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/26/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//


@protocol BombSpriteDelegate;


@interface BombSprite : CCSprite

@property (nonatomic, weak) id <BombSpriteDelegate> delegate;

- (id)initWithStartPos:(CGPoint)startPos groundY:(CGFloat)initGroundY;
- (void)calc:(ccTime)deltaTime;

@end


@protocol BombSpriteDelegate <NSObject>

- (void)bombDidDie:(BombSprite*)bombSprite;

@end