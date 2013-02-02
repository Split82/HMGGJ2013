//
//  GameObjectManager.m
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 2/2/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "GameObjectManager.h"
#import "SlimeBubbleSprite.h"
#import "AudioManager.h"

#define MAX_BODY_DEBRIS_COUNT 300
#define BOMB_KILL_PERIMETER 85
#define ENEMY_ATTACK_FORCE 5
#define BLOODY_MARY_BODY_DEBRIS_COUNT 150

@interface GameObjectManager() {

    CCSpriteBatchNode *mainSpriteBatch;
    CCNode *parentNode;
    CCParticleBatchNode *particleBatchNode;

    // Game objects
    NSMutableArray *killedCoins;
    NSMutableArray *killedTapEnemies;
    NSMutableArray *killedSwipeEnemies;
    NSMutableArray *killedBombs;
    NSMutableArray *killedEnemyBodyDebrises;
    NSMutableArray *killedBubbles;
    NSMutableArray *killedLabels;
    NSMutableArray *killedFlyingSkulls;
    NSMutableArray *killedBombExplosions;
    NSMutableArray *killedLightnings;
    NSMutableArray *killedWaterSplashes;
    NSMutableArray *killedTrails;

    NSMutableArray *unusedBloodParticleSystems;

    Trail *currentTrail;
}

@end


@implementation GameObjectManager

@synthesize tapEnemies;
@synthesize swipeEnemies;
@synthesize coins;
@synthesize bombs;
@synthesize enemyBodyDebrises;
@synthesize bubbles;
@synthesize labels;
@synthesize flyingSkulls;
@synthesize bombExplosions;
@synthesize lightnings;
@synthesize waterSplashes;
@synthesize trails;
@synthesize numberOfKillsInLastCalc;

- (id)initWithParentNode:(CCNode*)initParentNode spriteBatchNode:(CCSpriteBatchNode*)spriteBatchNode particleBatchNode:(CCParticleBatchNode*)initParticleBatchNode {

    self = [super init];
    if (self) {

        mainSpriteBatch = spriteBatchNode;
        parentNode = initParentNode;
        particleBatchNode = initParticleBatchNode;

        // Game objects
        tapEnemies = [[NSMutableArray alloc] initWithCapacity:100];
        swipeEnemies = [[NSMutableArray alloc] initWithCapacity:100];
        coins = [[NSMutableArray alloc] initWithCapacity:100];
        bombs = [[NSMutableArray alloc] initWithCapacity:10];
        enemyBodyDebrises = [[NSMutableArray alloc] initWithCapacity:50];
        bubbles = [[NSMutableArray alloc] initWithCapacity:40];
        labels = [[NSMutableArray alloc] initWithCapacity:4];
        flyingSkulls = [[NSMutableArray alloc] initWithCapacity:4];
        bombExplosions = [[NSMutableArray alloc] initWithCapacity:4];
        lightnings = [[NSMutableArray alloc] initWithCapacity:10];
        waterSplashes = [[NSMutableArray alloc] initWithCapacity:10];
        trails = [[NSMutableArray alloc] initWithCapacity:10];

        killedCoins = [[NSMutableArray alloc] initWithCapacity:10];
        killedTapEnemies = [[NSMutableArray alloc] initWithCapacity:100];
        killedSwipeEnemies = [[NSMutableArray alloc] initWithCapacity:100];
        killedBombs = [[NSMutableArray alloc] initWithCapacity:10];
        killedEnemyBodyDebrises = [[NSMutableArray alloc] initWithCapacity:50];
        killedBubbles = [[NSMutableArray alloc] initWithCapacity:2];
        killedLabels = [[NSMutableArray alloc] initWithCapacity:4];
        killedFlyingSkulls = [[NSMutableArray alloc] initWithCapacity:4];
        killedBombExplosions = [[NSMutableArray alloc] initWithCapacity:4];
        killedLightnings = [[NSMutableArray alloc] initWithCapacity:10];
        killedWaterSplashes = [[NSMutableArray alloc] initWithCapacity:4];
        killedTrails = [[NSMutableArray alloc] initWithCapacity:4];

        // Particles
        for (int i = 0; i < MAX_BODY_DEBRIS_COUNT; i++) {

            [unusedBloodParticleSystems addObject:[self createBloodParticleSystem:NO]];
        }
    }
    return self;
}

