//
//  MasterControlProgram.h
//  HMGGJ2013
//
//  Created by Peter Morihladko on 1/26/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EnemySprite.h"

// the one who runs the game
@protocol MainframeDelegate;

// the necessary evil
@interface MasterControlProgram : NSObject

@property (nonatomic, weak) id <MainframeDelegate> mainframe;

- (void)calc:(ccTime)deltaTime;

@end

@protocol MainframeDelegate <NSObject>

- (void)addEnemy:(EnemyType)type;

- (int)countTapEnemies;

- (int)countSwipeEnemies;

- (void)addCoinAtPos:(CGPoint)pos;

@end