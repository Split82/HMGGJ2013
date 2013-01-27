//
//  SpriteTextureFrameInfo.m
//  HMGGJ2013
//
//  Created by Loki on 1/26/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "SpriteTextureFrameInfo.h"

@implementation SpriteTextureFrameInfo

@synthesize frame, offset;

- (id) initWithFrameName:(NSString*)_frameName offset:(CGPoint)_offset {
    
    if (self = [super init]) {
        
        self.frame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:_frameName];
        self.offset = _offset;
    }
    
    return self;
}

+ (id) createWithFrameName:(NSString*)_frameName offset:(CGPoint)_offset {
    
    return [[SpriteTextureFrameInfo alloc] initWithFrameName:_frameName offset:_offset];
}



@end
