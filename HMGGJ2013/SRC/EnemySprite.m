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


#define ENEMY_HALF_WIDTH 20.0f

#define WALKING_MOVEMENT_OFFSET 2.0f
#define WALKING_ANIM_DELAY (1 / 30.0f)
#define WALKING_BORDER_OFFSET (ENEMY_HALF_WIDTH * 3)

#define CLIMBING_MOVEMENT_OFFSET 4.0f
#define CLIMBING_ANIM_DELAY (1 / 30.0f * 4)
#define CLIMBING_BORDER_OFFSET 30.0f

#define FALLING_ACCEL -300.0f
#define FALLING_HORIZ_DECCEL 100.0f
#define FALLING_ANIM_DELAY 0.2f

#define SLEEPING_ANIM_DELAY (1 / 30.0f)

#define CROSSING_ANIM_DELAY (1 / 30.0f * 4)

#define WALL_HEIGHT 356.0f

#define MIN_FALLING_SPPEED_FOR_SLEEP 200.0f

static NSMutableArray *swiperWalkingAnimSpriteFrames = nil;
static NSMutableArray *swiperClimbingAnimSpriteFrames = nil;
static NSMutableArray *swiperFallingAnimSpriteFrames = nil;
static NSMutableArray *swiperCrossingAnimSpriteFrames = nil;
static NSMutableArray *swiperSleepingAnimSpriteFrames = nil;

static NSMutableArray *tapperWalkingAnimSpriteFrames = nil;
static NSMutableArray *tapperClimbingAnimSpriteFrames = nil;
static NSMutableArray *tapperFallingAnimSpriteFrames = nil;
static NSMutableArray *tapperCrossingAnimSpriteFrames = nil;
static NSMutableArray *tapperSleepingAnimSpriteFrames = nil;

@interface EnemySprite() {
 
    float direction;

    NSMutableArray *walkingAnimSpriteFrames;
    NSMutableArray *climbingAnimSpriteFrames;
    NSMutableArray *fallingAnimSpriteFrames;
    NSMutableArray *crossingAnimSpriteFrames;
    NSMutableArray *sleepingAnimSpriteFrames;
    
    int animFrameIndex;
    
    float animTime;
    float moveTime;
    
    float climbXPos;
    float verticalVel;
    float horizontalVel;
    
    BOOL killed;
    BOOL wakingUp;
    
    CGPoint spritePos;
    
    float sleepTime;
    float wakingAnimeDelayMul;
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
        wakingUp = FALSE;
        
        climbXPos = CLIMBING_BORDER_OFFSET + (float)rand() / RAND_MAX * ([CCDirector sharedDirector].winSize.width - 2 * CLIMBING_BORDER_OFFSET - ENEMY_HALF_WIDTH * 2);
        

