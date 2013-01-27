//
//  TeslaCoil.h
//  HMGGJ2013
//
//  Created by Loki on 1/27/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "CCSprite.h"

@protocol TeslaCoilDelegate;

@interface TeslaCoil : CCSprite

@property (nonatomic, weak) id <TeslaCoilDelegate> delegate;

- (void)calc:(ccTime)deltaTime;

- (void)electrify;

@end


@protocol TeslaCoilDelegate <NSObject>


@end