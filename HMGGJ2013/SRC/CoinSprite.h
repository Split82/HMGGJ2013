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
{    
    float lifeTime;
    float groundY;
    CGPoint velocity;
    
    NSArray *animationFrames;
    int animationIndexes[14];
    int animationOffset;
}

@property (nonatomic, weak) id <CoinSpriteDelegate> delegate;

- (id)initWithStartPos:(CGPoint)startPos spaceBounds:(CGRect)initSpaceBounds;
- (void)calc:(ccTime)deltaTime;

@end

@protocol CoinSpriteDelegate <NSObject>

- (void)coinDidDie:(CoinSprite*)coinSprite;

@end
