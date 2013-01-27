//
//  MainGameScene.h
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/25/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "GestureRecognizer.h"
#import "CoinSprite.h"
#import "EnemySprite.h"
#import "BombSprite.h"
#import "BombSpawner.h"
#import "MasterControlProgram.h"
#import "EnemyBodyDebris.h"
#import "ScoreAddLabel.h"

#define IS_WIDESCREEN ([[UIScreen mainScreen] bounds].size.height == 568.0f)
#define GROUND_Y (IS_WIDESCREEN ? 89 : 45)

@interface MainGameScene : CCScene <GestureRecognizerDelegate, CoinSpriteDelegate, EnemySpriteDelegate, BombSpriteDelegate, BombSpawnerDelegate, MainframeDelegate, EnemyBodyDebrisDelegate, ScoreAddLabelDelegate>

@end
