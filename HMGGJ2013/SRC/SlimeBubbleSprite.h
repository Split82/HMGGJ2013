//
//  SlimeBubbleSprite.h
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/26/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "CCSprite.h"

@interface SlimeBubbleSprite : CCSprite

- (id)initWithPos:(CGPoint)pos;
- (void)calc:(ccTime)deltaTime;

@end
