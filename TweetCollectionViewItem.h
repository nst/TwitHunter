//
//  TweetCollectionViewItem.h
//  TwitHunter
//
//  Created by Nicolas Seriot on 20.04.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TweetCollectionViewItem : NSCollectionViewItem {
	IBOutlet NSTextView *textView;
}

- (IBAction)openUserWebTimeline:(id)sender;
- (IBAction)changeReadState:(id)sender;

@end
