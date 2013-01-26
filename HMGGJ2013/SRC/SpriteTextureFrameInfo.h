//
//  SpriteTextureFrameInfo.h
//  HMGGJ2013
//
//  Created by Loki on 1/26/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SpriteTextureFrameInfo : NSObject

- (id) initWithFrameName:(NSString*)frameName offset:(CGPoint)offset;

@property (nonatomic, copy) NSString* frameName;
@property (nonatomic, assign) CGPoint offset;

@end