#pragma mark - Creating objects

- (void)addBubble:(CGPoint)pos {

    SlimeBubbleSprite *newBubble = [[SlimeBubbleSprite alloc] initWithPos:pos];
    newBubble.zOrder = 7;
    [mainSpriteBatch addChild:newBubble];
    [bubbles addObject:newBubble];
}

- (void)addCoinAtPos:(CGPoint)pos {

    CoinSprite *newCoin = [[CoinSprite alloc] initWithStartPos:pos spaceBounds:CGRectMake(0, _groundY, [CCDirector sharedDirector].winSize.width, [CCDirector sharedDirector].winSize.height - _groundY)];
    newCoin.zOrder = _zOrder;
    newCoin.delegate = self;
    [coins addObject:newCoin];
    [mainSpriteBatch addChild:newCoin];
}

- (void)addEnemy:(EnemyType)type {

    EnemySprite *enemy = [[EnemySprite alloc] initWithType:type];
    enemy.zOrder = _zOrder;
    enemy.delegate = self;

    if (enemy.type == kEnemyTypeSwipe) {
        [swipeEnemies addObject:enemy];
    }
    else {
        [tapEnemies addObject:enemy];
    }

    [mainSpriteBatch addChild:enemy];

}

- (void)addBombAtPosX:(CGFloat)posX {

    BombSprite *newBomb = [[BombSprite alloc] initWithStartPos:ccp(posX, 520 + (rand() / (float)RAND_MAX) * 20) groundY:_groundY];
    newBomb.zOrder = _zOrder;
    newBomb.delegate = self;

    [bombs addObject:newBomb];
    [mainSpriteBatch addChild:newBomb];
}

- (CCParticleSystemQuad*)createBloodParticleSystem:(BOOL)getFromUnusedSystems{

    if ([unusedBloodParticleSystems count] && getFromUnusedSystems == YES) {

        CCParticleSystemQuad *bloodParticleSystem = [unusedBloodParticleSystems lastObject];
        [unusedBloodParticleSystems removeLastObject];

        [bloodParticleSystem resetSystem];
        return bloodParticleSystem;
    }

    CCParticleSystemQuad *bloodParticleSystem = [[CCParticleSystemQuad alloc] initWithFile:@"BloodParticleSystem.plist"];

    return bloodParticleSystem;
}

- (void)createEnemyBodyExplosionAtPos:(CGPoint)pos enemyType:(EnemyType)enemyType {

    int numberOfBodyPars = rand() % 3 + 3;

    for (int i = 0; i < numberOfBodyPars; i++) {

        if ([enemyBodyDebrises count] >= MAX_BODY_DEBRIS_COUNT) {
            break;
        }

        // Debris
        float angle = M_PI * (rand() / (float)RAND_MAX) - M_PI_2;
        CGPoint randVelocity;
        randVelocity.x = sinf(angle) * 1500.0f;
        randVelocity.y = cosf(angle) * 1500.0f;
        EnemyBodyDebris *enemyBodyDebris = [[EnemyBodyDebris alloc] init:enemyType velocity:randVelocity spaceBounds:CGRectMake(0, _groundY, [CCDirector sharedDirector].winSize.width, [CCDirector sharedDirector].winSize.height - _groundY)];
        enemyBodyDebris.bloodParticleSystem = [self createBloodParticleSystem:YES];
        enemyBodyDebris.bloodParticleSystem.position = pos;
        [particleBatchNode addChild:enemyBodyDebris.bloodParticleSystem];

        enemyBodyDebris.position = pos;
        enemyBodyDebris.delegate = self;
        enemyBodyDebris.zOrder = _zOrder - 1;

        [enemyBodyDebrises addObject:enemyBodyDebris];
        [mainSpriteBatch addChild:enemyBodyDebris];
    }
}

