//
//  Trail.h
//  HMGGJ2013
//
//  Created by Loki on 1/27/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "CCNode.h"

@protocol TrailDelegate;

@interface Trail : CCNode

@property (nonatomic, assign) BOOL finished;

@property (nonatomic, weak) id <TrailDelegate> delegate;


- (void)draw;
- (id)initWithStartPos:(CGPoint)initStartPos endPos:(CGPoint)initEndPos;

- (void)calc:(ccTime)dt;

- (void)addPoint:(CGPoint)pos;

@end

@protocol TrailDelegate <NSObject>

- (void)trailDidFinish:(Trail*)trail;

@end