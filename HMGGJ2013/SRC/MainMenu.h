//
//  MainMenu.h
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 2/2/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "Menu.h"

@protocol MainMenuDelegate;


@interface MainMenu : NSObject <Menu>

@property (nonatomic, weak) id <MainMenuDelegate> delegate;

- (id)initWithParentView:(UIView*)initParentView parentNode:(CCNode*)initParentNode bounds:(CGRect)initBounds;

@end


@protocol MainMenuDelegate <NSObject>

- (void)mainMenuNewGameButtonWasPressed:(MainMenu*)menu;
- (void)mainMenuCreditsButtonWasPressed:(MainMenu*)menu;
- (void)mainMenuRemoveAdsButtonWasPressed:(MainMenu*)menu;
- (void)mainMenuAchievementsButtonWasPressed:(MainMenu*)menu;
- (void)mainMenuLeaderboardsButtonWasPressed:(MainMenu*)menu;
- (void)mainMenuSoundButtonWasPressed:(MainMenu*)menu;

@end