- (void)makeBombExplosionAtPos:(CGPoint)pos {

    NSInteger kills = 0;

    [[AudioManager sharedManager] explode];

    for (EnemySprite *enemy in tapEnemies) {
        if (ccpLengthSQ(ccpSub(enemy.position, pos)) < BOMB_KILL_PERIMETER * BOMB_KILL_PERIMETER) {

            [killedTapEnemies addObject:enemy];
            [enemy removeFromParentAndCleanup:YES];

            [self enemyDidDie:enemy];

            kills++;
        }
    }

    if ([enemyBodyDebrises count] > BLOODY_MARY_BODY_DEBRIS_COUNT) {

        // TODO
        //[[AppDelegate player] filledFloorWithBlood];
    }

    if (kills > 0) {
        [self addScoreAddLabelWithText:[NSString stringWithFormat:@"+%d", kills * kills] pos:ccpAdd(pos, ccp(0, 20)) type:ScoreAddLabelTypeRising addSkull:YES];
    }

    // TODO
    //[AppDelegate player].points += kills * kills;

    BombExplosion *newBombExplosion = [[BombExplosion alloc] init];
    newBombExplosion.zOrder = _zOrder - 1;
    newBombExplosion.scale = [UIScreen mainScreen].scale * 2;
    newBombExplosion.anchorPoint = ccp(0.5, 0);
    newBombExplosion.position = pos;
    newBombExplosion.delegate = self;
    [mainSpriteBatch addChild:newBombExplosion];
    [bombExplosions addObject:newBombExplosion];
}

- (void)addScoreAddLabelWithText:(NSString*)text pos:(CGPoint)pos type:(ScoreAddLabelType)type addSkull:(BOOL)addSkull {

    ScoreAddLabel *scoreAddLabel = [[ScoreAddLabel alloc] initWithText:text pos:pos type:type];
    if (addSkull) {
        scoreAddLabel.anchorPoint = ccp(1, 0.5);
    }
    else {
        scoreAddLabel.anchorPoint = ccp(0.5, 0.5);
    }
    scoreAddLabel.scale = [UIScreen mainScreen].scale * 2;
    scoreAddLabel.delegate = self;
    scoreAddLabel.zOrder = 100;
    [parentNode addChild:scoreAddLabel];
    [labels addObject:scoreAddLabel];

    if (addSkull) {

        FlyingSkullSprite *flyingSkull = [[FlyingSkullSprite alloc] initWithPos:ccpAdd(pos, ccp(4, -4))];
        flyingSkull.delegate = self;
        flyingSkull.scale = [UIScreen mainScreen].scale * 2;
        flyingSkull.zOrder = 100;
        flyingSkull.anchorPoint = ccp(0, 0.5);
        [flyingSkulls addObject:flyingSkull];
        [mainSpriteBatch addChild:flyingSkull];
    }
}

- (void)createNewTrail:(CGPoint)startPos endPos:(CGPoint)endPos {

    currentTrail = [[Trail alloc] initWithStartPos:startPos endPos:endPos];
    currentTrail.delegate = self;
    currentTrail.zOrder = 999;

    [parentNode addChild:currentTrail];
    [trails addObject:currentTrail];
}

- (void)createLightningToEnemy:(EnemySprite*)enemy {

    [[AudioManager sharedManager] enemyHit];

    CGPoint startPos = CGPointMake([CCDirector sharedDirector].winSize.width / 2, [CCDirector sharedDirector].winSize.height / 2 + 220);
    Lightning *lightning = [[Lightning alloc] initWithStartPos:startPos endPos:enemy.position];
    lightning.zOrder = 30;
    lightning.lightningTarget = enemy;
    
    [parentNode addChild:lightning];
    [lightnings addObject:lightning];
}

#pragma mark - Actions

