//
//  FlyingSkullSprite.h
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/27/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "CCSprite.h"

@protocol FlyingSkullSpriteDelegate;

@interface FlyingSkullSprite : CCSprite

@property (nonatomic, weak) id <FlyingSkullSpriteDelegate> delegate;

- (id)initWithPos:(CGPoint)pos;
- (void)calc:(ccTime)deltaTime;

@end


@protocol FlyingSkullSpriteDelegate <NSObject>

- (void)flyingSkullSpriteDidFinish:(FlyingSkullSprite*)flyingSkull;

@end