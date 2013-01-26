//
//  Enemy.m
//  HMGGJ2013
//
//  Created by Loki on 1/25/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "EnemySprite.h"
#import "GameDataNameDefinitions.h"
#import "MainGameScene.h"
#import "SpriteTextureFrameInfo.h"

#define WALKING_MOVEMENT_OFFSET 2.0f
#define WALKING_ANIM_DELAY (1/30.0f)
#define WALKING_BORDER_OFFSET 5.0f

#define CLIMBING_MOVEMENT_OFFSET 1.0f
#define CLIMBING_MOVEMENT_DELAY (1/60.0f)
#define CLIMBING_ANIM_DELAY 0.2f
#define CLIMBING_BORDER_OFFSET 40.0f

#define FALLING_ACCEL -300.0f
#define FALLING_HORIZ_DECCEL 100.0f
#define FALLING_ANIM_DELAY 0.2f

#define WALL_HEIGHT 400.0f

static NSMutableArray *swiperWalkingAnimSpriteFrames = nil;
static NSMutableArray *swiperClimbingAnimSpriteFrames = nil;
static NSMutableArray *swiperFallingAnimSpriteFrames = nil;

static NSMutableArray *tapperWalkingAnimSpriteFrames = nil;
static NSMutableArray *tapperClimbingAnimSpriteFrames = nil;
static NSMutableArray *tapperFallingAnimSpriteFrames = nil;


@interface EnemySprite() {
 
    float direction;

    NSMutableArray *walkingAnimSpriteFrames;
    NSMutableArray *climbingAnimSpriteFrames;
    NSMutableArray *fallingAnimSpriteFrames;
    
    int animFrameIndex;
    
    float animTime;
    float moveTime;
    
    float climbXPos;
    float verticalVel;
    float horizontalVel;
    
    BOOL killed;
}

@end


@implementation EnemySprite

@synthesize type, state;

