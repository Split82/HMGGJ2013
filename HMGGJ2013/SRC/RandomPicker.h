//
//  RandomPicker.h
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/27/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RandomPicker : NSObject

- (id)initWithItems:(NSArray*)items minimumPickupInterval:(NSTimeInterval)minimumPickupInterval;

- (id)pickRandomItem;

@end
