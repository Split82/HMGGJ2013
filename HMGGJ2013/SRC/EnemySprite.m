//
//  Enemy.m
//  HMGGJ2013
//
//  Created by Loki on 1/25/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "EnemySprite.h"
#import "GameDataNameDefinitions.h"

#define WALKING_MOVEMENT_OFFSET 1.0f
#define WALKING_MOVEMENT_DELAY 0.1f
#define WALKING_ANIM_DELAY 0.2f
#define WALKING_BORDER_OFFSET 5.0f
#define WALKING_PLANE_Y_POS 10.0f

#define CLIMBING_MOVEMENT_OFFSET 1.0f
#define CLIMBING_MOVEMENT_DELAY 0.1f
#define CLIMBING_ANIM_DELAY 0.2f

#define WALL_HEIGHT 400.0f


@interface EnemySprite() {
 
    float direction;
    
    NSMutableArray *walkingAnimSpriteFrames;
    NSMutableArray *climbingAnimSpriteFrames;
    
    int animFrameIndex;
    
    float animTime;
    float moveTime;
    
    float climbXPos;
    
    BOOL killed;
}

@end


@implementation EnemySprite

@synthesize type, state;

-(id) initWithType:(EnemyType)_type {
    
    if ([self initWithSpriteFrameName:kPlaceholderTextureFrameName]) {
        
        self.anchorPoint = ccp(0.5, 0.5);
        self.type = type;
        self.state = kEnemyStateWalking;
        
        animFrameIndex = 0;
        animTime = 0;
        moveTime = 0;
        
        climbXPos = (float)rand() / RAND_MAX * [CCDirector sharedDirector].winSize.width;
        
        if (rand() % 2) {
            
            direction = 1;
            
            self.position = CGPointMake(-WALKING_BORDER_OFFSET, WALKING_PLANE_Y_POS);
        }
        else {
            
            direction = -1;
            self.flipX = YES;
            
            self.position = CGPointMake([CCDirector sharedDirector].winSize.width + WALKING_BORDER_OFFSET, WALKING_PLANE_Y_POS);
        }
        
        NSArray *walkingAnimeSpriteFrameNames = @[
            kPlaceholderTextureFrameName,
            kPlaceholderTextureFrameName,
            kPlaceholderTextureFrameName,
            kPlaceholderTextureFrameName
        ];
        
        walkingAnimSpriteFrames = [[NSMutableArray alloc] initWithCapacity:[walkingAnimeSpriteFrameNames count]];
        
        for (NSString *spriteFrameName in walkingAnimeSpriteFrameNames) {
            
            [walkingAnimSpriteFrames addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:spriteFrameName]];            
        }
        
        NSArray *climbingAnimeSpriteFrameNames = @[
            kPlaceholderTextureFrameName,
            kPlaceholderTextureFrameName,
            kPlaceholderTextureFrameName,
            kPlaceholderTextureFrameName
        ];
        
        climbingAnimSpriteFrames = [[NSMutableArray alloc] initWithCapacity:[climbingAnimeSpriteFrameNames count]];
        
        for (NSString *spriteFrameName in climbingAnimeSpriteFrameNames) {
            
            [climbingAnimSpriteFrames addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:spriteFrameName]];
        }
        
        [self setDisplayFrame:walkingAnimSpriteFrames[0]];
    }
    
    return self;
}


- (void) calc:(ccTime) time {
    
    animTime += time;
    moveTime += time;
    
    switch (state) {
            
        case kEnemyStateWalking: {
            
            if (direction == -1 && position_.x < WALKING_BORDER_OFFSET) {
                
                self.flipX = FALSE;
                direction = 1;
            }
            else if (direction == 1 && position_.x > [CCDirector sharedDirector].winSize.width + WALKING_BORDER_OFFSET) {
                
                self.flipX = TRUE;
                direction = -1;
            }
            
            if (moveTime > WALKING_MOVEMENT_DELAY) {
                
                CGPoint newPos = self.position;
                newPos.x += (int)(animTime / WALKING_ANIM_DELAY) * direction * WALKING_MOVEMENT_OFFSET;
                
                if ((newPos.x <= climbXPos && self.position.x > climbXPos) || (newPos.x >= climbXPos && self.position.x < climbXPos)) {
                    
                    state = kEnemyStateClimbing;
                    animFrameIndex = 0;
                }
                
                self.position = newPos;

                moveTime = moveTime - (int)(moveTime / WALKING_MOVEMENT_DELAY) * WALKING_MOVEMENT_DELAY;
            }
            
            if (animTime > WALKING_ANIM_DELAY) {
                
                animFrameIndex += (int)(animTime / WALKING_ANIM_DELAY);
                animFrameIndex = animFrameIndex % [walkingAnimSpriteFrames count];
                
                animTime = animTime - (int)(animTime / WALKING_ANIM_DELAY) * WALKING_ANIM_DELAY;
            }
            
            [self setDisplayFrame:walkingAnimSpriteFrames[animFrameIndex]];
            
            break;
        }
        case kEnemyStateClimbing: {
            
            if (position_.y > WALL_HEIGHT) {
                
                [_delegate enemyDidClimbWall:self];
                return;
            }
            if (moveTime > CLIMBING_MOVEMENT_DELAY) {
                
                CGPoint newPos = self.position;
                newPos.y += (int)(animTime / CLIMBING_MOVEMENT_DELAY) * CLIMBING_MOVEMENT_OFFSET;
                
                self.position = newPos;
                
                moveTime = moveTime - (int)(moveTime / CLIMBING_MOVEMENT_DELAY) * CLIMBING_MOVEMENT_DELAY;
            }
            
            if (animTime > CLIMBING_ANIM_DELAY) {
                
                animFrameIndex += (int)(animTime / CLIMBING_ANIM_DELAY);
                animFrameIndex = animFrameIndex % [climbingAnimSpriteFrames count];
                
                animTime = animTime - (int)(animTime / CLIMBING_ANIM_DELAY) * CLIMBING_ANIM_DELAY;
            }
            
            [self setDisplayFrame:climbingAnimSpriteFrames[animFrameIndex]];
            
            break;
        }
        case kEnemyStateFalling: {
            
            break;
        }
    }
}


@end
