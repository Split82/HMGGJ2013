//
//  WallGrid.m
//  HMGGJ2013
//
//  Created by Loki on 1/25/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "WallGrid.h"

#define SLOT_WIDTH 40.0f

@interface WallGrid() {
    
    NSMutableArray *slots;
}

@end

@implementation WallGrid

- (id)init {
    
    self = [super init];
    if (self) {
        
        int slotsCount = (int)([CCDirector sharedDirector].winSize.width / SLOT_WIDTH) + 1;

        slots = [[NSMutableArray alloc] initWithCapacity:slotsCount];
        
        for (int i = 0; i < slotsCount; i++) {
            
            [slots addObject:[NSNumber numberWithBool:NO]];
        }
    }
    
    return self;
}

- (int)slotIndexFromPos:(float)pos {
    
    return (int)((pos + ([slots count] * SLOT_WIDTH - [CCDirector sharedDirector].winSize.width) / 2) / SLOT_WIDTH);
}

- (void)releaseSlot:(int)index {
    
    if (index < 0 || index > [slots count] - 1) {
        
        return;
    }
    slots[index] = [NSNumber numberWithBool:NO];
}

- (int)takeSlot:(float)pos {
 
    int index = [self slotIndexFromPos:pos];
    if (index < 0 || index > [slots count] - 1) {
        
        return -1;
    }
    
    slots[index] = [NSNumber numberWithBool:YES];
    
    return index;
}

- (BOOL)isSlotTaken:(float)pos {

    int index = [self slotIndexFromPos:pos];
    if (index < 0 || index > [slots count] - 1) {
        
        return YES;
    }
    
    return [slots[index] boolValue];
}

@end
