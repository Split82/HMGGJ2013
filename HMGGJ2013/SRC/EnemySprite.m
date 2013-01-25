//
//  Enemy.m
//  HMGGJ2013
//
//  Created by Loki on 1/25/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "EnemySprite.h"
#import "GameDataNameDefinitions.h"

#define WALKING_SPEED 10.0f
#define WALKING_BORDER_OFFSET 5.0f
#define WALKING_PLANE_Y_POS 10.0f

@interface EnemySprite() {
 
    float direction;
    
    NSMutableArray *walkingAnimSpriteFrames;
    NSMutableArray *climbingAnimSpriteFrames;
    
    int animFrameIndex;
    
    float animTime;
    float moveTime;
}

@end


@implementation EnemySprite

@synthesize type, state;

-(id) initWithType:(EnemyType)_type {
    
    if ([self initWithSpriteFrameName:kPlaceholderTextureFrameName]) {
        
        self.type = type;
        self.state = kEnemyStateWalking;
        
        animFrameIndex = 0;
        animTime = 0;
        moveTime = 0;
        
        if (rand() % 2) {
            
            direction = 1;
            
            [self setPosition:CGPointMake(-WALKING_BORDER_OFFSET, WALKING_PLANE_Y_POS)];
        }
        else {
            
            direction = -1;
            
            [self setPosition:CGPointMake([CCDirector sharedDirector].winSize.width + WALKING_BORDER_OFFSET, WALKING_PLANE_Y_POS)];
        }
        
        NSArray *walkingAnimeSpriteFrameNames = @[
            kPlaceholderTextureFrameName,
            kPlaceholderTextureFrameName,
            kPlaceholderTextureFrameName,
            kPlaceholderTextureFrameName
        ];
        
        for (NSString *spriteFrameName in walkingAnimeSpriteFrameNames) {
            
            [walkingAnimSpriteFrames addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:spriteFrameName]];            
        }
        
        NSArray *climbingAnimeSpriteFrameNames = @[
            kPlaceholderTextureFrameName,
            kPlaceholderTextureFrameName,
            kPlaceholderTextureFrameName,
            kPlaceholderTextureFrameName
        ];
        
        for (NSString *spriteFrameName in climbingAnimeSpriteFrameNames) {
            
            [climbingAnimSpriteFrames addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:spriteFrameName]];
        }
    }
    
    return self;
}


- (void) update:(ccTime) time {
    
    switch (state) {
            
        case kEnemyStateWalking: {
        }
        case kEnemyStateClimbing: {
        }
        case kEnemyStateFalling: {
        }
    }
}


@end
