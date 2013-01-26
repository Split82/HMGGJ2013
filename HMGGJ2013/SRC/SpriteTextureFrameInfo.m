//
//  SpriteTextureFrameInfo.m
//  HMGGJ2013
//
//  Created by Loki on 1/26/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "SpriteTextureFrameInfo.h"

@implementation SpriteTextureFrameInfo

@synthesize frameName, offset;

- (id) initWithFrameName:(NSString*)_frameName offset:(CGPoint)_offset {
    
    if ([super init]) {
        
        self.frameName = frameName;
        self.offset = _offset;
    }
    
    return self;
}


@end
