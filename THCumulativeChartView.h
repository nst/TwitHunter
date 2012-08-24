//
//  CumulativeChartView.h
//  TwitHunter
//
//  Created by Nicolas Seriot on 5/1/10.
//  Copyright 2010 seriot.ch. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define MAX_COUNT 100

@class THCumulativeChartView;

@protocol CumulativeChartViewDelegate
- (void)chartView:(THCumulativeChartView *)aChartView didSlideToScore:(NSUInteger)aScore;
- (void)chartView:(THCumulativeChartView *)aChartView didStopSlidingOnScore:(NSUInteger)aScore;
@end

@protocol CumulativeChartViewDataSource
- (NSUInteger)numberOfTweets;
- (NSUInteger)cumulatedTweetsForScore:(NSUInteger)aScore;
@end

@interface THCumulativeChartView : NSView {
	NSUInteger score;
	
	IBOutlet NSObject <CumulativeChartViewDelegate> *delegate;
	IBOutlet NSObject <CumulativeChartViewDataSource> *dataSource;
	
	NSTrackingRectTag tag;
}

@property (nonatomic, retain) NSObject <CumulativeChartViewDelegate> *delegate;
@property (nonatomic, retain) NSObject <CumulativeChartViewDataSource> *dataSource;

- (void)setScore:(NSUInteger)aScore;

@end
