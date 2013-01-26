//
//  ScreenShaker.h
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/26/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ScreenShaker : NSObject

@property (nonatomic, readonly) CGPoint offset;

- (void)calc:(ccTime)deltaTime;
- (void)shake;

@end
