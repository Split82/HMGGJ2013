//
//  AboutViewController.m
//  HMGGJ2013
//
//  Created by Lukáš Foldýna on 25.01.13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "AboutViewController.h"


@interface AboutViewController ()

@property (nonatomic, strong) UIView *padView;

@end

@implementation AboutViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(movingGesture:)];
    _padView = [[UIView alloc] initWithFrame:CGRectMake(140.0, self.view.frame.size.height - 5.0, 40.0, 20.0)];
    [_padView setBackgroundColor:[UIColor blackColor]];
    [_padView addGestureRecognizer:pan];
    [self.view addSubview:_padView];
}

#pragma mark -

- (void) movingGesture:(UIGestureRecognizer *)gesture
{
    CGPoint location = [gesture locationInView:self.view];
    if (location.x < 0)
        location.x = 5.0;
    else if (location.x + 40.0 > 320.0) {
        location.x = 320.0 - 45.0;
    }
    location.y = self.view.frame.size.height - 25.0;
    CGRect frame = [_padView frame];
    frame.origin = location;
    [_padView setFrame:frame];
}

- (IBAction) closeButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
