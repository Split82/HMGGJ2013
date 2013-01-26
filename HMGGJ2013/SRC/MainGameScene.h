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

@interface MainGameScene : CCScene <GestureRecognizerDelegate, CoinSpriteDelegate, EnemySpriteDelegate>

@end
