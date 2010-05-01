//
//  THSliderView.m
//  TwitHunter
//
//  Created by Nicolas Seriot on 5/1/10.
//  Copyright 2010 seriot.ch. All rights reserved.
//

#import "THSliderView.h"


@implementation THSliderView

- (void)setNumberOfTweets:(NSUInteger)nbOfTweets forScore:(NSUInteger)score {
	if(score < 0 || score > 100) return;
	
	array[score] = nbOfTweets;
}

- (void)setTweetsCount:(NSUInteger)count {
	tweetsCount = count;
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		//
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {

	CGFloat heightFactor = [self bounds].size.height / 100.0;
	CGFloat widthFactor = [self bounds].size.width / tweetsCount;
	
	NSGraphicsContext *gc =[NSGraphicsContext currentContext];
	CGContextRef context = (CGContextRef)[gc graphicsPort];
	CGContextBeginPath(context);
	
	CGContextMoveToPoint(context, 0.0, 100.0*heightFactor);
	
	NSUInteger total = 0;
	for(NSUInteger i = 101; i > 0; i--) {
		total += array[i-1];
		CGContextAddLineToPoint(context, total*widthFactor, i*heightFactor);
	}

	CGContextDrawPath(context, kCGPathStroke);
}

- (void)dealloc {
	[super dealloc];
}

@end
