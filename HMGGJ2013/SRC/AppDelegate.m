//
//  AppDelegate.m
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/25/13.
//  Copyright __MyCompanyName__ 2013. All rights reserved.
//

#import "AppDelegate.h"
#import "AudioManager.h"
#import "MainMenuGameScene.h"
#import <GameKit/GameKit.h>


@interface AppDelegate ()
{
	UIWindow *window;
}

@property (retain,readwrite) NSString *currentPlayerID;
@property (readwrite, getter = isGameCenterAuthenticationComplete) BOOL gameCenterAuthenticationComplete;

@property (nonatomic, strong) MainMenuGameScene *mainMenu;

@end


@implementation AppDelegate

#pragma mark -

+ (MainMenuGameScene *) mainMenuScene
{
    return [(id)[[UIApplication sharedApplication] delegate] mainMenu];
}

+ (PlayerModel *) player
{
    return [(id)[[UIApplication sharedApplication] delegate] player];
}

#pragma mark UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
	// Create the main window
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    [[AudioManager sharedManager] preloadSounds];
    
    // Create an CCGLView with a RGB565 color buffer, and a depth buffer of 0-bits
    CCGLView *glView = [CCGLView viewWithFrame:window.bounds
                                   pixelFormat:kEAGLColorFormatRGBA8	//kEAGLColorFormatRGBA8
                                   depthFormat:0	//GL_DEPTH_COMPONENT24_OES
                            preserveBackbuffer:NO
                                    sharegroup:nil
                                 multiSampling:NO
                               numberOfSamples:0];
    
    CCDirector *director = (CCDirectorIOS*)[CCDirector sharedDirector];
    
    director.wantsFullScreenLayout = YES;
    
    // Display FSP and SPF
    [director setDisplayStats:YES];
    
    // set FPS at 60
    [director setAnimationInterval:1.0/60];
    
    // attach the openglView to the director
    [director setView:glView];
    
    // for rotation and other messages
    //[director setDelegate:self];
    
    // 2D projection
    [director setProjection:kCCDirectorProjection2D];
    
    // Enables High Res mode (Retina Display) on iPhone 4 and maintains low res on all other devices
    [director enableRetinaDisplay:YES];
    
    // Default texture format for PNG/BMP/TIFF/JPEG/GIF images
    // It can be RGBA8888, RGBA4444, RGB5_A1, RGB565
    // You can change anytime.
    [CCTexture2D setDefaultAlphaPixelFormat:kCCTexture2DPixelFormat_RGBA8888];
    
    // If the 1st suffix is not found and if fallback is enabled then fallback suffixes are going to searched. If none is found, it will try with the name without suffix.
    // On iPad HD  : "-ipadhd", "-ipad",  "-hd"
    // On iPad     : "-ipad", "-hd"
    // On iPhone HD: "-hd"
    /*
     CCFileUtils *sharedFileUtils = [CCFileUtils sharedFileUtils];
     [sharedFileUtils setEnableFallbackSuffixes:NO];				// Default: NO. No fallback suffixes are going to be used
     [sharedFileUtils setiPhoneRetinaDisplaySuffix:@"-hd"];		// Default on iPhone RetinaDisplay is "-hd"
     [sharedFileUtils setiPadSuffix:@"-ipad"];					// Default on iPad is "ipad"
     [sharedFileUtils setiPadRetinaDisplaySuffix:@"-ipadhd"];	// Default on iPad RetinaDisplay is "-ipadhd"
     */
    
    // Assume that PVR images have premultiplied alpha
    [CCTexture2D PVRImagesHavePremultipliedAlpha:YES];
    
    // Create a Navigation Controller with the Director
    _mainMenu = [[MainMenuGameScene alloc] init];
    
	// for rotation and other messages
    [director runWithScene:_mainMenu];
	
	// set the Navigation Controller as the root view controller
	[window setRootViewController:director];
    [window makeKeyAndVisible];
	
    [self setGameCenterAuthenticationComplete:NO];
    
    [self setPlayer:[[PlayerModel alloc] init]];
    
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    [localPlayer authenticateWithCompletionHandler:^(NSError *error) {
        if ([localPlayer isAuthenticated]) {
            [self setGameCenterAuthenticationComplete:YES];
            
            if (![self currentPlayerID] || ! [self.currentPlayerID isEqualToString:localPlayer.playerID]) {
                if (![self.currentPlayerID isEqualToString:localPlayer.playerID]) {
                    [self setPlayer:[[PlayerModel alloc] init]];
                }
                int64_t delayInSeconds = 1.0;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [self.player synchronize];
                });
                [_mainMenu setDisplayGameCenter:YES];
                //TODO: SPLIT/LOKI load new game...
            }
        } else {
            // Player se logoutnul killnout aktualni hru?
            [self setGameCenterAuthenticationComplete:NO];
            [_mainMenu setDisplayGameCenter:NO];
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
    [_mainMenu setDisplayGameCenter:NO];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
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

