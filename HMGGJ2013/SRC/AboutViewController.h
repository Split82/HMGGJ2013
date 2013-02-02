//
//  AboutViewController.h
//  HMGGJ2013
//
//  Created by Lukáš Foldýna on 25.01.13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//


@protocol AboutViewControllerDelegate;


@interface AboutViewController : UIViewController

@property (nonatomic, weak) id <AboutViewControllerDelegate> delegate;

@end


@protocol AboutViewControllerDelegate <NSObject>

- (void)aboutViewControllerDidFinish:(AboutViewController*)viewController;

@end