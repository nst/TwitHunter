//
//  TweetCollectionViewItem.h
//  TwitHunter
//
//  Created by Nicolas Seriot on 20.04.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface THTweetCollectionViewItem : NSCollectionViewItem

@property (nonatomic, retain) IBOutlet NSTextView *textView;

- (IBAction)openUserWebTimeline:(id)sender;
- (IBAction)changeReadState:(id)sender;

- (IBAction)retweet:(id)sender;
- (IBAction)reply:(id)sender;
- (IBAction)remoteDelete:(id)sender;

@end
