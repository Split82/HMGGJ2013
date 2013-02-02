//
//  ScreenCapture.h
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 2/2/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

@interface ScreenCapture : NSObject

+ (UIImage*)captureScreen;
+ (void)captureAndSaveScreen:(int)frameNum;

@end