- (void)sliceEnemyFromWall:(EnemySprite*)enemy direction:(CGPoint)direction {

    if (enemy.state != kEnemyStateClimbing && enemy.state != kEnemyStateCrossing) {

        return;
    }

    // TODO
    /*
    if (enemy.state == kEnemyStateCrossing && [AppDelegate player].health <= ENEMY_ATTACK_FORCE) {

        [[AppDelegate player] closeCall];
    }
    */

    // TODO
    // masterControlProgram.swiperKilled = YES;

    // Debris
    CGPoint pos;
    pos = ccpAdd(enemy.position, ccpMult(ccpNormalize(CGPointMake(direction.y, -direction.x)), 10));

    float directionAngle = atan2f(direction.y, direction.x);
    float angle = directionAngle - M_PI / 8 * (rand() / (float)RAND_MAX);
    CGPoint randVelocity;
    randVelocity.x = cosf(angle);
    randVelocity.y = sinf(angle);
    randVelocity = ccpMult(randVelocity, 10.0f * ccpLength(direction));
    EnemyBodyDebris *enemyBodyDebris = [[EnemyBodyDebris alloc] init:kEnemyTypeSwipe velocity:randVelocity spaceBounds:CGRectMake(0, _groundY, [CCDirector sharedDirector].winSize.width, [CCDirector sharedDirector].winSize.height - _groundY)];
    enemyBodyDebris.bloodParticleSystem = [self createBloodParticleSystem:YES];
    enemyBodyDebris.bloodParticleSystem.position = pos;
    [particleBatchNode addChild:enemyBodyDebris.bloodParticleSystem];

    enemyBodyDebris.swipeEnemyPart = YES;
    enemyBodyDebris.position = pos;
    enemyBodyDebris.delegate = self;
    enemyBodyDebris.zOrder = _zOrder - 1;
    [enemyBodyDebrises addObject:enemyBodyDebris];
    [mainSpriteBatch addChild:enemyBodyDebris];

    pos = ccpSub(enemy.position, ccpMult(ccpNormalize(CGPointMake(direction.y, -direction.x)), 10));

    directionAngle = atan2f(direction.y, direction.x);
    angle = directionAngle + M_PI / 8 * (rand() / (float)RAND_MAX);
    randVelocity.x = cosf(angle);
    randVelocity.y = sinf(angle);
    randVelocity = ccpMult(randVelocity, 10.0f * ccpLength(direction));
    enemyBodyDebris = [[EnemyBodyDebris alloc] init:kEnemyTypeSwipe velocity:randVelocity spaceBounds:CGRectMake(0, _groundY, [CCDirector sharedDirector].winSize.width, [CCDirector sharedDirector].winSize.height - _groundY)];
    enemyBodyDebris.bloodParticleSystem = [self createBloodParticleSystem:YES];
    enemyBodyDebris.bloodParticleSystem.position = pos;
    [particleBatchNode addChild:enemyBodyDebris.bloodParticleSystem];

    enemyBodyDebris.swipeEnemyPart = YES;
    enemyBodyDebris.position = pos;
    enemyBodyDebris.delegate = self;
    enemyBodyDebris.zOrder = _zOrder - 1;
    [enemyBodyDebrises addObject:enemyBodyDebris];
    [mainSpriteBatch addChild:enemyBodyDebris];

    [killedSwipeEnemies addObject:enemy];
    [enemy removeFromParentAndCleanup:YES];
}


- (void)throwEnemyFromWall:(EnemySprite*)enemy {

    if (enemy.state != kEnemyStateClimbing && enemy.state != kEnemyStateCrossing) {
        return;
    }

    if (enemy.type == kEnemyTypeSwipe) {

        [enemy elecrify];
        [self createLightningToEnemy:enemy];
    }
    else {

        // TODO
        /*
        if (enemy.state == kEnemyStateCrossing && [AppDelegate player].health <= ENEMY_ATTACK_FORCE) {
            [[AppDelegate player] closeCall];
        }
         */
        [enemy throwFromWall];
        [self createLightningToEnemy:enemy];
    }
}

- (void)pickupCoin:(CoinSprite *)cointSprite {

    [coins removeObject:cointSprite];
    CCAction *action = [CCEaseOut actionWithAction:[CCSequence actions:[CCMoveTo actionWithDuration:0.7f position:_coinPickupAnimationDestinationPos], // TODO position from HUD
                                                    [CCCallFuncN actionWithTarget:self selector:@selector(coinEndedCashingAnimation:)], nil] rate:4.0f];
    [cointSprite runAction:action];

}

- (void)updateTrailWithStartPos:(CGPoint)startPos endPos:(CGPoint)endPos {
    
    if (currentTrail) {

        [currentTrail addPoint:endPos];
    }
    else {

        [self createNewTrail:startPos endPos:endPos];
    }
}

- (void)cancelTrail {

    currentTrail = nil;
}

#pragma mark - CoinSpriteDelegate

