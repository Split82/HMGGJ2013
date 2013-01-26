//
//  GestureRecognizer.h
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/25/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

@protocol GestureRecognizerDelegate;


@interface GestureRecognizer : NSObject <CCTargetedTouchDelegate>

@property (nonatomic, weak) id <GestureRecognizerDelegate> delegate;

- (void)update:(ccTime)deltaTime;

@end


@protocol GestureRecognizerDelegate <NSObject>

- (void)longPressStarted:(CGPoint)pos;
- (void)longPressEnded;

- (void)swipeStarted:(CGPoint)pos;
- (void)swipeMoved:(CGPoint)pos;
- (void)swipeCancelled;
- (void)swipeEnded:(CGPoint)pos;

- (void)tapRecognized:(CGPoint)pos;

@end