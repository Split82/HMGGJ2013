//
//  AboutViewController.m
//  HMGGJ2013
//
//  Created by Lukáš Foldýna on 25.01.13.
//  Copyright (c) 2013 Hyperbolic Magnetism. All rights reserved.
//

#import "AboutViewController.h"


#define IS_WIDESCREEN ([[UIScreen mainScreen] bounds].size.height == 568.0f)


@interface AboutViewController ()

@property (nonatomic, strong) UIView *padView;

@end

@implementation AboutViewController

- (UIImage *)rasterizedImage:(NSString *)name {
    UIImage *image = [UIImage imageNamed:name];
    image = [UIImage imageWithCGImage:[image CGImage] scale:[[UIScreen mainScreen] scale] * 2 orientation:image.imageOrientation];
    return image;
}

- (CGRect)rectWithSize:(CGSize)size originY:(CGFloat)originY {
    CGFloat scale = 2;
    size.width *= scale;
    size.height *= scale;
    CGSize contentSize = [CCDirector sharedDirector].winSize;
    return CGRectMake((contentSize.width - size.width) / 2, originY,
                      size.width, size.height);
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    [self.backgroundView setImage:[self rasterizedImage:IS_WIDESCREEN ? @"about-bg" : @"about-bg-2"]];
    [self.backgroundView.layer setMagnificationFilter:kCAFilterNearest];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[self rasterizedImage:@"about-twitter"]];
    [imageView setFrame:[self rectWithSize:CGSizeMake(82.0, 92.0) originY:118]];
    [imageView.layer setMagnificationFilter:kCAFilterNearest];
    [imageView setUserInteractionEnabled:YES];
    [imageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(twitterPressed:)]];
    [self.view addSubview:imageView];
}

#pragma mark -

- (IBAction) twitterPressed:(UITapGestureRecognizer *)sender
{
    CGPoint location = [sender locationInView:[sender view]];
    NSInteger p = floorf(location.y / 37);
    
    if (p == 0)
        [self openTwitterAppForFollowingUser:@"augard"];
    else if (p == 1)
        [self openTwitterAppForFollowingUser:@"hladomorko"];
    else if (p == 2)
        [self openTwitterAppForFollowingUser:@"karimartin"];
    else if (p == 3)
        [self openTwitterAppForFollowingUser:@"lokimansk"];
    else if (p == 4)
        [self openTwitterAppForFollowingUser:@"split82"];
}

- (IBAction) closeButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void) openTwitterAppForFollowingUser:(NSString *)twitterUserName
{
	UIApplication *app = [UIApplication sharedApplication];
    
    // TweetbotURL: tweetbot://<screenname>/follow/
    NSURL *tweetbotURL = [NSURL URLWithString:[NSString stringWithFormat:@"tweetbot://<screenname>/follow/%@", twitterUserName]];
	if ([app canOpenURL:tweetbotURL]) {
		[app openURL:tweetbotURL];
		return;
	}
    
	// Tweetie: http://developer.atebits.com/tweetie-iphone/protocol-reference/
	NSURL *tweetieURL = [NSURL URLWithString:[NSString stringWithFormat:@"tweetie://user?screen_name=%@", twitterUserName]];
	if ([app canOpenURL:tweetieURL])
	{
		[app openURL:tweetieURL];
		return;
	}
    
	// Birdfeed: http://birdfeed.tumblr.com/post/172994970/url-scheme
	NSURL *birdfeedURL = [NSURL URLWithString:[NSString stringWithFormat:@"x-birdfeed://user?screen_name=%@", twitterUserName]];
	if ([app canOpenURL:birdfeedURL])
	{
		[app openURL:birdfeedURL];
		return;
	}
    
	// Twittelator: http://www.stone.com/Twittelator/Twittelator_API.html
	NSURL *twittelatorURL = [NSURL URLWithString:[NSString stringWithFormat:@"twit:///user?screen_name=%@", twitterUserName]];
	if ([app canOpenURL:twittelatorURL])
	{
		[app openURL:twittelatorURL];
		return;
	}
    
	// Icebird: http://icebirdapp.com/developerdocumentation/
	NSURL *icebirdURL = [NSURL URLWithString:[NSString stringWithFormat:@"icebird://user?screen_name=%@", twitterUserName]];
	if ([app canOpenURL:icebirdURL])
	{
		[app openURL:icebirdURL];
		return;
	}
    
	// Fluttr: no docs
	NSURL *fluttrURL = [NSURL URLWithString:[NSString stringWithFormat:@"fluttr://user/%@", twitterUserName]];
	if ([app canOpenURL:fluttrURL])
	{
		[app openURL:fluttrURL];
		return;
	}
    
	// SimplyTweet: http://motionobj.com/blog/url-schemes-in-simplytweet-23
	NSURL *simplytweetURL = [NSURL URLWithString:[NSString stringWithFormat:@"simplytweet:?link=http://twitter.com/%@", twitterUserName]];
	if ([app canOpenURL:simplytweetURL])
	{
		[app openURL:simplytweetURL];
		return;
	}
    
	// Tweetings: http://tweetings.net/iphone/scheme.html
	NSURL *tweetingsURL = [NSURL URLWithString:[NSString stringWithFormat:@"tweetings:///user?screen_name=%@", twitterUserName]];
	if ([app canOpenURL:tweetingsURL])
	{
		[app openURL:tweetingsURL];
		return;
	}
    
	// Echofon: http://echofon.com/twitter/iphone/guide.html
	NSURL *echofonURL = [NSURL URLWithString:[NSString stringWithFormat:@"echofon:///user_timeline?%@", twitterUserName]];
	if ([app canOpenURL:echofonURL])
	{
		[app openURL:echofonURL];
		return;
	}
    
	// --- Fallback: Mobile Twitter in Safari
	NSURL *safariURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://mobile.twitter.com/%@", twitterUserName]];
	[app openURL:safariURL];
}

@end
