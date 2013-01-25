//
//  MainMenuViewController.h
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/25/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainMenuViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIButton *topScoreButton;
@property (nonatomic, weak) IBOutlet UIButton *achievementsButton;
@property (nonatomic, getter = isGameCenterDisplayed) BOOL displayGameCenter;

- (IBAction)startGameButtonPressed:(id)sender;
- (IBAction)showLeaderboardButtonPressed:(id)sender;
- (IBAction)showAchievementsButtonPressed:(id)sender;

@end
