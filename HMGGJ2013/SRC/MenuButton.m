//
//  MenuButton.m
//  HMGGJ2013
//
//  Created by Lukáš Foldýna on 29.01.13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "MenuButton.h"


@interface MenuButton ()

@property (nonatomic, strong) CALayer *backgroundLayer;

@end

@implementation MenuButton

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        _backgroundLayer = [CALayer layer];
        _backgroundLayer.magnificationFilter = kCAFilterNearest;
        _backgroundLayer.actions = @{ @"onOrderIn":[NSNull null],
        @"onOrderOut":[NSNull null],
        @"sublayers":[NSNull null],
        @"contents":[NSNull null],
        @"bounds":[NSNull null]};
        [self.layer addSublayer:_backgroundLayer];
    }
    return self;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    CGRect frame = [self bounds];
    CGSize size = _backgroundLayer.frame.size;
    [_backgroundLayer setFrame:CGRectMake(floorf((frame.size.width - size.width) / 2), floorf((frame.size.height - size.height) / 2), size.width, size.height)];
}

- (void) setImage:(UIImage *)image
{
    _image = image;
    CGFloat scale = 2;
    CGSize size = [image size];
    size.width *= scale;
    size.height *= scale;
    [_backgroundLayer setContents:(id)[[self _rasterizedImage:image] CGImage]];
    [_backgroundLayer setFrame:CGRectMake(0.0, 0.0, size.width, size.height)];
    
    [self layoutSubviews];
}

- (void) setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    
    if (!_highlightedImage)
        return;
    if (highlighted) {
        [_backgroundLayer setContents:(id)[[self _rasterizedImage:_highlightedImage] CGImage]];
    } else {
        [_backgroundLayer setContents:(id)[[self _rasterizedImage:_image] CGImage]];
    }
}

#pragma mark -

+ (UIImage *)rasterizedImage:(NSString *)name {
    UIImage *image = [UIImage imageNamed:name];
    image = [UIImage imageWithCGImage:[image CGImage] scale:[[UIScreen mainScreen] scale] * 2 orientation:image.imageOrientation];
    return image;
}

+ (CGRect)rectWithSize:(CGSize)size originY:(CGFloat)originY {
    CGFloat scale = 2;
    size.width *= scale;
    size.height *= scale;
    CGSize contentSize = [CCDirector sharedDirector].winSize;
    return CGRectMake((contentSize.width - size.width) / 2, originY,
                      size.width, size.height);
}

#pragma mark -
#pragma mark Private

- (UIImage *) _rasterizedImage:(UIImage *)image
{
    return [UIImage imageWithCGImage:[image CGImage] scale:[[UIScreen mainScreen] scale] * 2 orientation:image.imageOrientation];
}

@end
