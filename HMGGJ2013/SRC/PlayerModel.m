//
//  PlayerModel.m
//  HMGGJ2013
//
//  Created by Lukáš Foldýna on 25.01.13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "PlayerModel.h"


#define kPlayerDefCoins         10
#define kPlayerDefHealth        100
#define kPlayerDefRageDealy     15
#define kPlayerDefRageMultipler 7
#define kPlayerDefRageReduction 0.5

#define kPlayerSyncTimer        30

#define kPlayerFirstKill            @"kPlayerFirstKill"
#define kPlayerBloodBath            @"kPlayerBloodBath"
#define kPlayerGlobalGameCount      @"kPlayerGlobalGameCount"
#define kPlayerGlobalKillCount      @"kPlayerGlobalKillCount"
#define kPlayerGlobalBombDropCount  @"kPlayerGlobalBombDropCount"
#define kPlayerGlobalCoinsCount     @"kPlayerGlobalCoinsCount"


@interface PlayerModel ()

@property (nonatomic, strong) NSLock *writeLock;

@property (nonatomic, assign) NSInteger enemyTaps;
@property (nonatomic, assign) NSInteger enemySwipes;

@property (nonatomic, assign) NSInteger firstBombCounter;
@property (nonatomic, assign) NSTimeInterval firstBombTimeinteval;

@property (nonatomic, assign) NSTimeInterval lastKillTime;
@property (nonatomic, assign) NSTimeInterval timer;

@property (nonatomic, assign) NSTimeInterval rageInterval;
@property (nonatomic, assign) NSTimeInterval disabledRageTimeinteval;

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
        // player defaults
        [self newGame];
        
        // achievements & score
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
        
        _firstBombTimeinteval = 0;
        _firstBombCounter = 0;
        
        NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDate *now = [NSDate date];
        NSDateComponents *components = [cal components:( NSYearCalendarUnit | NSMonthCalendarUnit | NSWeekCalendarUnit | NSWeekdayCalendarUnit ) fromDate:now];
        
        if ([components month] == 12) {
            if ([components day] == 24) {
                GKAchievement *achivement = [[GKAchievement alloc] initWithIdentifier:kAchievemntChristmassName];
                [achivement setPercentComplete:100];
                [achivement setShowsCompletionBanner:YES];
                [_achievements setObject:achivement forKey:kAchievemntChristmassName];
            } else if ([components day] == 31) {
                GKAchievement *achivement = [[GKAchievement alloc] initWithIdentifier:kAchievemntPartyBoyName];
                [achivement setPercentComplete:100];
                [achivement setShowsCompletionBanner:YES];
                [_achievements setObject:achivement forKey:kAchievemntPartyBoyName];
            }
        }
        _timer = [NSDate timeIntervalSinceReferenceDate] + kPlayerSyncTimer;
    }
    return self;
}

- (void) calc:(ccTime)deltaTime
{
    NSTimeInterval interval = [NSDate timeIntervalSinceReferenceDate];
    
    if (_rage > 0 && _rageInterval < interval) {
        if (_rageInterval != 0)
            [self _rageReduction];
        _rageInterval = interval + kPlayerDefRageReduction;
    }
    
    if (_timer < interval) {
        [self synchronize];
        _timer = interval + kPlayerSyncTimer;
    }
    
    if (_lastKillTime + 60 < interval && _kills > 0) {
        [self _dalaiLamaAchievements];
    }
}

#pragma mark -

- (void) setPoints:(NSInteger)points
{
    _points = points;
}

- (void) _rageReduction
{
    _rage -= 0.025;
    if (_rage <= 0) {
        _rage = 0;
        _rageInterval = 0;
    }
}

- (void) setKills:(NSInteger)kills
{
    NSInteger diff = kills - _kills;
    _kills = kills;
    self.rage += (float)diff / kPlayerDefRageMultipler;
    _rageInterval = 0;
    [self updateKillCount:diff];
}

- (void) setCoins:(NSInteger)coins
{
    NSInteger diff = coins - _coins;
    _coins = coins;
    [self updateCoinsCount:diff];
}

- (void) setHealth:(NSInteger)health
{
    if (health < 0) health = 0;
    _health = health;
}

- (void) setRage:(float)rage
{
    if (rage == 0) {
        _disabledRageTimeinteval = [NSDate timeIntervalSinceReferenceDate] + kPlayerDefRageDealy;
    } else if (_disabledRageTimeinteval && [NSDate timeIntervalSinceReferenceDate] < _disabledRageTimeinteval) {
        return;
    } else {
        _disabledRageTimeinteval = 0;
    }
    _rage = rage;
}

