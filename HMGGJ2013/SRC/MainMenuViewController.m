//
//  MainMenuViewController.m
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/25/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "MainMenuViewController.h"
#import "CCDirector.h"
#import "MainGameScene.h"

@interface MainMenuViewController ()

@end

@implementation MainMenuViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)startGame {

    // Create an CCGLView with a RGB565 color buffer, and a depth buffer of 0-bits
    CCGLView *glView = [CCGLView viewWithFrame:self.view.window.bounds
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

    MainGameScene *scene = [[MainGameScene alloc] init];
    [director runWithScene:scene];

    [self presentViewController:director animated:NO completion:nil];
}

- (IBAction)StartGameButtonPressed:(id)sender {

    [self startGame];
}


@end