        if (!swiperWalkingAnimSpriteFrames) {
            
            // tapper
            
            
            //walk
            tapperWalkingAnimSpriteFrames = [[NSMutableArray alloc] initWithCapacity:12];
            
            [tapperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"monsterBigMove1.png" offset:CGPointMake(0, 0)]];
            [tapperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"monsterBigMove2.png" offset:CGPointMake(0, 0)]];
            [tapperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"monsterBigMove3.png" offset:CGPointMake(0, 0)]];
            [tapperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"monsterBigMove4.png" offset:CGPointMake(0, 0)]];
            [tapperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"monsterBigMove5.png" offset:CGPointMake(0, 0)]];
            [tapperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"monsterBigMove6.png" offset:CGPointMake(0, 0)]];
            [tapperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"monsterBigMove7.png" offset:CGPointMake(0, 0)]];
            [tapperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"monsterBigMove8.png" offset:CGPointMake(0, 0)]];
            [tapperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"monsterBigMove9.png" offset:CGPointMake(0, 0)]];
            [tapperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"monsterBigMove10.png" offset:CGPointMake(0, 0)]];
            [tapperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"monsterBigMove11.png" offset:CGPointMake(0, 0)]];
            [tapperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"monsterBigMove12.png" offset:CGPointMake(0, 0)]];
            
            // climb
            tapperClimbingAnimSpriteFrames = [[NSMutableArray alloc] initWithCapacity:12];
            
            [tapperClimbingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"BigClimb1.png" offset:CGPointMake(1, 0)]];
            [tapperClimbingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"BigClimb2.png" offset:CGPointMake(0, 0)]];
            [tapperClimbingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"BigClimb3.png" offset:CGPointMake(0, 0)]];
            [tapperClimbingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"BigClimb4.png" offset:CGPointMake(0, 0)]];
            [tapperClimbingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"BigClimb5.png" offset:CGPointMake(0, 0)]];
            [tapperClimbingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"BigClimb6.png" offset:CGPointMake(0, 0)]];
            [tapperClimbingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"BigClimb7.png" offset:CGPointMake(1, 0)]];
            
            // fall
            tapperFallingAnimSpriteFrames = [[NSMutableArray alloc] initWithCapacity:12];

            [tapperFallingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"bigFront.png" offset:CGPointMake(0, 0)]];
            [tapperFallingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"bigWaterFall.png" offset:CGPointMake(0, 0)]];
            
            // sleep
            tapperSleepingAnimSpriteFrames = [[NSMutableArray alloc] initWithCapacity:12];
            
            [tapperSleepingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"bigFront.png" offset:CGPointMake(0, 0)]];
            [tapperSleepingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"bigFall1.png" offset:CGPointMake(0, 0)]];
            [tapperSleepingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"bigFall2.png" offset:CGPointMake(0, 0)]];
            [tapperSleepingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"bigFall3.png" offset:CGPointMake(0, 0)]];
            [tapperSleepingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"bigFall4.png" offset:CGPointMake(0, 0)]];

            // cross
            tapperCrossingAnimSpriteFrames = [[NSMutableArray alloc] initWithCapacity:12];
            
            [tapperCrossingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"BigClimbTop.png" offset:CGPointMake(0, 5)]];
            [tapperCrossingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"BigClimbTop2.png" offset:CGPointMake(0, 8)]];
            
            
            //swiper
            
            // walk
            swiperWalkingAnimSpriteFrames = [[NSMutableArray alloc] initWithCapacity:12];
            
            [swiperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"TallMove1.png" offset:CGPointMake(0, 0)]];
            [swiperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"TallMove2.png" offset:CGPointMake(0, 0)]];
            [swiperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"TallMove3.png" offset:CGPointMake(0, 0)]];
            [swiperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"TallMove4.png" offset:CGPointMake(0, 0)]];
            [swiperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"TallMove5.png" offset:CGPointMake(0, 0)]];
            [swiperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"TallMove6.png" offset:CGPointMake(0, 0)]];
            [swiperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"TallMove7.png" offset:CGPointMake(0, 0)]];
            [swiperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"TallMove8.png" offset:CGPointMake(0, 0)]];
            
            // climb
            swiperClimbingAnimSpriteFrames = [[NSMutableArray alloc] initWithCapacity:12];
            
            [swiperClimbingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"TallClimb1.png" offset:CGPointMake(1, 0)]];
            [swiperClimbingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"TallClimb2.png" offset:CGPointMake(0, 0)]];
            [swiperClimbingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"TallClimb3.png" offset:CGPointMake(0, 0)]];
            [swiperClimbingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"TallClimb4.png" offset:CGPointMake(0, 0)]];
            [swiperClimbingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"TallClimb5.png" offset:CGPointMake(0, 0)]];
            [swiperClimbingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"TallClimb6.png" offset:CGPointMake(0, 0)]];

            // fall
            swiperFallingAnimSpriteFrames = [[NSMutableArray alloc] initWithCapacity:12];
            
            [swiperFallingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"tallFront.png" offset:CGPointMake(0, 0)]];
            [swiperFallingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"tallWaterFall.png" offset:CGPointMake(0, 0)]];
            
            // sleep
            swiperSleepingAnimSpriteFrames = [[NSMutableArray alloc] initWithCapacity:12];
            
            [swiperSleepingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"tallFront.png" offset:CGPointMake(0, 0)]];
            [swiperSleepingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"tallFall1.png" offset:CGPointMake(0, 0)]];
            [swiperSleepingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"tallFall2.png" offset:CGPointMake(0, 0)]];
            [swiperSleepingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"tallFall3.png" offset:CGPointMake(0, 0)]];
            [swiperSleepingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"tallFall4.png" offset:CGPointMake(0, 0)]];
            
            // cross
            swiperCrossingAnimSpriteFrames = [[NSMutableArray alloc] initWithCapacity:12];
            
            [swiperCrossingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"TallClimbTop.png" offset:CGPointMake(0, 2)]];
            [swiperCrossingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"TallClimbTop2.png" offset:CGPointMake(0, 8)]];
        }
        
        
        if (rand() % 2) {
            
            direction = 1;
            
            spritePos = CGPointMake(-WALKING_BORDER_OFFSET, GROUND_Y);
        }
        else {
            
            direction = -1;
            self.flipX = YES;
            
            spritePos = CGPointMake([CCDirector sharedDirector].winSize.width + WALKING_BORDER_OFFSET, GROUND_Y);
        }
        
        
        if (type == kEnemyTypeSwipe) {
            
            walkingAnimSpriteFrames = swiperWalkingAnimSpriteFrames;
            climbingAnimSpriteFrames = swiperClimbingAnimSpriteFrames;
            fallingAnimSpriteFrames = swiperFallingAnimSpriteFrames;
            sleepingAnimSpriteFrames = swiperSleepingAnimSpriteFrames;
            crossingAnimSpriteFrames = swiperCrossingAnimSpriteFrames;
        }
        else {
            
            walkingAnimSpriteFrames = tapperWalkingAnimSpriteFrames;
            climbingAnimSpriteFrames = tapperClimbingAnimSpriteFrames;
            fallingAnimSpriteFrames = tapperFallingAnimSpriteFrames;
            sleepingAnimSpriteFrames = tapperSleepingAnimSpriteFrames;
            crossingAnimSpriteFrames = tapperCrossingAnimSpriteFrames;
        }
        

        [self updateSpritePos];
        
    }
    
    return self;
}


