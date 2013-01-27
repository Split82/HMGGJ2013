//
//  WallGrid.h
//  HMGGJ2013
//
//  Created by Loki on 1/25/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WallGrid : NSObject

- (void)releaseSlot:(int)index;
- (int)takeSlot:(float)pos;
- (BOOL)isSlotTaken:(float)pos;

@end