- (void)coinDidDie:(CoinSprite *)coinSprite {

    [killedCoins addObject:coinSprite];
    [coinSprite removeFromParentAndCleanup:YES];
}

#pragma mark - BombSpriteDelegate

- (void)bombDidDie:(BombSprite *)bombSprite {

    [killedBombs addObject:bombSprite];
    [bombSprite removeFromParentAndCleanup:YES];

    [self makeBombExplosionAtPos:bombSprite.position];
    
    [_delegate gameObjectManager:self bombDidDie:bombSprite];
}

#pragma mark - EnemySpriteDelegate

- (float)slimeSurfacePosY {

    return [_delegate gameObjectManagerSlimeSurfacePosY:self];
}

- (void)enemyDidFallIntoSlime:(EnemySprite*)enemy {

    if (enemy.type == kEnemyTypeTap) {

        [killedTapEnemies addObject:enemy];
    }
    else {

        [killedSwipeEnemies addObject:enemy];
    }
    [enemy removeFromParentAndCleanup:YES];

    // TODO
    /*
    [AppDelegate player].health -= ENEMY_ATTACK_FORCE;
    int diff = (100 - [AppDelegate player].health);
    monsterHearth.infarkt = (float)diff / 100;
*/
    WaterSplash *waterSplash = [[WaterSplash alloc] init];
    waterSplash.scale = [UIScreen mainScreen].scale * 2;
    waterSplash.anchorPoint = ccp(0.5, 0);
    CGPoint waterSplashPos = enemy.position;
    waterSplashPos.y = [_delegate gameObjectManagerSlimeSurfacePosY:self];
    waterSplash.position = waterSplashPos;
    waterSplash.delegate = self;
    waterSplash.zOrder = 16;
    [mainSpriteBatch addChild:waterSplash];
    [waterSplashes addObject:waterSplash];
}

#pragma mark - ScoreAddDelegate

- (void)scoreAddLabelDidFinish:(ScoreAddLabel *)label {

    [killedLabels addObject:label];
    [label removeFromParentAndCleanup:YES];
}

#pragma mark - EnemyBodyDebrisDelegate

- (void)enemyBodyDebrisDidDie:(EnemyBodyDebris *)enemyBodyDebris {

    [unusedBloodParticleSystems addObject:enemyBodyDebris.bloodParticleSystem];
    [enemyBodyDebris.bloodParticleSystem removeFromParentAndCleanup:YES];

    [killedEnemyBodyDebrises addObject:enemyBodyDebris];
    [enemyBodyDebris removeFromParentAndCleanup:YES];
}

- (void)enemyBodyDebrisDidDieAndSpawnTapEnemy:(EnemyBodyDebris *)enemyBodyDebris {

    [self enemyBodyDebrisDidDie:enemyBodyDebris];

    EnemySprite *enemy = [[EnemySprite alloc] initWithWakingTapperWithPos:enemyBodyDebris.position];
    [tapEnemies addObject:enemy];
    enemy.zOrder = _zOrder;
    [mainSpriteBatch addChild:enemy];
    enemy.delegate = self;
}

#pragma mark - BombExplosionDelegate

- (void)bombExplosionDidFinish:(BombExplosion *)bombExplosion {

    [killedBombExplosions addObject:bombExplosion];
    [bombExplosion removeFromParentAndCleanup:YES];

}

#pragma mark - FlyingSkullSpriteDelegate

- (void)flyingSkullSpriteDidFinish:(FlyingSkullSprite *)flyingSkull {

    [killedFlyingSkulls addObject:flyingSkull];
    [flyingSkull removeFromParentAndCleanup:YES];

}

#pragma mark - TrailDelegate

- (void)trailDidFinish:(Trail *)trail {

    if (trail == currentTrail) {

        currentTrail = nil;
    }

    [killedTrails addObject:trail];
    [trail removeFromParentAndCleanup:YES];
}

#pragma mark - LightningDelegate

- (void)lightningDidFinish:(Lightning *)lightning {

    [killedLightnings addObject:lightning];
    [lightning removeFromParentAndCleanup:YES];
}

#pragma mark - WaterSplashDelegate

