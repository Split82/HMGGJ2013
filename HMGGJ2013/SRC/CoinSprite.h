//
//  CoinSprite.h
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/25/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "CCSprite.h"

@protocol CoinSpriteDelegate;


@interface CoinSprite : CCSprite

@property (nonatomic, weak) NSObject <CoinSpriteDelegate> *delegate;

- (id)initWithStartPos:(CGPoint)startPos;
- (void)update:(ccTime)deltaTime;

@end

@protocol CoinSpriteDelegate

- (void)coinDidDie:(CoinSprite*)coinSprite;

@end
