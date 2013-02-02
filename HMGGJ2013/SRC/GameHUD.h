//
//  GameHUD.h
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 2/2/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

@protocol GameHUDDelegate;


@interface GameHUD : NSObject

@property (nonatomic, weak) id <GameHUDDelegate> delegate;
@property (nonatomic, assign) int score;
@property (nonatomic, assign) int numberOfCoins;
@property (nonatomic, assign) float rageProgress; // 0 - 1
@property (nonatomic, readonly) CGPoint coinsSpritePosition;

- (id)initWithParentView:(UIView*)parentView parentNode:(CCNode*)parentNode parentSpriteBatchNode:(CCNode*)parentSpriteBatchNode bounds:(CGRect)bounds;

- (void)show;
- (void)hide;

@end


@protocol GameHUDDelegate <NSObject>

- (void)gameHUDPauseButtonWasPressed:(GameHUD*)gameHUD;

@end