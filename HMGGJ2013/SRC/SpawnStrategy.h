//
//  Strategy.h
//  HMGGJ2013
//
//  Created by Peter Morihladko on 1/27/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SpawnStrategy <NSObject>

- (void)scheduleNewEnemySpawn;

@end
