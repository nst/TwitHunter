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
#import "NSManagedObject+TH.h"

@implementation TweetCollectionViewItem

- (void)awakeFromNib {
	//[textView setAutomaticLinkDetectionEnabled:YES];
}

- (IBAction)openUserWebTimeline:(id)sender {
	Tweet *tweet = [self representedObject];

	NSString *urlString = [NSString stringWithFormat:@"http://twitter.com/%@", tweet.user.screenName];
	NSURL *url = [NSURL URLWithString:urlString];
	[[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction)reloadTweetsFilter:(id)sender {
	Tweet *tweet = [self representedObject];
	NSLog(@"-- %@ %@", tweet.uid, tweet.isRead);
	BOOL success = [tweet save];
	if(!success) NSLog(@"-- can't save tweet %@", tweet);
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"ReloadTweetsFilter" object:self]];
}

#pragma mark NSTextView delegate

- (BOOL)textView:(NSTextView*)textView clickedOnLink:(id)link 
		 atIndex:(unsigned)charIndex {
	BOOL success;
	success=[[NSWorkspace sharedWorkspace] openURL: link];
	return success;
}

@end
