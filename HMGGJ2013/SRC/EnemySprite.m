//
//  Enemy.m
//  HMGGJ2013
//
//  Created by Loki on 1/25/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

// masakeeeeer!!!!!!

#import "EnemySprite.h"
#import "GameDataNameDefinitions.h"
#import "MainGameScene.h"
#import "SpriteTextureFrameInfo.h"
#import "WallGrid.h"
#import "AudioManager.h"

#define ENEMY_HALF_WIDTH 20.0f

#define WALKING_MOVEMENT_OFFSET 2.0f
#define WALKING_ANIM_DELAY (1 / 30.0f)
#define WALKING_BORDER_OFFSET (ENEMY_HALF_WIDTH * 2)

#define CLIMBING_MOVEMENT_OFFSET 4.0f
#define CLIMBING_ANIM_DELAY (1 / 30.0f * 2)
#define CLIMBING_BORDER_OFFSET 30.0f

#define FALLING_ACCEL -400.0f
#define FALLING_HORIZ_DECCEL 100.0f
#define FALLING_ANIM_DELAY 0.2f

#define SLEEPING_ANIM_DELAY (1 / 30.0f)

#define CROSSING_ANIM_DELAY (1 / 30.0f * 4)

#define WALL_HEIGHT 356.0f

#define MIN_FALLING_SPPEED_FOR_SLEEP 250.0f

#define ZAPPING_TIME 0.4f

#define ZAPPING_SKELETON_TIME 0.08f

#define MIN_SLEEP_TIME_INTERVAL 0.8f

#define WALL_GRID_SLOT_HEIGHT 40.0f


static NSMutableArray *swiperWalkingAnimSpriteFrames = nil;
static NSMutableArray *swiperClimbingAnimSpriteFrames = nil;
static NSMutableArray *swiperFallingAnimSpriteFrames = nil;
static NSMutableArray *swiperCrossingAnimSpriteFrames = nil;
static NSMutableArray *swiperSleepingAnimSpriteFrames = nil;
static NSMutableArray *swiperZappingAnimSpriteFrames = nil;

static NSMutableArray *tapperWalkingAnimSpriteFrames = nil;
static NSMutableArray *tapperClimbingAnimSpriteFrames = nil;
static NSMutableArray *tapperFallingAnimSpriteFrames = nil;
static NSMutableArray *tapperCrossingAnimSpriteFrames = nil;
static NSMutableArray *tapperSleepingAnimSpriteFrames = nil;
static NSMutableArray *tapperZappingAnimSpriteFrames = nil;

static WallGrid *wallGrid = nil;

@interface EnemySprite() {
 
    float direction;

    NSMutableArray *walkingAnimSpriteFrames;
    NSMutableArray *climbingAnimSpriteFrames;
    NSMutableArray *fallingAnimSpriteFrames;
    NSMutableArray *crossingAnimSpriteFrames;
    NSMutableArray *sleepingAnimSpriteFrames;
    NSMutableArray *zappingAnimSpriteFrames;
    
    int animFrameIndex;
    
    float animTime;
    
    float climbXPos;
    float verticalVel;
    float horizontalVel;
    
    BOOL killed;
    BOOL wakingUp;
        
    float sleepTime;
    float wakingAnimeDelayMul;
    
    NSMutableArray *stars;
    
    float elapsedTime;
    float zappingTime;
    
    
    int hasWallSlotAtIndex;
}

@property (nonatomic, assign) CGPoint spritePos;


@end


@implementation EnemySprite

@synthesize type, state, spritePos;

