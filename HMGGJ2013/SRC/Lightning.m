//
//  Lightning.m
//  HMGGJ2013
//
//  Created by Loki on 1/27/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.

#import "Lightning.h"

static const float kUpdateInterval = 0.1f;
static const float kGenerateNewInterval = 0.3f;
static const float kMiddlePointOffsetMul = 0.5f;

static const float kArcWidth = 20;

static const float kSegmentLength = 20.0f;

@implementation Lightning {
    
    CGPoint startPos;
    CGPoint endPos;
    
    
    float size;
    
    CGPoint *points;
    unsigned char *colors;
    CGPoint *stripes;
    
    int pointsCount;
    
    ccTime elapsedTime;
    
}

@synthesize finished;

- (id)initWithStartPos:(CGPoint)initStartPos endPos:(CGPoint)initEndPos {
    
    self = [super init];
    
    if (self) {
        
        finished =  NO;
        points = NULL;
        colors = NULL;
        pointsCount = 0;
        
        elapsedTime = 0;
        startPos = initStartPos;
        endPos = initEndPos;
        
        self.shaderProgram = [[CCShaderCache sharedShaderCache] programForKey:kCCShader_PositionColor];        
        
        [self generate];
        
    }
    
    return  self;
}



- (void)draw {
    
    if (finished) return;
    
    ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position | kCCVertexAttribFlag_Color );

    [self.shaderProgram use];
    [self.shaderProgram setUniformForModelViewProjectionMatrix];
    
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    glEnableVertexAttribArray(kCCVertexAttribFlag_Position);
    glEnableVertexAttribArray(kCCVertexAttribFlag_Color);
    
    for (int i = 0; i < pointsCount; i++) {
        
        colors[i * 4] = (int)(255 * 0.4f + size * 0.2f);
        colors[i * 4 + 1] = (int)(255 * 0.4f + size * 0.2f);
        colors[i * 4 + 2] = (int)(255);
        colors[i * 4 + 2] = (int)(255);
    }
    
    glVertexAttribPointer(kCCVertexAttrib_Color, 4, GL_UNSIGNED_BYTE, GL_TRUE, 0, colors);
    glVertexAttribPointer(kCCVertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, 0, points);
    
    glLineWidth(MAX(size * 20, 1.0f));
    
    glDrawArrays(GL_LINE_STRIP, 0, pointsCount);
    
    
    
    memset(colors, 255, pointsCount * 4);
    glVertexAttribPointer(kCCVertexAttrib_Color, 4, GL_UNSIGNED_BYTE, GL_TRUE, 0, colors);
    
    glLineWidth(1.0f);
    
    glDrawArrays(GL_LINE_STRIP, 0, pointsCount);
    
}


- (void)calc:(ccTime)dt {
    
    if (elapsedTime > kGenerateNewInterval) {
        
        finished = YES;
        [self removeFromParentAndCleanup:YES];
        return;
    }
    
    
    elapsedTime += dt;
    size = 1.0f - fabs(elapsedTime / kGenerateNewInterval * 2 - 1);
}

- (void)generate {
    
    
    if (points) {
        free(points);
        points = NULL;
        
        free(colors);
        colors = NULL;
    }
    
    float dx = (endPos.x - startPos.x);
    float dy = (endPos.y - startPos.y);
    
    float len = sqrtf(dx * dx + dy * dy);
    
    if (len == 0)
        return;
    
    dx /= len;
    dy /= len;
    
    pointsCount = MAX(2, (int)(len / kSegmentLength));
    //printf("%i %f \n", pointsCount, len);
    
    
    points = (CGPoint*)malloc(sizeof(CGPoint) * pointsCount);
    points[0] = startPos;
    points[pointsCount - 1] = endPos;
    
    
    
    for (int i = 1; i < pointsCount - 1; i++) {
        
        float t = (i + ((float)rand() / RAND_MAX * 2 - 1) * kMiddlePointOffsetMul) * len / (pointsCount - 1);
        points[i].x = startPos.x + t * dx;
        points[i].y = startPos.y + t * dy;
        
        t = ((float)rand() / RAND_MAX * 2 - 1) * kArcWidth;
        
        points[i].x += t * -dy;
        points[i].y += t * dx;
    }
    
    colors = (unsigned char*)malloc(sizeof(unsigned char) * pointsCount * 4);
}

- (void)destroy {
    
    if (points) {
        
        free(points);
        free(colors);
        
        points = NULL;
        colors = NULL;
    }
}


@end
