//
//  MasterControlProgram.h
//  HMGGJ2013
//
//  Created by Peter Morihladko on 1/26/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "EnemySprite.h"

@protocol MainFrame;


// the necessary evil
@interface MasterControlProgram : NSObject

@property (nonatomic, weak) id <MainFrame> mainframe;
@property (nonatomic, assign) BOOL tutorialFinished;
@property (nonatomic, assign) BOOL tapperKilled;
@property (nonatomic, assign) BOOL swiperKilled;

- (void)calc:(ccTime)deltaTime;

@end


@protocol MainFrame <NSObject>

- (void)masterControlProgram:(MasterControlProgram*)masterControlProgram addEnemy:(EnemyType)type;
- (int)masterControlProgramNumberOfTapEnemies:(MasterControlProgram*)masterControlProgram;
- (int)masterControlProgramNumberOfSwipeEnemies:(MasterControlProgram*)masterControlProgram;
- (void)masterControlProgram:(MasterControlProgram*)masterControlProgram addCoinAtPos:(CGPoint)pos;
- (int)masterControlProgramNumberOfPlayerCoins:(MasterControlProgram*)masterControlProgram;

@end