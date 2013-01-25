//
//  PlayerModel.m
//  HMGGJ2013
//
//  Created by Lukáš Foldýna on 25.01.13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "PlayerModel.h"


@interface PlayerModel ()

@property (nonatomic, strong) NSLock *writeLock;

@end

@implementation PlayerModel
{
    NSMutableArray *_scores;
    NSMutableDictionary *_achievements;
}

@synthesize scores = _scores;
@synthesize achievements = _achievements;

- (id) init
{
    self = [super init];
    
    if (self) {
        _writeLock = [[NSLock alloc] init];
        
        id unarchivedData = nil;
        unarchivedData = [NSKeyedUnarchiver unarchiveObjectWithFile:[self _scoreFilePath]];
        
        if (unarchivedData) {
            _scores = [NSMutableArray arrayWithArray:unarchivedData];
            [self _submitScores];
        } else {
            _scores = [NSMutableArray array];
        }
        unarchivedData = [NSKeyedUnarchiver unarchiveObjectWithFile:[self _achievementsFilePath]];
        
        if (unarchivedData) {
            _achievements = [NSMutableDictionary dictionaryWithDictionary:unarchivedData];
            [self _submitAchievements];
        } else {
            _achievements = [NSMutableDictionary dictionary];
        }
    }
    return self;
}

#pragma mark Score

- (void) storeScore:(NSUInteger)value
{
    GKScore *score = [[GKScore alloc] initWithCategory:kTopScoreName];
    [score setValue:value];
    [score setShouldSetDefaultLeaderboard:YES];
    [_scores addObject:score];

    [self _submitScores];
    [self _saveScore];
}

#pragma mark Achievemnt

- (void) addAchievement:(GKAchievement *)achievement
{
    GKAchievement *currentStorage = _achievements[achievement.identifier];
    
    if (!currentStorage || (currentStorage && currentStorage.percentComplete < achievement.percentComplete)) {
        [_achievements setObject:achievement forKey:achievement.identifier];
    }
    [self _submitAchievements];
    [self _saveAchievements];
}

- (void) resetAchivements
{
    [GKAchievement resetAchievementsWithCompletionHandler:^(NSError *error) {
         if (!error) {
             [_achievements removeAllObjects];
             [[NSFileManager defaultManager] removeItemAtPath:[self _achievementsFilePath] error:nil];
         } else {
             NSLog(@"failed to reset achievements: %@", error);
         }
     }];
}

- (void) synchronize
{
    [self _submitScores];
    [self _saveScore];
    
    [self _submitAchievements];
    [self _saveAchievements];
}

#pragma mark -
#pragma mark Private

- (NSString *) _scoreFilePath
{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
    return [NSString stringWithFormat:@"%@/%@.scores.plist", [GKLocalPlayer localPlayer].playerID, path];
}

- (void) _submitScore:(GKScore *)score
{
    if ([[GKLocalPlayer localPlayer] isAuthenticated]) {
        if (![score value])
            return;
        [score reportScoreWithCompletionHandler:^(NSError *error) {
            if (!error || (![error code] && ![error domain])) {
                NSLog(@"failed to send score to game center: %@", error);
            } else {
                [_scores removeObjectAtIndex:[_scores indexOfObject:score]];
            }
        }];
    }
}

- (void) _submitScores
{
    int index = [_scores count] - 1;
    while (index >= 0) {
        GKScore *score = _scores[index];
        [self _submitScore:score];
        index--;
    }
}

- (void) _saveScore
{
    if (![_scores count])
        return;
    [_writeLock lock];
    
    NSError *error;
    NSData *archivedScores = [NSKeyedArchiver archivedDataWithRootObject:_scores];
    [archivedScores writeToFile:[self _scoreFilePath] options:NSDataWritingFileProtectionNone error:&error];
    
    if (error) {
        // Shit, it's not my fault, split!
        NSLog(@"Failed to save scores file data: %@", error);
    }
    [_writeLock unlock];
}

- (NSString *) _achievementsFilePath
{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
    return [NSString stringWithFormat:@"%@/%@.achievements.plist", [GKLocalPlayer localPlayer].playerID, path];
}

- (void) _submitAchievement:(GKAchievement *)achievement
{
    [achievement reportAchievementWithCompletionHandler: ^(NSError *error) {
        if (error) {
            NSLog(@"failed to send achievement to game center %@", error);
        } else {
            if (_achievements[achievement.identifier])
                [_achievements removeObjectForKey:achievement.identifier];
        }
    }];
}

- (void) _submitAchievements
{
    for (NSString *key in [_achievements allKeys]) {
        GKAchievement *achievement = _achievements[key];
        [_achievements removeObjectForKey:key];
        [self _submitAchievement:achievement];
    }
}

- (void) _saveAchievements
{
    if (![_achievements allValues])
        return;
    [_writeLock lock];
    
    NSError *error;
    NSData *archivedAchievements = [NSKeyedArchiver archivedDataWithRootObject:_achievements];
    [archivedAchievements writeToFile:[self _achievementsFilePath] options:NSDataWritingFileProtectionNone error:&error];
    
    if (error) {
        // Shit, it's not my fault, split!
        NSLog(@"Failed to save achievements file data: %@", error);
    }
    [_writeLock unlock];
}

@end
