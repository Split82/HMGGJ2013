//
//  AppDelegate.h
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/25/13.
//  Copyright __MyCompanyName__ 2013. All rights reserved.
//

#import "PlayerModel.h"

@class MainMenuGameScene;

@interface AppDelegate : NSObject <UIApplicationDelegate>

+ (MainMenuGameScene *) mainMenuScene;
+ (PlayerModel *) player;
@property (nonatomic, strong) PlayerModel *player;

@end
