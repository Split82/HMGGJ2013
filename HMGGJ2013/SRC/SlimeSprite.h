//
//  SlimeSprite.h
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/26/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "CCSprite.h"

@interface SlimeSprite : CCSprite

@property (nonatomic, readonly) CGFloat maxHeight;

- (id)initWithWidth:(CGFloat)width maxHeight:(CGFloat)initMaxHeight;
- (void)calc:(ccTime)deltaTime;
- (void)setEnergy:(CGFloat)energy; // 0 - 1

@end