- (void) calc:(ccTime) time {
    
    animTime += time;
    moveTime += time;
    
    switch (state) {
            
        case kEnemyStateWalking: {
            
            if (direction == -1 && spritePos.x < -WALKING_BORDER_OFFSET) {
                
                self.flipX = FALSE;
                direction = 1;
            }
            else if (direction == 1 && spritePos.x > [CCDirector sharedDirector].winSize.width + WALKING_BORDER_OFFSET - ENEMY_HALF_WIDTH * 2) {
                
                self.flipX = TRUE;
                direction = -1;
            }
            

            if (animTime > WALKING_ANIM_DELAY) {
                
                CGPoint newSpritePos = spritePos;
                newSpritePos.x += (int)(animTime / WALKING_ANIM_DELAY) * direction * WALKING_MOVEMENT_OFFSET;
                
                if ((newSpritePos.x <= climbXPos && spritePos.x > climbXPos) || (newSpritePos.x >= climbXPos && spritePos.x < climbXPos)) {
                    
                    state = kEnemyStateClimbing;
                    animFrameIndex = 0;
                    moveTime = 0;
                    animTime = 0;
                    
                    [self updateSpritePos];
                    
                    return;
                }
                
                spritePos = newSpritePos;
                
                animFrameIndex += (int)(animTime / WALKING_ANIM_DELAY);
                animFrameIndex = animFrameIndex % [walkingAnimSpriteFrames count];
                
                animTime = animTime - (int)(animTime / WALKING_ANIM_DELAY) * WALKING_ANIM_DELAY;
                
                [self updateSpritePos];
            }
            
            break;
        }
        case kEnemyStateClimbing: {
            
            if (spritePos.y > WALL_HEIGHT + GROUND_Y) {
                
                animFrameIndex = 0;
                moveTime = 0;
                animTime = 0;
                
                state = kEnemyStateCrossing;
                
                [self updateSpritePos];
                return;
            }
            if (animTime > CLIMBING_ANIM_DELAY) {
                
                CGPoint newSpritePos = spritePos;
                newSpritePos.y += (int)(animTime / CLIMBING_ANIM_DELAY) * CLIMBING_MOVEMENT_OFFSET;
                
                
                animFrameIndex += (int)(animTime / CLIMBING_ANIM_DELAY);
                animFrameIndex = animFrameIndex % [climbingAnimSpriteFrames count];
                
                animTime = animTime - (int)(animTime / CLIMBING_ANIM_DELAY) * CLIMBING_ANIM_DELAY;

                
                spritePos = newSpritePos;
                
                [self updateSpritePos];
            }
            
            break;
        }
        case kEnemyStateFallingInto:
        case kEnemyStateFalling: {
            
            if ((state == kEnemyStateFalling) && (spritePos.y < GROUND_Y)) {
                
                spritePos.y = GROUND_Y;

                wakingUp = NO;
                wakingAnimeDelayMul =  400.0f / fabs(verticalVel);
                if (verticalVel < -MIN_FALLING_SPPEED_FOR_SLEEP) {
                    
                    sleepTime = MIN(fabs(verticalVel + MIN_FALLING_SPPEED_FOR_SLEEP) * 0.006, 3);
                }
                else {
                    
                    sleepTime = 0;
                }
                
                animFrameIndex = 1; // skip first front facing frame
                moveTime = 0;
                animTime = 0;
                
                state = kEnemyStateSleeping;
                
                [self updateSpritePos];
                return;
            }
            else if ((state == kEnemyStateFallingInto) && (spritePos.y < [_delegate slimeSurfacePosY])) {
                
                [_delegate enemyDidClimbWall:self];
                return;
            }
            
            spritePos.y += verticalVel * time;
            verticalVel += FALLING_ACCEL * time;
            
            spritePos.x += horizontalVel * time * direction;
            horizontalVel -= FALLING_HORIZ_DECCEL * time;
            if (horizontalVel < 0) {
                
                horizontalVel = 0;
            }
            
            if (animTime > FALLING_ANIM_DELAY) {
                
                animFrameIndex += (int)(animTime / FALLING_ANIM_DELAY) * 2; // frames are interlaced (outer/inner falling)
                animFrameIndex = animFrameIndex % [fallingAnimSpriteFrames count];
                
                animTime = animTime - (int)(animTime / FALLING_ANIM_DELAY) * FALLING_ANIM_DELAY;
            }
            
            [self updateSpritePos];
            break;
        }
        case kEnemyStateSleeping: {
            
            // sleeping
            if (animFrameIndex == [sleepingAnimSpriteFrames count] - 1) {
                
                if (animTime > sleepTime) {
                    
                    wakingUp = YES;
                    wakingAnimeDelayMul = 4;

                    animTime -= sleepTime;
                    animFrameIndex = [sleepingAnimSpriteFrames count] - 2;
                }
            }
            else {
                
                if (animTime > SLEEPING_ANIM_DELAY * wakingAnimeDelayMul) {
                    
                    // amnimate waking up/sleeping down
                    animFrameIndex += (wakingUp ? -1 : 1) * (int)(animTime / (SLEEPING_ANIM_DELAY * wakingAnimeDelayMul));
                    
                    animTime = animTime - (int)(animTime / (SLEEPING_ANIM_DELAY * wakingAnimeDelayMul)) * SLEEPING_ANIM_DELAY * wakingAnimeDelayMul;
                    
                    
                    // fell on ground
                    if (animFrameIndex >= (int)[sleepingAnimSpriteFrames count]) {
                        
                        animFrameIndex = [sleepingAnimSpriteFrames count] - 1;
                    }
                    // fully waked up
                    else if (animFrameIndex < 0) {
                        
                        // walk to visible area
                        if (spritePos.x < CLIMBING_BORDER_OFFSET) {
                            
                            state = kEnemyStateWalking;
                            
                            direction = 1;
                            self.flipX = NO;
                            
                            climbXPos = CLIMBING_BORDER_OFFSET + (float)rand() / RAND_MAX * CLIMBING_BORDER_OFFSET;
                        }
                        else if (spritePos.x > [CCDirector sharedDirector].winSize.width - CLIMBING_BORDER_OFFSET - ENEMY_HALF_WIDTH * 2) {
                            
                            state = kEnemyStateWalking;
                            
                            climbXPos = [CCDirector sharedDirector].winSize.width - CLIMBING_BORDER_OFFSET - (float)rand() / RAND_MAX * CLIMBING_BORDER_OFFSET - ENEMY_HALF_WIDTH * 2;
                            
                            direction = -1;
                            self.flipX = YES;
                        }
                        // climb
                        else {
                            
                            state = kEnemyStateClimbing;
                        }
                        
                        animFrameIndex = 0;
                        animTime = 0;
                        moveTime = 0;
                        
                        [self updateSpritePos];
                        return;
                    }
                    
                    
                    [self updateSpritePos];
                }
            }
            
            break;
        }
        case kEnemyStateCrossing: {
            
            if (animTime > CROSSING_ANIM_DELAY) {
                
                animFrameIndex += (int)(animTime / CROSSING_ANIM_DELAY);
                
                if (animFrameIndex >= [crossingAnimSpriteFrames count]) {
                    
                    animTime = 0;
                    moveTime = 0;
                    animFrameIndex = 1; // odd frames

                    verticalVel = 0;
                    horizontalVel = 0;
                    
                    state = kEnemyStateFallingInto;
                    
                    [[self parent] reorderChild:self z:19];
                    
                    [self updateSpritePos];
                    return;
                }
                
                animTime = animTime - (int)(animTime / CROSSING_ANIM_DELAY) * CROSSING_ANIM_DELAY;
                
                [self updateSpritePos];
            }
            
            break;
        }
            
    }
}

