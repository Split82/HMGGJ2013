//
//  Trail.m
//  HMGGJ2013
//
//  Created by Loki on 1/27/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "Trail.h"

#define TRAIL_PART_COUNT 20
#define TRAIL_SIZE 5.0f
#define TRAIL_PART_MAX_LENGTH2 (100.0f*100.0f)
#define TRAIL_FADEOUT_SPEED 3.3f

@interface Trail() {

    CGPoint vertices[TRAIL_PART_COUNT * 2];
    CGPoint points[TRAIL_PART_COUNT];
    CGPoint normals[TRAIL_PART_COUNT];
    float alphas[TRAIL_PART_COUNT];
    
    unsigned char colors[TRAIL_PART_COUNT * 2 * 4];
    
    int currentIndex;
    CGPoint lastPoint;
    CGPoint currentPoint;
}

@end

@implementation Trail

- (id)initWithStartPos:(CGPoint)initStartPos endPos:(CGPoint)initEndPos {
    
    
    self = [super init];
    
    if (self) {
        
        
        for (int i = 0; i < TRAIL_PART_COUNT; i++) {
            
            alphas[i] = 0;
            points[i] = CGPointMake(0, 0);
            normals[i] = CGPointMake(0, 0);
        }
     
        
        currentIndex = 1;
        
        lastPoint = initStartPos;
        currentPoint = initEndPos;
        
        CGPoint normal = ccpNormalize(ccpSub(currentPoint, lastPoint));
        normal = CGPointMake(normal.y, -normal.x);
        
        points[0] = lastPoint;
        points[1] = currentPoint;
        normals[0] = normal;
        normals[1] = normal;
        alphas[0] = 1;
        alphas[1] = 1;
        
        _finished = NO;
        
        self.shaderProgram = [[CCShaderCache sharedShaderCache] programForKey:kCCShader_PositionColor];

    }
    
    return self;
}


- (void)addPoint:(CGPoint)pos {
    
    if (ccpDistanceSQ(pos, lastPoint) > TRAIL_PART_MAX_LENGTH2) {
        
        
        lastPoint = currentPoint;
        currentIndex = ((currentIndex + 1) % TRAIL_PART_COUNT);
    }
    
    currentPoint = pos;
    
    CGPoint normal = ccpNormalize(ccpSub(currentPoint, lastPoint));
    normal = CGPointMake(normal.y, -normal.x);
    
    normals[currentIndex] = normal;
    points[currentIndex] = currentPoint;
    alphas[currentIndex] = 1;
}

- (void)draw {
    
    if (_finished) return;
    
    ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position | kCCVertexAttribFlag_Color );
    
    [self.shaderProgram use];
    [self.shaderProgram setUniformForModelViewProjectionMatrix];
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    for (int i = 0; i < TRAIL_PART_COUNT; i++) {
        
        colors[i * 8 + 4] = colors[i * 8] = (int)(255);
        colors[i * 8 + 5] = colors[i * 8 + 1] = (int)(255);
        colors[i * 8 + 6] = colors[i * 8 + 2] = (int)(100 + 155 * alphas[i]);
        colors[i * 8 + 7] = colors[i * 8 + 3] = (int)(255);

        
        vertices[i * 2] = ccpAdd(points[i], ccpMult(normals[i], TRAIL_SIZE * alphas[i]));
        vertices[i * 2 + 1] = ccpAdd(points[i], ccpMult(normals[i], -TRAIL_SIZE * alphas[i]));
    }
    
    //repeat last point
    vertices[currentIndex * 2 + 2] = vertices[currentIndex * 2 + 1];
    
    glVertexAttribPointer(kCCVertexAttrib_Color, 4, GL_UNSIGNED_BYTE, GL_TRUE, 0, colors);
    glVertexAttribPointer(kCCVertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, 0, vertices);
    
    ccGLBindTexture2D(0);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, TRAIL_PART_COUNT * 2);
    
}

- (void)calc:(ccTime)dt {
    
    _finished = YES;
    
    float alphaChange = dt * TRAIL_FADEOUT_SPEED;
    
    for (int i = 0; i < TRAIL_PART_COUNT; i++) {
        
        alphas[i] -= alphaChange;
        if (alphas[i] < 0) {
            
            alphas[i] = 0;
        }
        else{
        
            _finished = NO;
        }
    }
    
    if (_finished) {
        
        [_delegate trailDidFinish:self];
    }
}

@end
