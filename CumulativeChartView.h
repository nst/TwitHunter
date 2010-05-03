//
//  CumulativeChartView.h
//  TwitHunter
//
//  Created by Nicolas Seriot on 5/1/10.
//  Copyright 2010 seriot.ch. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define MAX_COUNT 100

@protocol CumulativeChartViewDelegate
- (void)didSlideToScore:(NSUInteger)aScore cumulatedTweetsCount:(NSUInteger)cumulatedTweetsCount;
@end


@interface CumulativeChartView : NSView {
	NSUInteger tweetsCountForScore[MAX_COUNT+1];
	NSUInteger culumatedTweetsForScore[MAX_COUNT+1];
	NSUInteger totalTweets;
	NSUInteger score;
	
	NSObject <CumulativeChartViewDelegate> *delegate;
	
	NSTrackingRectTag tag;
	NSCursor *cursor;
}

@property (nonatomic, retain) NSObject <CumulativeChartViewDelegate> *delegate;
@property (nonatomic, retain) NSCursor *cursor;

- (void)setNumberOfTweets:(NSUInteger)nbOfTweets forScore:(NSUInteger)aScore;
- (void)setTweetsCount:(NSUInteger)count;
- (void)setScore:(NSUInteger)aScore;

@end
