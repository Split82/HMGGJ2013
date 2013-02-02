//
//  MainGameScene.h
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/25/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "GestureRecognizer.h"
#import "GameObjectManager.h"
#import "BombSpawner.h"
#import "MasterControlProgram.h"
#import "MainMenu.h"
#import "GameHUD.h"
#import "AboutViewController.h"

#define GROUND_Y (IS_568H ? 89 : 60)

@interface MainGameScene : CCScene <GestureRecognizerDelegate, BombSpawnerDelegate, MainFrame, GameObjectManagerDelegate, MainMenuDelegate, GameHUDDelegate, AboutViewControllerDelegate>

@end