-(id) initWithType:(EnemyType)_type {
    
    if (self = [self initWithSpriteFrameName:@"monsterBigMove1.png"]) {
        
        self.anchorPoint = ccp(0.5, 0.5);
        self.type = _type;
        self.state = kEnemyStateWalking;
        self.scale = [UIScreen mainScreen].scale * 2;
        animFrameIndex = 0;
        animTime = 0;
        wakingUp = NO;
        hasWallSlotAtIndex = -1;
        
        if (rand() % 2) {
            
            direction = 1;
            
            spritePos = CGPointMake(-WALKING_BORDER_OFFSET, GROUND_Y);
            
            climbXPos = CLIMBING_BORDER_OFFSET + (float)rand() / RAND_MAX * [CCDirector sharedDirector].winSize.width  / 2;
            
        }
        else {
            
            direction = -1;
            self.flipX = YES;
            
            spritePos = CGPointMake([CCDirector sharedDirector].winSize.width + WALKING_BORDER_OFFSET, GROUND_Y);
            
            climbXPos = [CCDirector sharedDirector].winSize.width - CLIMBING_BORDER_OFFSET - ENEMY_HALF_WIDTH * 2 -(float)rand() / RAND_MAX * [CCDirector sharedDirector].winSize.width / 2;
            
        }

        if (!wallGrid) {
            
            wallGrid = [[WallGrid alloc] init];
        }

        if (!swiperWalkingAnimSpriteFrames) {
            
            // swiper
            
            
            //walk
            swiperWalkingAnimSpriteFrames = [[NSMutableArray alloc] initWithCapacity:12];
            
            [swiperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"monsterBigMove1.png" offset:CGPointMake(0, 0)]];
            [swiperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"monsterBigMove2.png" offset:CGPointMake(0, 0)]];
            [swiperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"monsterBigMove3.png" offset:CGPointMake(0, 0)]];
            [swiperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"monsterBigMove4.png" offset:CGPointMake(0, 0)]];
            [swiperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"monsterBigMove5.png" offset:CGPointMake(0, 0)]];
            [swiperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"monsterBigMove6.png" offset:CGPointMake(0, 0)]];
            [swiperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"monsterBigMove7.png" offset:CGPointMake(0, 0)]];
            [swiperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"monsterBigMove8.png" offset:CGPointMake(0, 0)]];
            [swiperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"monsterBigMove9.png" offset:CGPointMake(0, 0)]];
            [swiperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"monsterBigMove10.png" offset:CGPointMake(0, 0)]];
            [swiperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"monsterBigMove11.png" offset:CGPointMake(0, 0)]];
            [swiperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"monsterBigMove12.png" offset:CGPointMake(0, 0)]];
            
            // climb
            swiperClimbingAnimSpriteFrames = [[NSMutableArray alloc] initWithCapacity:12];
            
            [swiperClimbingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"BigClimb1.png" offset:CGPointMake(1, 0)]];
            [swiperClimbingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"BigClimb2.png" offset:CGPointMake(0, 0)]];
            [swiperClimbingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"BigClimb3.png" offset:CGPointMake(0, 0)]];
            [swiperClimbingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"BigClimb4.png" offset:CGPointMake(0, 0)]];
            [swiperClimbingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"BigClimb5.png" offset:CGPointMake(0, 0)]];
            [swiperClimbingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"BigClimb6.png" offset:CGPointMake(0, 0)]];
            [swiperClimbingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"BigClimb7.png" offset:CGPointMake(1, 0)]];
            [swiperClimbingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"BigClimbEl1.png" offset:CGPointMake(1, 0)]];
            [swiperClimbingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"BigClimbEl2.png" offset:CGPointMake(0, 0)]];
            [swiperClimbingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"BigClimbEl3.png" offset:CGPointMake(0, 0)]];
            [swiperClimbingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"BigClimbEl4.png" offset:CGPointMake(0, 0)]];
            [swiperClimbingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"BigClimbEl5.png" offset:CGPointMake(0, 0)]];
            [swiperClimbingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"BigClimbEl6.png" offset:CGPointMake(0, 0)]];
            [swiperClimbingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"BigClimbEl7.png" offset:CGPointMake(1, 0)]];
            
            // fall
            swiperFallingAnimSpriteFrames = [[NSMutableArray alloc] initWithCapacity:12];

            [swiperFallingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"bigFront.png" offset:CGPointMake(0, 0)]];
            [swiperFallingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"bigWaterFall.png" offset:CGPointMake(0, 0)]];
            
            // sleep
            swiperSleepingAnimSpriteFrames = [[NSMutableArray alloc] initWithCapacity:12];
            
            [swiperSleepingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"bigFront.png" offset:CGPointMake(0, 0)]];
            [swiperSleepingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"bigFall1.png" offset:CGPointMake(0, 0)]];
            [swiperSleepingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"bigFall2.png" offset:CGPointMake(0, 0)]];
            [swiperSleepingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"bigFall3.png" offset:CGPointMake(0, 0)]];
            [swiperSleepingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"bigFall4.png" offset:CGPointMake(0, 0)]];

            // cross
            swiperCrossingAnimSpriteFrames = [[NSMutableArray alloc] initWithCapacity:12];
            
            [swiperCrossingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"BigClimbTop.png" offset:CGPointMake(0, 5)]];
            [swiperCrossingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"BigClimbTop2.png" offset:CGPointMake(0, 8)]];
            
            // zapp
            swiperZappingAnimSpriteFrames = [[NSMutableArray alloc] initWithCapacity:12];
            
            [swiperZappingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"bigSkeleton.png" offset:CGPointMake(-1, -1)]];
            [swiperZappingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"bigFront.png" offset:CGPointMake(0, 0)]];
            
            //tapper
            
            // walk
            tapperWalkingAnimSpriteFrames = [[NSMutableArray alloc] initWithCapacity:12];
            
            [tapperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"TallMove1.png" offset:CGPointMake(0, 0)]];
            [tapperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"TallMove2.png" offset:CGPointMake(0, 0)]];
            [tapperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"TallMove3.png" offset:CGPointMake(0, 0)]];
            [tapperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"TallMove4.png" offset:CGPointMake(0, 0)]];
            [tapperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"TallMove5.png" offset:CGPointMake(0, 0)]];
            [tapperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"TallMove6.png" offset:CGPointMake(0, 0)]];
            [tapperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"TallMove7.png" offset:CGPointMake(0, 0)]];
            [tapperWalkingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"TallMove8.png" offset:CGPointMake(0, 0)]];
            
            // climb
            tapperClimbingAnimSpriteFrames = [[NSMutableArray alloc] initWithCapacity:12];
            
            [tapperClimbingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"TallClimb1.png" offset:CGPointMake(1, 0)]];
            [tapperClimbingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"TallClimb2.png" offset:CGPointMake(0, 0)]];
            [tapperClimbingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"TallClimb3.png" offset:CGPointMake(0, 0)]];
            [tapperClimbingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"TallClimb4.png" offset:CGPointMake(0, 0)]];
            [tapperClimbingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"TallClimb5.png" offset:CGPointMake(0, 0)]];
            [tapperClimbingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"TallClimb6.png" offset:CGPointMake(0, 0)]];

            // fall
            tapperFallingAnimSpriteFrames = [[NSMutableArray alloc] initWithCapacity:12];
            
            [tapperFallingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"tallFront.png" offset:CGPointMake(0, 0)]];
            [tapperFallingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"tallWaterFall.png" offset:CGPointMake(0, 0)]];
            
            // sleep
            tapperSleepingAnimSpriteFrames = [[NSMutableArray alloc] initWithCapacity:12];
            
            [tapperSleepingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"tallFront.png" offset:CGPointMake(0, 0)]];
            [tapperSleepingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"tallFall1.png" offset:CGPointMake(0, 0)]];
            [tapperSleepingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"tallFall2.png" offset:CGPointMake(0, 0)]];
            [tapperSleepingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"tallFall3.png" offset:CGPointMake(0, 0)]];
            [tapperSleepingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"tallFall4.png" offset:CGPointMake(0, 0)]];
            
            // cross
            tapperCrossingAnimSpriteFrames = [[NSMutableArray alloc] initWithCapacity:12];
            
            [tapperCrossingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"TallClimbTop.png" offset:CGPointMake(0, 2)]];
            [tapperCrossingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"TallClimbTop2.png" offset:CGPointMake(0, 8)]];
            
            // zapp
            tapperZappingAnimSpriteFrames = [[NSMutableArray alloc] initWithCapacity:12];
            
            [tapperZappingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"tallSkeleton.png" offset:CGPointMake(-1, -1)]];
            [tapperZappingAnimSpriteFrames addObject:[SpriteTextureFrameInfo createWithFrameName:@"tallFront.png" offset:CGPointMake(0, 0)]];
        }
        
        
        if (type == kEnemyTypeSwipe) {
            
            walkingAnimSpriteFrames = swiperWalkingAnimSpriteFrames;
            climbingAnimSpriteFrames = swiperClimbingAnimSpriteFrames;
            fallingAnimSpriteFrames = swiperFallingAnimSpriteFrames;
            sleepingAnimSpriteFrames = swiperSleepingAnimSpriteFrames;
            crossingAnimSpriteFrames = swiperCrossingAnimSpriteFrames;
            zappingAnimSpriteFrames = swiperZappingAnimSpriteFrames;
        }
        else {
            
            walkingAnimSpriteFrames = tapperWalkingAnimSpriteFrames;
            climbingAnimSpriteFrames = tapperClimbingAnimSpriteFrames;
            fallingAnimSpriteFrames = tapperFallingAnimSpriteFrames;
            sleepingAnimSpriteFrames = tapperSleepingAnimSpriteFrames;
            crossingAnimSpriteFrames = tapperCrossingAnimSpriteFrames;
            zappingAnimSpriteFrames = tapperZappingAnimSpriteFrames;
        }
        

        [self updateSpritePos];
        
        stars = [[NSMutableArray alloc] initWithCapacity:3];
        
        CCSprite *star;
        
        for (int i = 0; i < 3; i++) {
            
            star = [[CCSprite alloc] initWithSpriteFrameName:@"starConfused.png"];
            star.anchorPoint = ccp(0.5, 0.5f);
            star.zOrder = 30;
            [self addChild:star];
            
            [stars addObject:star];
            star.visible = NO;
        }
    }
    
    return self;
}


