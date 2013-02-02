//
//  Menu.h
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 2/2/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

@protocol Menu <NSObject>

- (void)show;
- (void)hide;
- (void)calc:(ccTime)deltaTime;

@end
