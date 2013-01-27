//
//  Lightning.h
//  HMGGJ2013
//
//  Created by Loki on 1/27/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "CCNode.h"

@protocol LightningDelegate;

@interface Lightning : CCNode

@property (nonatomic, assign) BOOL finished;

@property (nonatomic, weak) id <LightningDelegate> delegate;

- (void)draw;
- (id)initWithStartPos:(CGPoint)initStartPos endPos:(CGPoint)initEndPos;

- (void)calc:(ccTime)dt;

@end

@protocol LightningDelegate <NSObject>

- (void)lightningDidFinish:(Lightning*)lightning;

@end