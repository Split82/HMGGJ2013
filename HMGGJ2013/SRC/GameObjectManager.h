//
//  GameObjectManager.h
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 2/2/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "CoinSprite.h"
#import "EnemySprite.h"
#import "BombSprite.h"
#import "ScoreAddLabel.h"
#import "EnemyBodyDebris.h"
#import "BombExplosion.h"
#import "FlyingSkullSprite.h"
#import "Lightning.h"
#import "Trail.h"
#import "WaterSplash.h"

@protocol GameObjectManagerDelegate;


@interface GameObjectManager : NSObject <CoinSpriteDelegate, EnemySpriteDelegate, BombSpriteDelegate, ScoreAddLabelDelegate, EnemyBodyDebrisDelegate, BombExplosionDelegate, FlyingSkullSpriteDelegate, LightningDelegate, TrailDelegate, WaterSplashDelegate>

// Should be set
@property (nonatomic, weak) id <GameObjectManagerDelegate> delegate;
@property (nonatomic, assign) CGFloat groundY;
@property (nonatomic, assign) NSInteger zOrder;
@property (nonatomic, assign) CGPoint coinPickupAnimationDestinationPos;

// Readonly
@property (nonatomic, readonly) int numberOfKillsInLastCalc;
@property (nonatomic, strong, readonly) NSMutableArray *tapEnemies;
@property (nonatomic, strong, readonly) NSMutableArray *swipeEnemies;
@property (nonatomic, strong, readonly) NSMutableArray *coins;
@property (nonatomic, strong, readonly) NSMutableArray *bombs;
@property (nonatomic, strong, readonly) NSMutableArray *enemyBodyDebrises;
@property (nonatomic, strong, readonly) NSMutableArray *bubbles;
@property (nonatomic, strong, readonly) NSMutableArray *labels;
@property (nonatomic, strong, readonly) NSMutableArray *flyingSkulls;
@property (nonatomic, strong, readonly) NSMutableArray *bombExplosions;
@property (nonatomic, strong, readonly) NSMutableArray *lightnings;
@property (nonatomic, strong, readonly) NSMutableArray *waterSplashes;
@property (nonatomic, strong, readonly) NSMutableArray *trails;

- (id)initWithParentNode:(CCNode*)parentNode spriteBatchNode:(CCSpriteBatchNode*)spriteBatchNode particleBatchNode:(CCParticleBatchNode*)particleBatchNode;
- (void)calc:(ccTime)deltaTime;

// Adds
- (void)addScoreAddLabelWithText:(NSString*)text pos:(CGPoint)pos type:(ScoreAddLabelType)type addSkull:(BOOL)addSkull;
- (void)addBombAtPosX:(CGFloat)posX;
- (void)addCoinAtPos:(CGPoint)pos;
- (void)addBubble:(CGPoint)pos; // TODO automatic
- (void)addEnemy:(EnemyType)type;

// Actions
- (void)sliceEnemyFromWall:(EnemySprite*)enemy direction:(CGPoint)direction;
- (void)throwEnemyFromWall:(EnemySprite*)enemy;
- (void)pickupCoin:(CoinSprite*)cointSprite;
- (void)updateTrailWithStartPos:(CGPoint)startPos endPos:(CGPoint)endPos;
- (void)cancelTrail;

@end


@protocol GameObjectManagerDelegate <NSObject>

- (void)gameObjectManager:(GameObjectManager*)gameObjectManager bombDidDie:(BombSprite*)bombSprite;
- (CGFloat)gameObjectManagerSlimeSurfacePosY:(GameObjectManager*)gameObjectManager;

@end
