//
//  AudioManager.h
//  HMGGJ2013
//
//  Created by Peter Morihladko on 1/25/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioManager : NSObject

+ (id)sharedManager;

- (void)preloadSounds;

- (void)startBackgroundMusic;

- (void)stopBackgroundMusic;

- (void)groundHit;

- (void)enemyHit;

- (void)explode;

- (void)coinHit;

@end
