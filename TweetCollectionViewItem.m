//
//  TweetCollectionViewItem.m
//  TwitHunter
//
//  Created by Nicolas Seriot on 20.04.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import "TweetCollectionViewItem.h"
#import "Tweet.h"
#import "User.h"

@implementation TweetCollectionViewItem

- (IBAction)openUserWebTimeline:(id)sender {
	Tweet *tweet = [self representedObject];

	NSString *urlString = [NSString stringWithFormat:@"http://twitter.com/%@", tweet.user.screenName];
	NSURL *url = [NSURL URLWithString:urlString];
	[[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction)toggleIsRead:(id)sender {
	Tweet *tweet = [self representedObject];
	[tweet toggleIsRead];
}

@end
