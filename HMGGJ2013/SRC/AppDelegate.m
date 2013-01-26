//
//  AppDelegate.m
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/25/13.
//  Copyright __MyCompanyName__ 2013. All rights reserved.
//

#import "AppDelegate.h"
#import "MainMenuViewController.h"
#import <GameKit/GameKit.h>


@interface AppDelegate()
{
	UIWindow *window;
}

@property (retain,readwrite) NSString *currentPlayerID;
@property (readwrite, getter = isGameCenterAuthenticationComplete) BOOL gameCenterAuthenticationComplete;

@end


@implementation AppDelegate

#pragma mark -

+ (PlayerModel *) player
{
    return [(id)[[UIApplication sharedApplication] delegate] player];
}

#pragma mark UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
	// Create the main window
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    MainMenuViewController *viewController = [[MainMenuViewController alloc] initWithNibName:@"MainMenuViewController" bundle:nil];
    window.rootViewController = viewController;

	[window makeKeyAndVisible];
	
    [self setGameCenterAuthenticationComplete:NO];
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    [localPlayer authenticateWithCompletionHandler:^(NSError *error) {
        if ([localPlayer isAuthenticated]) {
            [self setGameCenterAuthenticationComplete:YES];
            
            if (![self currentPlayerID] || ! [self.currentPlayerID isEqualToString:localPlayer.playerID]) {
                if (![self.currentPlayerID isEqualToString:localPlayer.playerID]) {
                    [self setPlayer:[[PlayerModel alloc] init]];
                }
                [self.player synchronize];
                [viewController setDisplayGameCenter:YES];
                //TODO: SPLIT/LOKI load new game...
            }
        } else {
            // Player se logoutnul killnout aktualni hru?
            [self setGameCenterAuthenticationComplete:NO];
            [viewController setDisplayGameCenter:NO];
        }
    }];
	return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
	return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (void)applicationWillResignActive:(UIApplication *)application {
    
    [[CCDirector sharedDirector] pause];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    
    [[CCDirector sharedDirector] resume];
}

- (void)applicationDidEnterBackground:(UIApplication*)application {
    [self setGameCenterAuthenticationComplete:NO];
    [(MainMenuViewController *)[window rootViewController] setDisplayGameCenter:NO];
    
    [[CCDirector sharedDirector] stopAnimation];
}

- (void)applicationWillEnterForeground:(UIApplication*)application {
    
    [[CCDirector sharedDirector] startAnimation];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    
	CC_DIRECTOR_END();
}


- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    
	[[CCDirector sharedDirector] purgeCachedData];
}

- (void)applicationSignificantTimeChange:(UIApplication *)application {
    
	[[CCDirector sharedDirector] setNextDeltaTimeZero:YES];
}

@end

