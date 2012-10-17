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
#import "THTextView.h"

@implementation THTweetCollectionViewItem

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [_tweetTextTextView setEditable:NO];
    [_tweetTextTextView setSelectable:YES];
    [_tweetTextTextView setDrawsBackground:NO];
//    [_tweetTextTextView setRichText:YES];
    
//	CALayer *layer = [CALayer layer];
//	CGColorRef color = [NSColor redColor].CGColor;
//	layer.backgroundColor = color;
//	[[self view] setLayer:layer];
}

- (IBAction)openUserWebTimeline:(id)sender {
	THTweet *tweet = [self representedObject];
    
	NSString *urlString = [NSString stringWithFormat:@"http://twitter.com/%@", tweet.user.screenName];
	NSURL *url = [NSURL URLWithString:urlString];
	[[NSWorkspace sharedWorkspace] openURL:url];
}

- (void)setReadState:(BOOL)isRead {
    THTweet *tweet = [self representedObject];

    tweet.isRead = @(isRead);
	
    NSLog(@"-- %@ %@", tweet.uid, tweet.isRead);
	
    BOOL success = [tweet save];
	if(!success) NSLog(@"-- can't save tweet %@", tweet);
	
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:tweet forKey:@"Tweet"];
	
	NSNotification *notification = [NSNotification notificationWithName:@"DidChangeTweetReadStateNotification" object:self userInfo:userInfo];
	[[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (IBAction)toggleReadState:(id)sender {
	THTweet *tweet = [self representedObject];
    
    BOOL wasRead = [tweet.isRead boolValue];
    
    [self setReadState:!wasRead];
}

- (IBAction)markAsRead:(id)sender {
    [self setReadState:YES];
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
    
//    NSLog(@"-- setRepresentedObject");
    
    THTweetView *tweetView = (THTweetView *)(self.view);
    
    tweetView.delegate = self;
    
    if(representedObject == nil) return;
    
//    [_tweetTextTextView bind:@"attributedString" toObject:representedObject withKeyPath:@"attributedString" options:nil];
    
    NSAttributedString *as = [representedObject attributedString];
    
    if(as == nil) return;
    
    [[_tweetTextTextView textStorage] setAttributedString:as];
}

#pragma mark THTweetViewProtocol

- (void)tweetViewWasClicked:(THTweetView *)tweetView {
//    [self toggleSelection:self];
    
    [self setReadState:YES];
}

@end