-(id) initWithWakingTapperWithPos:(CGPoint)pos {
    
    self = [self initWithType:kEnemyTypeTap];
    if (self) {
        
        state = kEnemyStateSleeping;
        spritePos = pos;
        spritePos.y = GROUND_Y;
        
        animFrameIndex = [sleepingAnimSpriteFrames count] - 1;
        for (CCSprite *star in stars) {
            
            star.visible = YES;
        }
        sleepTime = 0.5f;
        
        [self updateSpritePos];
    }
    return self;
}

- (void) dealloc {
    
    if ((state == kEnemyStateClimbing) && (hasWallSlotAtIndex >= 0)) {
        
        [wallGrid releaseSlot:hasWallSlotAtIndex];
    }
}


- (void) calc:(ccTime) time {
    
    animTime += time;
    elapsedTime += time;
    
    for (int i = 0; i < [stars count]; i++) {
        
        CCSprite *star = stars[i];
        CGPoint newPos = star.position;
        
        newPos.y = 10;
        if (type == kEnemyTypeTap) {
            
            newPos.x = 8.0f;
        }
        else {
            
            newPos.x = 9.6f;
        }
        newPos.x += sinf(elapsedTime * 7 + i * 2 * 3.14 / [stars count]) * 8;
        
        star.position = ccpMult(newPos, 1 / [UIScreen mainScreen].scale);
    }
    
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
                    
                    if ([wallGrid isSlotTaken:position_.x]) {
                     
                        [self updateClimbPos];
                    }
                    else {
                        
                        zappingTime = 0;
                        state = kEnemyStateClimbing;
                        hasWallSlotAtIndex = [wallGrid takeSlot:position_.x];
                        
                        animFrameIndex = 0;
                        animTime = 0;
                        
                        [self updateSpritePos];
                        
                        return;
                    }
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
                animTime = 0;
                
                state = kEnemyStateCrossing;
                
                [self updateSpritePos];
                return;
            }
            if (animTime > CLIMBING_ANIM_DELAY) {
                
                CGPoint newSpritePos = spritePos;
                newSpritePos.y += (int)(animTime / CLIMBING_ANIM_DELAY) * CLIMBING_MOVEMENT_OFFSET;
                
                
                animFrameIndex += (int)(animTime / CLIMBING_ANIM_DELAY);
                animFrameIndex = animFrameIndex % ([climbingAnimSpriteFrames count] / 2);
                
                animTime = animTime - (int)(animTime / CLIMBING_ANIM_DELAY) * CLIMBING_ANIM_DELAY;

                
                spritePos = newSpritePos;
                
                if ((spritePos.y > (WALL_GRID_SLOT_HEIGHT + GROUND_Y)) && (hasWallSlotAtIndex >= 0)) {
                    
                    [wallGrid releaseSlot:hasWallSlotAtIndex];
                    hasWallSlotAtIndex = -1;
                }
                
            }
            if (zappingTime > 0) {
                
                zappingTime -= time;
            }
            [self updateSpritePos];
            break;
        }
        case kEnemyStateZapping:
        case kEnemyStateFallingInto:
        case kEnemyStateFalling: {
            
            if (((state == kEnemyStateFalling) || (state == kEnemyStateZapping)) && (spritePos.y < GROUND_Y)) {
                
                [[AudioManager sharedManager] groundHit];
                
                spritePos.y = GROUND_Y;
                
                if (fabs(verticalVel) < MIN_FALLING_SPPEED_FOR_SLEEP) {
                    
                    [self climbAferFall];
                    return;
                }

                wakingUp = NO;
                wakingAnimeDelayMul =  200.0f / fabs(verticalVel);
                
                sleepTime = MIN((fabs(verticalVel) - MIN_FALLING_SPPEED_FOR_SLEEP) * 0.006 + MIN_SLEEP_TIME_INTERVAL, 3);
                
                animFrameIndex = 1; // skip first front facing frame
                animTime = 0;
                
                state = kEnemyStateSleeping;
                
                [self updateSpritePos];
                return;
            }
            else if ((state == kEnemyStateFallingInto) && (spritePos.y < [_delegate slimeSurfacePosY])) {
                
                [_delegate enemyDidFallIntoSlime:self];
                return;
            }
            
            spritePos.y += verticalVel * time;
            verticalVel += FALLING_ACCEL * time;
            
            spritePos.x += horizontalVel * time * direction;
            horizontalVel -= FALLING_HORIZ_DECCEL * time;
            if (horizontalVel < 0) {
                
                horizontalVel = 0;
            }
            
            //zapping
            if (state == kEnemyStateZapping) {
                
                animFrameIndex = (int)roundf(zappingTime / ZAPPING_SKELETON_TIME) % [zappingAnimSpriteFrames count];
                
                if (zappingTime < 0) {
                    
                    state = kEnemyStateFalling;
                    animTime = 0;
                    animFrameIndex = 0;
                }
                
                zappingTime -= time;
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
                    
                    for (CCSprite *star in stars) {
                        
                        star.visible = NO;
                    }
                }
            }
            else {
                
                if (animTime > SLEEPING_ANIM_DELAY * wakingAnimeDelayMul) {
                    
                    // amnimate waking up/sleeping down
                    animFrameIndex += (wakingUp ? -1 : 1) * (int)(animTime / (SLEEPING_ANIM_DELAY * wakingAnimeDelayMul));
                    
                    animTime = animTime - (int)(animTime / (SLEEPING_ANIM_DELAY * wakingAnimeDelayMul)) * SLEEPING_ANIM_DELAY * wakingAnimeDelayMul;
                    
                    
                    // fell on ground
                    if (animFrameIndex >= (int)[sleepingAnimSpriteFrames count] - 1) {
                        
                        animFrameIndex = [sleepingAnimSpriteFrames count] - 1;
                        
                        if (sleepTime > 0.3) {
                            
                            for (CCSprite *star in stars) {
                                
                                star.visible = YES;
                            }
                        }
                    }
                    // fully waked up
                    else if (animFrameIndex < 0) {
                        
                        [self climbAferFall];
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
                    
                    spritePos.y -= 10; // move down some
                    
                    animTime = 0;
                    animFrameIndex = [fallingAnimSpriteFrames count] - 1; // last frame

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

-(void)climbAferFall {
    
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
        
        if ([wallGrid isSlotTaken:position_.x]) {
         
            state = kEnemyStateWalking;
            [self updateClimbPos];
        }
        else {
        
            zappingTime = 0;
            state = kEnemyStateClimbing;
            hasWallSlotAtIndex = [wallGrid takeSlot:position_.x];
        }
    }
    
    animFrameIndex = 0;
    animTime = 0;
    
    [self updateSpritePos];
}

+(void) resetWallGrid {
    
    
}

-(void) elecrify {
 
    zappingTime = ZAPPING_TIME;
}


-(void) throwFromWall {
    
    if ((state == kEnemyStateClimbing) && (hasWallSlotAtIndex >= 0)) {
        
        [wallGrid releaseSlot:hasWallSlotAtIndex];
        hasWallSlotAtIndex = -1;
    }
    
    state = kEnemyStateZapping;
    animFrameIndex = 0;
    animTime = 0;
    verticalVel = 100;
    horizontalVel = (float)rand() / RAND_MAX * 50 + 50;
    if (rand() % 2) {
        
        direction = 1;
    }
    else {
        
        direction = -1;
    }
    
    zappingTime = ZAPPING_TIME;
    
    elapsedTime = 0;
    
    [self updateSpritePos];
}

- (void) updateClimbPos {
    
    climbXPos += (float)rand() / RAND_MAX * ENEMY_HALF_WIDTH * direction / 4;
    
    if (climbXPos > ([CCDirector sharedDirector].winSize.width - CLIMBING_BORDER_OFFSET - ENEMY_HALF_WIDTH * 2)) {
        
        climbXPos -= ENEMY_HALF_WIDTH;
    }
    else if (climbXPos < CLIMBING_BORDER_OFFSET) {
        
        climbXPos += ENEMY_HALF_WIDTH;
    }
}

- (void) updateSpritePos {
    

    int realAnimFrameIndex = animFrameIndex;
    CGPoint realSpritePos = spritePos;
    
    NSArray *frames;
    if (state == kEnemyStateWalking) {
        
        frames = walkingAnimSpriteFrames;
    }
    else if (state == kEnemyStateClimbing) {
        
        frames = climbingAnimSpriteFrames;
        if (zappingTime > 0) {
            
            realSpritePos.x += sinf(ZAPPING_TIME - zappingTime) * zappingTime / ZAPPING_TIME * 10;
            
            int isZapping = (int)roundf(zappingTime / ZAPPING_SKELETON_TIME) % 2;
            
            if (isZapping) {
                
                realAnimFrameIndex += [climbingAnimSpriteFrames count] / 2;
            }
        }
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
    else if (state == kEnemyStateZapping) {
        
        frames = zappingAnimSpriteFrames;
    }

    [self setDisplayFrame:((SpriteTextureFrameInfo*)frames[realAnimFrameIndex]).frame];
    
    CGSize spriteSize = ((SpriteTextureFrameInfo*)frames[realAnimFrameIndex]).frame.rectInPixels.size;
    CGPoint halfSize = CGPointMake(spriteSize.width / 2, spriteSize.height / 2);
    
    self.position = ccpAdd(realSpritePos, ccpMult(ccpAdd(((SpriteTextureFrameInfo*)frames[realAnimFrameIndex]).offset, halfSize), 2));

    
}

@end