- (void) newGame
{
    _points = 0;
    _kills = 0;
    _coins = kPlayerDefCoins;
    _health = kPlayerDefHealth;
    _rage = 0;
    _disabledRageTimeinteval = [NSDate timeIntervalSinceReferenceDate] + kPlayerDefRageDealy;
    _rageInterval = 0;
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

- (void) resetAchievements
{
    [GKAchievement resetAchievementsWithCompletionHandler:^(NSError *error) {
        if (!error) {
            [_achievements removeAllObjects];
            [[NSFileManager defaultManager] removeItemAtPath:[self _achievementsFilePath] error:nil];
        } else {
            NSLog(@"failed to reset achievements: %@", error);
        }
    }];
    NSUserDefaults *df = [NSUserDefaults standardUserDefaults];
    [df setBool:NO forKey:kPlayerFirstKill];
    [df setBool:NO forKey:kPlayerBloodBath];
    [df setInteger:0 forKey:kPlayerGlobalGameCount];
    [df setInteger:0 forKey:kPlayerGlobalKillCount];
    [df setInteger:0 forKey:kPlayerGlobalBombDropCount];
    [df setInteger:0 forKey:kPlayerGlobalCoinsCount];
    [df synchronize];
    
    _lastKillTime = 0;
    
    _firstBombTimeinteval = 0;
    _firstBombCounter = 0;
    
    _enemyTaps = 0;
    _enemySwipes = 0;
}

- (void) gameStarted
{
    NSInteger count = [[NSUserDefaults standardUserDefaults] integerForKey:kPlayerGlobalGameCount];
    if (count == 0) {
        GKAchievement *achivement = [[GKAchievement alloc] initWithIdentifier:kAchievemntFirstAchivementName];
        [achivement setPercentComplete:100];
        [_achievements setObject:achivement forKey:kAchievemntFirstAchivementName];
    }
    count++;
    
    if (count == 15) {
        GKAchievement *achivement = [[GKAchievement alloc] initWithIdentifier:kAchievemntAddictedName];
        [achivement setPercentComplete:100];
        [achivement setShowsCompletionBanner:YES];
        [_achievements setObject:achivement forKey:kAchievemntAddictedName];
    }
    [[NSUserDefaults standardUserDefaults] setInteger:count forKey:kPlayerGlobalGameCount];
}

- (void) filledFloorWithBlood
{
    GKAchievement *achivement = [[GKAchievement alloc] initWithIdentifier:kAchievemntBloodyMaryName];
    [achivement setPercentComplete:100];
    [achivement setShowsCompletionBanner:YES];
    [_achievements setObject:achivement forKey:kAchievemntBloodyMaryName];
}

- (void) closeCall
{
    GKAchievement *achivement = [[GKAchievement alloc] initWithIdentifier:kAchievemntCloseCallName];
    [achivement setPercentComplete:100];
    [achivement setShowsCompletionBanner:YES];
    [_achievements setObject:achivement forKey:kAchievemntCloseCallName];
}

- (void) betaTester
{
    GKAchievement *achivement = [[GKAchievement alloc] initWithIdentifier:kAchievemntBetaTesterName];
    [achivement setPercentComplete:100];
    [achivement setShowsCompletionBanner:YES];
    [_achievements setObject:achivement forKey:kAchievemntBetaTesterName];
    [self synchronize];
}

- (void) callCenter
{
    GKAchievement *achivement = [[GKAchievement alloc] initWithIdentifier:kAchievemntCallCenterName];
    [achivement setPercentComplete:100];
    [achivement setShowsCompletionBanner:YES];
    [_achievements setObject:achivement forKey:kAchievemntCallCenterName];
}

- (void) enemyTaps:(NSInteger)taps
{
    _enemyTaps += taps;
    _enemySwipes = 0;
    
    if (_enemyTaps >= 10) {
        GKAchievement *achivement = [[GKAchievement alloc] initWithIdentifier:kAchievemntTapDencerName];
        [achivement setPercentComplete:100];
        [achivement setShowsCompletionBanner:YES];
        [_achievements setObject:achivement forKey:kAchievemntTapDencerName];
    }
}

- (void) enemySwipes:(NSInteger)enemySwipes
{
    _enemySwipes += enemySwipes;
    _enemyTaps = 0;
    
    if (_enemySwipes >= 10) {
        GKAchievement *achivement = [[GKAchievement alloc] initWithIdentifier:kAchievemntFruitNinjaName];
        [achivement setPercentComplete:100];
        [achivement setShowsCompletionBanner:YES];
        [_achievements setObject:achivement forKey:kAchievemntFruitNinjaName];
    }
}

- (void) updateKillCount:(NSInteger)kills
{
    NSInteger allKills = [[NSUserDefaults standardUserDefaults] integerForKey:kPlayerGlobalKillCount];
    allKills += kills;
    _lastKillTime = [NSDate timeIntervalSinceReferenceDate];
    
    if (allKills > 0 && ![[NSUserDefaults standardUserDefaults] boolForKey:kPlayerFirstKill]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kPlayerFirstKill];
        GKAchievement *achivement = [[GKAchievement alloc] initWithIdentifier:kAchievemntFirstKillName];
        [achivement setPercentComplete:100];
        [_achievements setObject:achivement forKey:kAchievemntFirstKillName];
    }
    if (kills >= 20 && ![[NSUserDefaults standardUserDefaults] boolForKey:kPlayerBloodBath]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kPlayerBloodBath];
        GKAchievement *achivement = [[GKAchievement alloc] initWithIdentifier:kAchievemntBloodBathName];
        [achivement setPercentComplete:100];
        [achivement setShowsCompletionBanner:YES];
        [_achievements setObject:achivement forKey:kAchievemntBloodBathName];
    }
    [[NSUserDefaults standardUserDefaults] setInteger:allKills forKey:kPlayerGlobalKillCount];
}

