//
//  MenuGameScene.h
//  HMGGJ2013
//
//  Created by Lukáš Foldýna on 26.01.13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "CCScene.h"

@interface MainMenuGameScene : CCScene

@property (nonatomic, weak) IBOutlet UIButton *topScoreButton;
@property (nonatomic, weak) IBOutlet UIButton *achievementsButton;
@property (nonatomic, getter = isGameCenterDisplayed) BOOL displayGameCenter;

- (IBAction)startGameButtonPressed:(id)sender;
- (IBAction)showLeaderboardButtonPressed:(id)sender;
- (IBAction)showAchievementsButtonPressed:(id)sender;
- (IBAction)showAboutButtonPressed:(id)sender;

@end
