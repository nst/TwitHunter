//
//  TweetCollectionViewItem.m
//  TwitHunter
//
//  Created by Nicolas Seriot on 20.04.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import "THTweetCollectionViewItem.h"
#import "THTweet.h"
#import "THUser.h"
#import "NSManagedObject+SingleContext.h"
//#import "NSColor+TH.h"

@implementation THTweetCollectionViewItem

- (void)awakeFromNib {
	//[textView setAutomaticLinkDetectionEnabled:YES];

//	CALayer *layer = [CALayer layer];
//	CGColorRef color = [[NSColor redColor] copyAsCGColor];
//	layer.backgroundColor = color;
//	CGColorRelease(color);
//	[[self view] setLayer:layer];
}

- (IBAction)openUserWebTimeline:(id)sender {
	THTweet *tweet = [self representedObject];

	NSString *urlString = [NSString stringWithFormat:@"http://twitter.com/%@", tweet.user.screenName];
	NSURL *url = [NSURL URLWithString:urlString];
	[[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction)changeReadState:(id)sender {
	THTweet *tweet = [self representedObject];
    
    BOOL wasRead = [tweet.isRead boolValue];
    
    tweet.isRead = [NSNumber numberWithBool:!wasRead];
	
    NSLog(@"-- %@ %@", tweet.uid, tweet.isRead);
	
    BOOL success = [tweet save];
	if(!success) NSLog(@"-- can't save tweet %@", tweet);
	
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:tweet forKey:@"Tweet"];
	
	NSNotification *notification = [NSNotification notificationWithName:@"DidChangeTweetReadStateNotification" object:self userInfo:userInfo];
	[[NSNotificationCenter defaultCenter] postNotification:notification];
}

//- (IBAction)showContextMenu:(id)sender {
//    NSLog(@"-- show context menu, %@ %@", sender, NSStringFromRect([sender frame]));
//    
//    NSMenu *menu = [[[NSMenu alloc] initWithTitle:@"Contextual Menu"] autorelease];
//    [menu insertItemWithTitle:@"Beep" action:@selector(beep:) keyEquivalent:@"" atIndex:0];
//    [menu insertItemWithTitle:@"Honk" action:@selector(honk:) keyEquivalent:@"" atIndex:1];
//    
//    NSPopUpButtonCell *popUpButtonCell = [[[NSPopUpButtonCell alloc] initTextCell:@"" pullsDown:NO] autorelease];
//    [popUpButtonCell setFra]
//    [popUpButtonCell setMenu:menu];
//    
//    [popUpButtonCell performClickWithFrame:[sender frame] inView:[self collectionView]];
//}

#pragma mark NSTextView delegate

- (BOOL)textView:(NSTextView*)textView clickedOnLink:(id)link 
		 atIndex:(unsigned)charIndex {
	BOOL success;
	success=[[NSWorkspace sharedWorkspace] openURL: link];
	return success;
}

- (void)dealloc {
    [_textView release];
    [super dealloc];
}

@end