- (void) _dalaiLamaAchievements
{
    GKAchievement *achivement = [[GKAchievement alloc] initWithIdentifier:kAchievemntDalaiLamaName];
    [achivement setPercentComplete:100];
    [achivement setShowsCompletionBanner:YES];
    [_achievements setObject:achivement forKey:kAchievemntDalaiLamaName];
}

- (void) updateDropBombCount:(NSInteger)bombs
{
    _enemyTaps = 0;
    _enemySwipes = 0;
    
    NSInteger allBombs = [[NSUserDefaults standardUserDefaults] integerForKey:kPlayerGlobalBombDropCount];
    allBombs += bombs;
    [[NSUserDefaults standardUserDefaults] setInteger:allBombs forKey:kPlayerGlobalBombDropCount];

    if (_firstBombTimeinteval == 0)
        _firstBombTimeinteval = [NSDate timeIntervalSinceReferenceDate];
    
    if (_firstBombTimeinteval + 10 <= [NSDate timeIntervalSinceReferenceDate]) {
        if (_firstBombCounter + bombs >= 30) {
            GKAchievement *achivement = [[GKAchievement alloc] initWithIdentifier:kAchievemntCarpetBomberName];
            [achivement setPercentComplete:100];
            [achivement setShowsCompletionBanner:YES];
            [_achievements setObject:achivement forKey:kAchievemntCarpetBomberName];
        }
    } else {
        _firstBombCounter = 0;
        _firstBombTimeinteval = [NSDate timeIntervalSinceReferenceDate];
    }
    _firstBombCounter += bombs;
}

- (void) updateCoinsCount:(NSInteger)coins
{
    NSInteger allCoins = [[NSUserDefaults standardUserDefaults] integerForKey:kPlayerGlobalCoinsCount];
    allCoins += coins;
    [[NSUserDefaults standardUserDefaults] setInteger:allCoins forKey:kPlayerGlobalCoinsCount];
}

- (void) synchronize
{
    NSInteger allKills = [[NSUserDefaults standardUserDefaults] integerForKey:kPlayerGlobalKillCount];
    NSInteger allBombs = [[NSUserDefaults standardUserDefaults] integerForKey:kPlayerGlobalBombDropCount];
    NSInteger allCoins = [[NSUserDefaults standardUserDefaults] integerForKey:kPlayerGlobalCoinsCount];
    
    // kills achievements
    GKAchievement *achivement;
    NSArray *keys; NSInteger count = 100;
    keys = @[kAchievemntKill100Name, kAchievemntKill1000Name, kAchievemntKill10000Name, kAchievemntKill100000Name, kAchievemntKill1000000Name];
    for (NSString *key in keys) {
        achivement = [[GKAchievement alloc] initWithIdentifier:key];
        [achivement setPercentComplete:allKills >= count ? 100 : ((allKills / count) * 100)];
        [_achievements setObject:achivement forKey:key];
        count *= 10;
    }
    
    // bomb drop achievements
    count = 100;
    keys = @[kAchievemntDrop100Name, kAchievemntDrop1000Name, kAchievemntDrop10000Name, kAchievemntDrop100000Name, kAchievemntDrop1000000Name];
    for (NSString *key in keys) {
        achivement = [[GKAchievement alloc] initWithIdentifier:key];
        [achivement setPercentComplete:allBombs >= count ? 100 : ((allBombs / count) * 100)];
        [achivement setShowsCompletionBanner:YES];
        [_achievements setObject:achivement forKey:key];
        count *= 10;
    }
    
    // coins achievements
    count = 100;
    keys = @[kAchievemntCollect100Name, kAchievemntCollect1000Name, kAchievemntCollect10000Name, kAchievemntCollect100000Name, kAchievemntCollect1000000Name];
    for (NSString *key in keys) {
        achivement = [[GKAchievement alloc] initWithIdentifier:key];
        [achivement setPercentComplete:allCoins >= count ? 100 : ((allCoins / count) * 100)];
        [_achievements setObject:achivement forKey:key];
        count *= 10;
    }
    [self _submitScores];
    [self _saveScore];
    
    [self _submitAchievements];
    [self _saveAchievements];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark -
#pragma mark Private

- (NSString *) _scoreFilePath
{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
    return [NSString stringWithFormat:@"%@/%@.scores.plist", path, [GKLocalPlayer localPlayer].playerID];
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
    @try {
        int index = [_scores count] - 1;
        while (index >= 0) {
            GKScore *score = _scores[index];
            [self _submitScore:score];
            index--;
        }
    } @catch (NSException *exception) {
      
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
    return [NSString stringWithFormat:@"%@/%@.achievements.plist", path, [GKLocalPlayer localPlayer].playerID];
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