- (void)waterSplashDidFinish:(WaterSplash *)waterSplash {

    [killedWaterSplashes addObject:waterSplash];
    [waterSplash removeFromParentAndCleanup:YES];
}

#pragma mark - Callbacks

- (void)enemyDidDie:(EnemySprite*)enemy {
    
    [self addCoinAtPos:enemy.position];
    [self createEnemyBodyExplosionAtPos:enemy.position enemyType:enemy.type];
    numberOfKillsInLastCalc++;
}

-(void)coinEndedCashingAnimation:(CoinSprite*)coin {

    [coin removeFromParentAndCleanup:YES];
}

#pragma mark - Calc

- (void)calc:(ccTime)deltaTime {

    numberOfKillsInLastCalc = 0;

    for (CoinSprite *coin in coins) {
        [coin calc:deltaTime];
    }

    for (BombSprite *bomb in bombs) {
        [bomb calc:deltaTime];
    }

    for (EnemySprite *enemy in tapEnemies) {
        [enemy calc:deltaTime];
    }

    for (EnemySprite *enemy in swipeEnemies) {
        [enemy calc:deltaTime];
    }

    for (EnemyBodyDebris *enemyBodyDebris in enemyBodyDebrises) {
        [enemyBodyDebris calc:deltaTime];
    }

    for (SlimeBubbleSprite *bubble in bubbles) {
        [bubble calc:deltaTime];
        if (bubble.position.y > [_delegate gameObjectManagerSlimeSurfacePosY:self] - bubble.boundingBox.size.height) {
            [killedBubbles addObject:bubble];
            [bubble removeFromParentAndCleanup:YES];
        }
    }

    for (ScoreAddLabel *label in labels) {
        [label calc:deltaTime];
    }

    for (FlyingSkullSprite *skull in flyingSkulls) {
        [skull calc:deltaTime];
    }

    for (Lightning *lightning in lightnings) {
        [lightning calc:deltaTime];
    }

    for (WaterSplash *waterSplash in waterSplashes) {
        [waterSplash calc:deltaTime];
    }

    for (Trail *trail in trails) {
        [trail calc:deltaTime];
    }

    for (BombExplosion *bombExplosion in bombExplosions) {
        [bombExplosion calc:deltaTime];
    }

    // Killed
    for (CoinSprite *coin in killedCoins) {
        [coins removeObject:coin];
    }
    [killedCoins removeAllObjects];


    for (BombSprite *bomb in killedBombs) {
        [bombs removeObject:bomb];
    }
    [killedBombs removeAllObjects];

    for (EnemySprite *killedEnemy in killedTapEnemies) {
        [tapEnemies removeObject:killedEnemy];
    }
    [killedTapEnemies removeAllObjects];

    for (EnemySprite *killedEnemy in killedSwipeEnemies) {
        [swipeEnemies removeObject:killedEnemy];
    }
    [killedSwipeEnemies removeAllObjects];

    for (EnemyBodyDebris *enemyBodyDebris in killedEnemyBodyDebrises) {
        [enemyBodyDebrises removeObject:enemyBodyDebris];
    }
    [killedEnemyBodyDebrises removeAllObjects];

    for (SlimeBubbleSprite *bubble in killedBubbles) {
        [bubbles removeObject:bubble];
    }
    [killedBubbles removeAllObjects];

    for (ScoreAddLabel *label in killedLabels) {
        [labels removeObject:label];
    }
    [killedLabels removeAllObjects];

    for (FlyingSkullSprite *skull in killedFlyingSkulls) {
        [flyingSkulls removeObject:skull];
    }
    [killedFlyingSkulls removeAllObjects];

    for (Lightning *lightning in killedLightnings) {
        [lightnings removeObject:lightning];
    }
    [killedLightnings removeAllObjects];

    for (WaterSplash *waterSplash in killedWaterSplashes) {
        [waterSplashes removeObject:waterSplash];
    }
    [killedWaterSplashes removeAllObjects];

    for (Trail *trail in killedTrails) {
        [trails removeObject:trail];
    }
    [killedTrails removeAllObjects];

    for (BombExplosion *bombExplosion in killedBombExplosions) {
        [bombExplosions removeObject:bombExplosion];
    }
    [killedBombExplosions removeAllObjects];
}

@end
