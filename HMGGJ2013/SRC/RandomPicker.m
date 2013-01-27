//
//  RandomPicker.h
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/27/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "RandomPicker.h"

@interface RandomPicker() {

    NSMutableArray *items;
    NSTimeInterval minimumPickupInterval;
    BOOL canPick;
}

@end


@implementation RandomPicker

- (id)initWithItems:(NSArray*)initItems minimumPickupInterval:(NSTimeInterval)initMinimumPickupInterval {

    self = [super init];
    if (self) {

        items = [NSMutableArray arrayWithArray:initItems];
        minimumPickupInterval = initMinimumPickupInterval;
        
        canPick = YES;        
    }
    return self;
}

- (void)resetCanPick {
    
    canPick = YES;
}

- (id)pickRandomItem {

    if (canPick) {

        int pickedIndex = rand() % ([items count] - 1);
        id pickedObject = items[pickedIndex];
        [items removeObjectAtIndex:pickedIndex];
        [items addObject:pickedObject];
        canPick = NO;
        [self performSelector:@selector(resetCanPick) withObject:nil afterDelay:minimumPickupInterval];
        return pickedObject;
    }
    else {
        return nil;
    }
}

@end
