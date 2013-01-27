//
//  ScoreAddLabel.h
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/27/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

@protocol ScoreAddLabelDelegate;

typedef enum {

    ScoreAddLabelTypeBlinking,
    ScoreAddLabelTypeRising,
} ScoreAddLabelType;

@interface ScoreAddLabel : CCLabelBMFont

@property (nonatomic, readonly) ScoreAddLabelType type;
@property (nonatomic, weak) id <ScoreAddLabelDelegate> delegate;

- (id)initWithText:(NSString*)text pos:(CGPoint)pos type:(ScoreAddLabelType)type;
- (void)calc:(ccTime)deltaTime;

@end


@protocol ScoreAddLabelDelegate <NSObject>

- (void)scoreAddLabelDidFinish:(ScoreAddLabel*)label;

@end