//
//  WaterSplash.h
//  HMGGJ2013
//
//  Created by Loki on 1/27/13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "CCSprite.h"

@protocol WaterSplashDelegate;


@interface WaterSplash : CCSprite

@property (nonatomic, weak) id <WaterSplashDelegate> delegate;

- (void)calc:(ccTime)deltaTime;

@end


@protocol WaterSplashDelegate <NSObject>

- (void)waterSplashDidFinish:(WaterSplash*)waterSplash;

@end
