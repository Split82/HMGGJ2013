//
//  CoinSprite.h
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/25/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "CCSprite.h"

@interface CoinSprite : CCSprite

- (id)initWithStartPos:(CGPoint)startPos;
- (void)update:(ccTime)deltaTime;

@end
