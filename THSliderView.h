//
//  THSliderView.h
//  TwitHunter
//
//  Created by Nicolas Seriot on 5/1/10.
//  Copyright 2010 seriot.ch. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface THSliderView : NSView {
//	NSMutableArray *array;
	NSUInteger array[101];
	NSUInteger tweetsCount;
}

- (void)setNumberOfTweets:(NSUInteger)nbOfTweets forScore:(NSUInteger)score;
- (void)setTweetsCount:(NSUInteger)count;

@end
