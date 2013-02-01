//
//  MenuButton.h
//  HMGGJ2013
//
//  Created by Lukáš Foldýna on 29.01.13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MenuButton : UIControl

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIImage *highlightedImage;

+ (UIImage *)rasterizedImage:(NSString *)name;
+ (CGRect)rectWithSize:(CGSize)size originY:(CGFloat)originY;

@end
