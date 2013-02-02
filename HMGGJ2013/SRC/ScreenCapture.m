//
//  ScreenCapture.m
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 2/2/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "ScreenCapture.h"

@implementation ScreenCapture

#pragma mark - Screen capture

static void releaseScreenshotData(void *info, const void *data, size_t size) {
	free((void *)data);
};

+ (UIImage*)captureScreen {

    int framebufferWidth = 320;
    int framebufferHeight = 480;

	NSInteger dataLength = framebufferWidth * framebufferHeight * 4;

	// Allocate array.
	GLuint *buffer = (GLuint *) malloc(dataLength);
	GLuint *resultsBuffer = (GLuint *)malloc(dataLength);
    // Read data
	glReadPixels(0, 0, framebufferWidth, framebufferHeight, GL_RGBA, GL_UNSIGNED_BYTE, buffer);

    // Flip vertical
	for(int y = 0; y < framebufferHeight; y++) {
		for(int x = 0; x < framebufferWidth; x++) {
			resultsBuffer[x + y * framebufferWidth] = buffer[x + (framebufferHeight - 1 - y) * framebufferWidth];
		}
	}

	free(buffer);

	// make data provider with data.
	CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, resultsBuffer, dataLength, releaseScreenshotData);

	// prep the ingredients
	const int bitsPerComponent = 8;
	const int bitsPerPixel = 4 * bitsPerComponent;
	const int bytesPerRow = 4 * framebufferWidth;
	CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
	CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
	CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;

	// make the cgimage
	CGImageRef imageRef = CGImageCreate(framebufferWidth, framebufferHeight, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
	CGColorSpaceRelease(colorSpaceRef);
	CGDataProviderRelease(provider);

	// then make the UIImage from that
	UIImage *image = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);
    
	return image;
}

+ (void)captureAndSaveScreen:(int)frameNum {

    UIImage *image = [ScreenCapture captureScreen];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT , 0), ^{
        NSString *fileName = [basePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.jpg", frameNum]];
        [UIImageJPEGRepresentation(image, 0.8) writeToFile:fileName atomically:YES];
    });
}

@end
