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
#import "NSManagedObject+ST.h"
//#import "NSColor+TH.h"
#import "THTextView.h"
#import "THTweetView.h"

@implementation THTweetCollectionViewItem

//- (void)awakeFromNib {
//
//	CALayer *layer = [CALayer layer];
//	CGColorRef color = [NSColor redColor].CGColor;
//	layer.backgroundColor = color;
//	[[self view] setLayer:layer];
//}

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

- (IBAction)retweet:(id)sender {
	THTweet *tweet = [self representedObject];
    
    NSDictionary *userInfo = @{@"Tweet" : tweet, @"Action" : @"Retweet"};
    NSNotification *notification = [NSNotification notificationWithName:@"THTweetAction" object:self userInfo:userInfo];
	[[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (IBAction)reply:(id)sender {
	THTweet *tweet = [self representedObject];
    
    NSDictionary *userInfo = @{@"Tweet" : tweet, @"Action" : @"Reply"};
    NSNotification *notification = [NSNotification notificationWithName:@"THTweetAction" object:self userInfo:userInfo];
	[[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (IBAction)remoteDelete:(id)sender {
	THTweet *tweet = [self representedObject];
    
    NSDictionary *userInfo = @{@"Tweet" : tweet, @"Action" : @"RemoteDelete"};
    NSNotification *notification = [NSNotification notificationWithName:@"THTweetAction" object:self userInfo:userInfo];
	[[NSNotificationCenter defaultCenter] postNotification:notification];
}

//- (IBAction)changeFavoriteState:(id)sender {
//	THTweet *tweet = [self representedObject];
//
//    BOOL wasFavorite = [tweet.isFavorite boolValue];
//
//    tweet.isFavorite = [NSNumber numberWithBool:!wasFavorite];
//
//    NSLog(@"-- %@ %@", tweet.uid, tweet.isFavorite);
//
//    BOOL success = [tweet save];
//	if(!success) NSLog(@"-- can't save tweet %@", tweet);
//
//	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:tweet forKey:@"Tweet"];
//
//#warning TODO: listen to favorite status change notification in controller and do the appropriate API request
//
//	NSNotification *notification = [NSNotification notificationWithName:@"DidChangeTweetFavoriteStateNotification" object:self userInfo:userInfo];
//	[[NSNotificationCenter defaultCenter] postNotification:notification];
//}

//- (IBAction)showContextMenu:(id)sender {
//    NSLog(@"-- show context menu, %@ %@", sender, NSStringFromRect([sender frame]));
//
//    NSRect frame = [(NSButton *)sender frame];
//    NSPoint menuOrigin = [[(NSButton *)sender superview] convertPoint:NSMakePoint(frame.origin.x, frame.origin.y+frame.size.height)
//                                                               toView:nil];
//
//    NSEvent *event =  [NSEvent mouseEventWithType:NSLeftMouseDown
//                                         location:menuOrigin
//                                    modifierFlags:NSLeftMouseDownMask // 0x100
//                                        timestamp:[[NSDate date] timeIntervalSince1970]
//                                     windowNumber:[[(NSButton *)sender window] windowNumber]
//                                          context:[[(NSButton *)sender window] graphicsContext]
//                                      eventNumber:0
//                                       clickCount:1
//                                         pressure:1];
//
//    NSMenu *menu = [[NSMenu alloc] init];
//    [menu insertItemWithTitle:@"add"
//                       action:@selector(add:)
//                keyEquivalent:@""
//                      atIndex:0];
//
//    [NSMenu popUpContextMenu:menu withEvent:event forView:(NSButton *)sender];
//}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
//    if(self.representedObject == nil) return;
    
//    THTweetView *tweetView = (THTweetView *)self.view;
//    
////    NSLog(@"-- %@", self.view);
////    NSLog(@"-- %@", _tweetTextTextView);
//    
//    NSString *s = [representedObject text];
//
//    [tweetView setStatus:s];
    
//    [_tweetTextTextView bind:@"attributedString" toObject:representedObject withKeyPath:@"attributedString" options:nil];
    
    //    THTweet *tweet = representedObject;
    //    NSString *text = tweet.text;
    //
    //    NSLog(@"-- %@", text);
    //
    //    if(text == nil) return;
    //
    //    [self view];
    //
    //    [_tweetTextTextView setEditable:YES];
    //    [_tweetTextTextView setAutomaticLinkDetectionEnabled:YES];
    //    [_tweetTextTextView setString:text];
    //    [_tweetTextTextView setEditable:NO];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
//    NSString *statusString = @"http://apple.com sdf @flyosity asd #hashtag dfg";
//	
//	NSMutableAttributedString *attributedStatusString = [[NSMutableAttributedString alloc] initWithString:statusString];
//    
//    
//    
//    
//    
//	// Defining our paragraph style for the tweet text. Starting with the shadow to make the text
//	// appear inset against the gray background.
//	NSShadow *textShadow = [[NSShadow alloc] init];
//	[textShadow setShadowColor:[NSColor colorWithDeviceWhite:1 alpha:.8]];
//	[textShadow setShadowBlurRadius:0];
//	[textShadow setShadowOffset:NSMakeSize(0, -1)];
//    
//	NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
//	[paragraphStyle setMinimumLineHeight:22];
//	[paragraphStyle setMaximumLineHeight:22];
//	[paragraphStyle setParagraphSpacing:0];
//	[paragraphStyle setParagraphSpacingBefore:0];
//	[paragraphStyle setTighteningFactorForTruncation:4];
//	[paragraphStyle setAlignment:NSNaturalTextAlignment];
//	[paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
//	
//	// Our initial set of attributes that are applied to the full string length
//	NSDictionary *fullAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
//									[NSColor colorWithDeviceHue:.53 saturation:.13 brightness:.26 alpha:1], NSForegroundColorAttributeName,
//									textShadow, NSShadowAttributeName,
//									[NSCursor arrowCursor], NSCursorAttributeName,
//									[NSNumber numberWithFloat:0.0], NSKernAttributeName,
//									[NSNumber numberWithInt:0], NSLigatureAttributeName,
//									paragraphStyle, NSParagraphStyleAttributeName,
//									[NSFont systemFontOfSize:11.0], NSFontAttributeName, nil];
//	[attributedStatusString addAttributes:fullAttributes range:NSMakeRange(0, [statusString length])];
//	[textShadow release];
//	[paragraphStyle release];
//    
//	// Generate arrays of our interesting items. Links, usernames, hashtags.
//	NSArray *linkMatches = [self scanStringForLinks:statusString];
//	NSArray *usernameMatches = [self scanStringForUsernames:statusString];
//	NSArray *hashtagMatches = [self scanStringForHashtags:statusString];
//	
//	// Iterate across the string matches from our regular expressions, find the range
//	// of each match, add new attributes to that range
//	for (NSString *linkMatchedString in linkMatches) {
//		NSRange range = [statusString rangeOfString:linkMatchedString];
//		if( range.location != NSNotFound ) {
//			// Add custom attribute of LinkMatch to indicate where our URLs are found. Could be blue
//			// or any other color.
//			NSDictionary *linkAttr = [[NSDictionary alloc] initWithObjectsAndKeys:
//									  [NSCursor pointingHandCursor], NSCursorAttributeName,
//									  [NSColor blueColor], NSForegroundColorAttributeName,
//									  [NSFont boldSystemFontOfSize:14.0], NSFontAttributeName,
//									  linkMatchedString, @"LinkMatch",
//									  nil];
//			[attributedStatusString addAttributes:linkAttr range:range];
//			[linkAttr release];
//		}
//	}
//	
//	for (NSString *usernameMatchedString in usernameMatches) {
//		NSRange range = [statusString rangeOfString:usernameMatchedString];
//		if( range.location != NSNotFound ) {
//			// Add custom attribute of UsernameMatch to indicate where our usernames are found
//			NSDictionary *linkAttr2 = [[NSDictionary alloc] initWithObjectsAndKeys:
//									   [NSColor blackColor], NSForegroundColorAttributeName,
//									   [NSCursor pointingHandCursor], NSCursorAttributeName,
//									   [NSFont boldSystemFontOfSize:14.0], NSFontAttributeName,
//									   usernameMatchedString, @"UsernameMatch",
//									   nil];
//			[attributedStatusString addAttributes:linkAttr2 range:range];
//			[linkAttr2 release];
//		}
//	}
//	
//	for (NSString *hashtagMatchedString in hashtagMatches) {
//		NSRange range = [statusString rangeOfString:hashtagMatchedString];
//		if( range.location != NSNotFound ) {
//			// Add custom attribute of HashtagMatch to indicate where our hashtags are found
//			NSDictionary *linkAttr3 = [[NSDictionary alloc] initWithObjectsAndKeys:
//                                       [NSColor grayColor], NSForegroundColorAttributeName,
//                                       [NSCursor pointingHandCursor], NSCursorAttributeName,
//                                       [NSFont systemFontOfSize:14.0], NSFontAttributeName,
//                                       hashtagMatchedString, @"HashtagMatch",
//                                       nil];
//			[attributedStatusString addAttributes:linkAttr3 range:range];
//			[linkAttr3 release];
//		}
//	}
//	
//    
//    
//    
//    
//    
//    
//    
//    
//    
//    
//	[_tweetTextTextView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
//	[_tweetTextTextView setBackgroundColor:[NSColor clearColor]];
//	[_tweetTextTextView setTextContainerInset:NSZeroSize];
//	[[_tweetTextTextView textStorage] setAttributedString:attributedStatusString];
//	[_tweetTextTextView setEditable:NO];
//	[_tweetTextTextView setSelectable:YES];
//    
//    [attributedStatusString release];
}

#pragma mark NSTextView delegate

- (BOOL)textView:(NSTextView*)textView clickedOnLink:(id)link
		 atIndex:(unsigned)charIndex {
	BOOL success;
	success=[[NSWorkspace sharedWorkspace] openURL: link];
	return success;
}

- (void)dealloc {
    [_tweetTextTextView release];
    [super dealloc];
}

@end