-(id) initWithType:(EnemyType)_type {
    
    if ([self initWithSpriteFrameName:kPlaceholderTextureFrameName]) {
        
        self.anchorPoint = ccp(0.5, 0.5);
        self.type = _type;
        self.state = kEnemyStateWalking;
        self.scale = [UIScreen mainScreen].scale * 2;
        
        animFrameIndex = 0;
        animTime = 0;
        moveTime = 0;
        
        climbXPos = CLIMBING_BORDER_OFFSET + (float)rand() / RAND_MAX * ([CCDirector sharedDirector].winSize.width - 2 * CLIMBING_BORDER_OFFSET);
        

        if (!swiperWalkingAnimSpriteFrames) {
            
            
            NSArray *tapperWalkingAnimSpriteFrameNames = @[
            @"monsterBigMove1.png",
            @"monsterBigMove2.png",
            @"monsterBigMove3.png",
            @"monsterBigMove4.png",
            @"monsterBigMove5.png",
            @"monsterBigMove6.png",
            @"monsterBigMove7.png",
            @"monsterBigMove8.png",
            @"monsterBigMove9.png",
            @"monsterBigMove10.png",
            @"monsterBigMove11.png",
            @"monsterBigMove12.png",
            ];
            
            CGPoint tapperWalkingAnimSpriteOffsets[12];
            tapperWalkingAnimSpriteOffsets[0] = CGPointMake(0, 0);
            tapperWalkingAnimSpriteOffsets[1] = CGPointMake(0, 0);
            tapperWalkingAnimSpriteOffsets[2] = CGPointMake(0, 0);
            tapperWalkingAnimSpriteOffsets[3] = CGPointMake(0, 0);
            tapperWalkingAnimSpriteOffsets[4] = CGPointMake(0, 0);
            tapperWalkingAnimSpriteOffsets[5] = CGPointMake(0, 0);
            tapperWalkingAnimSpriteOffsets[6] = CGPointMake(0, 0);
            tapperWalkingAnimSpriteOffsets[7] = CGPointMake(0, 0);
            tapperWalkingAnimSpriteOffsets[8] = CGPointMake(0, 0);
            tapperWalkingAnimSpriteOffsets[9] = CGPointMake(0, 0);
            tapperWalkingAnimSpriteOffsets[9] = CGPointMake(0, 0);
            
            NSArray *tapperClimbingAnimSpriteFrameNames = @[
            @"BigClimb1.png",
            @"BigClimb2.png",
            @"BigClimb3.png",
            @"BigClimb4.png",
            @"BigClimb5.png",
            @"BigClimb6.png",
            @"BigClimb7.png",
            ];
            
            NSArray *tapperFallingAnimSpriteFrameNames = @[
            @"BigClimb1.png",
            ];
            
            NSArray *swiperWalkingAnimSpriteFrameNames = @[
            @"TallMove1.png",
            @"TallMove2.png",
            @"TallMove3.png",
            @"TallMove4.png",
            @"TallMove5.png",
            @"TallMove6.png",
            @"TallMove7.png",
            @"TallMove8.png",
            ];
            
            NSArray *swiperClimbingAnimSpriteFrameNames = @[
            @"TallMove1.png",
            @"TallMove2.png",
            @"TallMove3.png",
            @"TallMove4.png",
            @"TallMove5.png",
            @"TallMove6.png",
            @"TallMove7.png",
            @"TallMove8.png",
            ];
            
            NSArray *swiperFallingAnimSpriteFrameNames = @[
            @"TallMove1.png",
            @"TallMove2.png",
            @"TallMove3.png",
            @"TallMove4.png",
            @"TallMove5.png",
            @"TallMove6.png",
            @"TallMove7.png",
            @"TallMove8.png",
            ];
            
            // tapper
            tapperWalkingAnimSpriteFrames = [[NSMutableArray alloc] initWithCapacity:[tapperWalkingAnimSpriteFrameNames count]];
            
            for (NSString *spriteFrameName in tapperWalkingAnimSpriteFrameNames) {
                
                [tapperWalkingAnimSpriteFrames addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:spriteFrameName]];
            }
            
            tapperClimbingAnimSpriteFrames = [[NSMutableArray alloc] initWithCapacity:[tapperClimbingAnimSpriteFrameNames count]];
            
            for (NSString *spriteFrameName in tapperClimbingAnimSpriteFrameNames) {
                
                [tapperClimbingAnimSpriteFrames addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:spriteFrameName]];
            }
            
            tapperFallingAnimSpriteFrames = [[NSMutableArray alloc] initWithCapacity:[tapperFallingAnimSpriteFrameNames count]];
            
            for (NSString *spriteFrameName in tapperFallingAnimSpriteFrameNames) {
                
                [tapperFallingAnimSpriteFrames addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:spriteFrameName]];
            }
            
            // swiper
            swiperWalkingAnimSpriteFrames = [[NSMutableArray alloc] initWithCapacity:[swiperWalkingAnimSpriteFrameNames count]];
            
            for (NSString *spriteFrameName in swiperWalkingAnimSpriteFrameNames) {
                
                [swiperWalkingAnimSpriteFrames addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:spriteFrameName]];
            }
            
            swiperClimbingAnimSpriteFrames = [[NSMutableArray alloc] initWithCapacity:[swiperClimbingAnimSpriteFrameNames count]];
            
            for (NSString *spriteFrameName in swiperClimbingAnimSpriteFrameNames) {
                
                [swiperClimbingAnimSpriteFrames addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:spriteFrameName]];
            }
            
            swiperFallingAnimSpriteFrames = [[NSMutableArray alloc] initWithCapacity:[swiperFallingAnimSpriteFrameNames count]];
            
            for (NSString *spriteFrameName in swiperFallingAnimSpriteFrameNames) {
                
                [swiperFallingAnimSpriteFrames addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:spriteFrameName]];
            }
            
        }
        
        
        if (rand() % 2) {
            
            direction = 1;
            
            self.position = CGPointMake(-WALKING_BORDER_OFFSET, GROUND_Y);
        }
        else {
            
            direction = -1;
            self.flipX = YES;
            
            self.position = CGPointMake([CCDirector sharedDirector].winSize.width + WALKING_BORDER_OFFSET, GROUND_Y);
        }
        
        
        if (type == kEnemyTypeSwipe) {
            
            walkingAnimSpriteFrames = swiperWalkingAnimSpriteFrames;
            climbingAnimSpriteFrames = swiperClimbingAnimSpriteFrames;
            fallingAnimSpriteFrames = swiperFallingAnimSpriteFrames;
        }
        else {
            
            walkingAnimSpriteFrames = tapperWalkingAnimSpriteFrames;
            climbingAnimSpriteFrames = tapperClimbingAnimSpriteFrames;
            fallingAnimSpriteFrames = tapperFallingAnimSpriteFrames;
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
            

            if (animTime > WALKING_ANIM_DELAY) {
                
                
                CGPoint newPos = self.position;
                newPos.x += (int)(animTime / WALKING_ANIM_DELAY) * direction * WALKING_MOVEMENT_OFFSET;
                
                if ((newPos.x <= climbXPos && self.position.x > climbXPos) || (newPos.x >= climbXPos && self.position.x < climbXPos)) {
                    
                    state = kEnemyStateClimbing;
                    animFrameIndex = 0;
                    moveTime = 0;
                    
                    return;
                }
                
                self.position = newPos;
                
                animFrameIndex += (int)(animTime / WALKING_ANIM_DELAY);
                animFrameIndex = animFrameIndex % [walkingAnimSpriteFrames count];
                
                animTime = animTime - (int)(animTime / WALKING_ANIM_DELAY) * WALKING_ANIM_DELAY;
                
            }
            
            [self setDisplayFrame:walkingAnimSpriteFrames[animFrameIndex]];
            
            break;
        }
        case kEnemyStateClimbing: {
            
            if (position_.y > WALL_HEIGHT + GROUND_Y) {
                
                [_delegate enemyDidClimbWall:self];
                return;
            }
            if (moveTime > CLIMBING_MOVEMENT_DELAY) {
                
                CGPoint newPos = self.position;
                newPos.y += (int)(moveTime / CLIMBING_MOVEMENT_DELAY) * CLIMBING_MOVEMENT_OFFSET;
                
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
            
            
            if (position_.y < GROUND_Y) {
                
                position_.y = GROUND_Y;
                self.position = position_;

                if (position_.x < CLIMBING_BORDER_OFFSET) {
                    
                    state = kEnemyStateWalking;
                    
                    direction = 1;
                    self.flipX = NO;
                    
                    climbXPos = CLIMBING_BORDER_OFFSET + (float)rand() / RAND_MAX * CLIMBING_BORDER_OFFSET;                    
                }
                else if (position_.x > [CCDirector sharedDirector].winSize.width - CLIMBING_BORDER_OFFSET) {
                
                    state = kEnemyStateWalking;
                    
                    climbXPos = [CCDirector sharedDirector].winSize.width - CLIMBING_BORDER_OFFSET - (float)rand() / RAND_MAX * CLIMBING_BORDER_OFFSET;
                    
                    direction = -1;
                    self.flipX = YES;
                }
                else {
                    

                    state = kEnemyStateClimbing;
                }
                
                animFrameIndex = 0;
                moveTime = 0;
                return;
            }
            
            position_.y += verticalVel * time;
            verticalVel += FALLING_ACCEL * time;
            
            position_.x += horizontalVel * time * direction;
            horizontalVel -= FALLING_HORIZ_DECCEL * time;
            if (horizontalVel < 0) {
                
                horizontalVel = 0;
            }
            
            self.position = position_;
            
            if (animTime > FALLING_ANIM_DELAY) {
                
                animFrameIndex += (int)(animTime / FALLING_ANIM_DELAY);
                animFrameIndex = animFrameIndex % [fallingAnimSpriteFrames count];
                
                animTime = animTime - (int)(animTime / FALLING_ANIM_DELAY) * FALLING_ANIM_DELAY;
            }
            
            [self setDisplayFrame:fallingAnimSpriteFrames[animFrameIndex]];
            break;
        }
    }
}

-(void) throwFromWall {
    
    if (state != kEnemyStateClimbing) {
        
        return;
    }
    
    state = kEnemyStateFalling;
    animFrameIndex = 0;
    moveTime = 0;
    verticalVel = 100;
    horizontalVel = (float)rand() / RAND_MAX * 50 + 50;
    
}

@end
