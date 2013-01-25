//
//  AppDelegate.m
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/25/13.
//  Copyright __MyCompanyName__ 2013. All rights reserved.
//

#import "AppDelegate.h"
#import "MainMenuViewController.h"

@interface AppDelegate() {

	UIWindow *window;
}

@end


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
	// Create the main window
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    MainMenuViewController *viewController = [[MainMenuViewController alloc] initWithNibName:@"MainMenuViewController" bundle:nil];
    window.rootViewController = viewController;

	[window makeKeyAndVisible];
	
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

