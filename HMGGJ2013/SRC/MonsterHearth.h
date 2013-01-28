//
//  MonsterHearth.h
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/27/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "CCSprite.h"

@interface MonsterHearth : CCSprite

@property (nonatomic, assign) float infarkt;

- (void)calc:(ccTime)deltaTime;

@end
