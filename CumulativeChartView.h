//
//  CumulativeChartView.h
//  TwitHunter
//
//  Created by Nicolas Seriot on 5/1/10.
//  Copyright 2010 seriot.ch. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define MAX_COUNT 100

@interface CumulativeChartView : NSView {
	NSUInteger array[MAX_COUNT+1];
	NSUInteger tweetsCount;
	NSUInteger score;
}

- (void)setNumberOfTweets:(NSUInteger)nbOfTweets forScore:(NSUInteger)aScore;
- (void)setTweetsCount:(NSUInteger)count;
- (void)setScore:(NSUInteger)aScore;

@end
