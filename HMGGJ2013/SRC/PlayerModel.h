//
//  PlayerModel.h
//  HMGGJ2013
//
//  Created by Lukáš Foldýna on 25.01.13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>
#import "AchievemntNameDefinitions.h"

@interface PlayerModel : NSObject

@property (nonatomic, strong, readonly) NSArray *scores;
- (void) storeScore:(NSUInteger)value;

@property (nonatomic, strong, readonly) NSMutableDictionary *achievements;
- (void) addAchievement:(GKAchievement *)achievement;
- (void) resetAchievements;

- (void) gameStarted;
- (void) updateKillCount:(NSInteger)kills;
- (void) updateDropBombCount:(NSInteger)bombs;
- (void) updateCoinsCount:(NSInteger)coins;

- (void) synchronize;

@end
