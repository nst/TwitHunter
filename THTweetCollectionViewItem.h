//
//  TweetCollectionViewItem.h
//  TwitHunter
//
//  Created by Nicolas Seriot on 20.04.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "THTweetView.h"

@class THTextView;

@interface THTweetCollectionViewItem : NSCollectionViewItem <THTweetViewProtocol>

@property (nonatomic, retain) IBOutlet THTextView *tweetTextTextView;

- (IBAction)openUserWebTimeline:(id)sender;
- (IBAction)toggleReadState:(id)sender;
- (IBAction)markAsRead:(id)sender;

- (IBAction)retweet:(id)sender;
- (IBAction)reply:(id)sender;
- (IBAction)remoteDelete:(id)sender;

@end