-(void) throwFromWall {
    
    if (state != kEnemyStateClimbing && state != kEnemyStateCrossing) {
        
        return;
    }
    
    state = kEnemyStateFalling;
    animFrameIndex = 0;
    moveTime = 0;
    animTime = 0;
    verticalVel = 100;
    horizontalVel = (float)rand() / RAND_MAX * 50 + 50;
    
    [self updateSpritePos];
    
}

- (void) updateSpritePos {
    

    NSArray *frames;
    if (state == kEnemyStateWalking) {
        
        frames = walkingAnimSpriteFrames;
    }
    else if (state == kEnemyStateClimbing) {
        
        frames = climbingAnimSpriteFrames;
    }
    else if (state == kEnemyStateFalling || state == kEnemyStateFallingInto) {
        
        frames = fallingAnimSpriteFrames;
    }
    else if (state == kEnemyStateSleeping) {
        
        frames = sleepingAnimSpriteFrames;
    }
    else if (state == kEnemyStateCrossing) {
        
        frames = crossingAnimSpriteFrames;
    }

    [self setDisplayFrame:((SpriteTextureFrameInfo*)frames[animFrameIndex]).frame];
    
    CGSize spriteSize = ((SpriteTextureFrameInfo*)frames[animFrameIndex]).frame.rectInPixels.size;
    CGPoint halfSize = CGPointMake(spriteSize.width / 2, spriteSize.height / 2);
    
    self.position = ccpAdd(spritePos, ccpMult(ccpAdd(((SpriteTextureFrameInfo*)frames[animFrameIndex]).offset, halfSize), 2));
    
}

@end
