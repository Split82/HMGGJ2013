//
//  AppDelegate.h
//  HMGGJ2013
//
//  Created by Jan Ilavsky on 1/25/13.
//  Copyright __MyCompanyName__ 2013. All rights reserved.
//

#import "PlayerModel.h"

@interface AppDelegate : NSObject <UIApplicationDelegate>

+ (PlayerModel *) player;
@property (nonatomic, strong) PlayerModel *player;

@end
