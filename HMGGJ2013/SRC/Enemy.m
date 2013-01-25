//
//  Enemy.m
//  HMGGJ2013
//
//  Created by Loki on 1/25/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "Enemy.h"

@interface Enemy() {
    
    
}

@end


@implementation Enemy

@synthesize type;

-(void) initWithType:(EnemyType)_type {
    
    self.type = type;
}


- (void) update:(ccTime) time {
    
}


@end
