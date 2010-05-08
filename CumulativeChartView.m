//
//  CumulativeChartView.m
//  TwitHunter
//
//  Created by Nicolas Seriot on 5/1/10.
//  Copyright 2010 seriot.ch. All rights reserved.
//

#import "CumulativeChartView.h"
#import "NSColor+TH.h"

#define DRAW_TOP
#define DRAW_BOTTOM

@implementation CumulativeChartView

@synthesize delegate, dataSource;

- (void)setScore:(NSUInteger)aScore {
	
	aScore = MIN(aScore, MAX_COUNT);
	aScore = MAX(0, aScore);
	
	score = aScore;
	[self setNeedsDisplay:YES];
}

- (void)resizeWithOldSuperviewSize:(NSSize)oldSize {
	[self removeTrackingRect:tag];
	tag = [self addTrackingRect:[self bounds] owner:self userData:nil assumeInside:NO];
	
	[super resizeWithOldSuperviewSize:oldSize];
}

- (void)resetCursorRects {
	[super resetCursorRects];
	
	NSCursor *cursor = [NSCursor resizeUpDownCursor];
	[self addCursorRect:[self bounds] cursor:cursor];
	[cursor setOnMouseEntered:YES];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[[self window] setAcceptsMouseMovedEvents:YES];
		tag = [self addTrackingRect:[self bounds] owner:self userData:nil assumeInside:NO];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {

	if([dataSource numberOfTweets] == 0) return;
	
	CGFloat height = [self bounds].size.height;
	CGFloat width = [self bounds].size.width;
	
	CGFloat heightFactor = height / (float)MAX_COUNT;
	CGFloat widthFactor = width / [dataSource numberOfTweets];
	
	NSGraphicsContext *gc = [NSGraphicsContext currentContext];
	CGContextRef context = (CGContextRef)[gc graphicsPort];

	/* set pen and colors */
	
	CGContextSetAllowsAntialiasing(context, false);
	
	CGContextSetLineWidth(context, 1.0);
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

	CGColorRef strokeColor = [[NSColor blackColor] newCGColorInColorSpace:colorSpace];

	CGContextSetStrokeColorWithColor(context, strokeColor);
	CGColorRelease(strokeColor);
	
	/* draw top */
	
	CGColorRef fillColorTop = [[NSColor colorForControlTint:NSBlueControlTint] newCGColorInColorSpace:colorSpace];
	CGContextSetFillColorWithColor(context, fillColorTop);
	CGColorRelease(fillColorTop);
	
	CGContextBeginPath(context);
	
	CGContextMoveToPoint(context, width, floorf(MAX_COUNT*heightFactor));
	
	NSUInteger totalFrom = 0;
	NSUInteger totalTo = 0;
	
	for(NSUInteger i = MAX_COUNT; i >= score; i--) {
		totalFrom = [dataSource cumulatedTweetsForScore:i];
		totalTo = [dataSource cumulatedTweetsForScore:i-1];
		
		CGContextAddLineToPoint(context, width - floorf(totalFrom*widthFactor), floorf(i*heightFactor));
		CGContextAddLineToPoint(context, width - floorf(totalTo*widthFactor), floorf(i*heightFactor));
		
		if(i == 0) break;
	}
	
	CGContextAddLineToPoint(context, width - floor(totalTo*widthFactor), score*heightFactor);
	CGContextAddLineToPoint(context, width-1, score*heightFactor);
	CGContextAddLineToPoint(context, width-1, MAX_COUNT*heightFactor-1);
	CGContextAddLineToPoint(context, width - floor([dataSource cumulatedTweetsForScore:MAX_COUNT]*widthFactor), MAX_COUNT*heightFactor-1);
	
#ifdef DRAW_TOP
	CGContextDrawPath(context, kCGPathFillStroke);
#else
	CGContextClosePath(context);
#endif
	
	/* draw bottom */
		
	CGColorRef fillColorBottom = [[NSColor colorForControlTint:NSGraphiteControlTint] newCGColorInColorSpace:colorSpace];
	
	CGContextSetFillColorWithColor(context, fillColorBottom);
	CGColorRelease(fillColorBottom);
	
	CGContextBeginPath(context);
	
	CGContextMoveToPoint(context, width, floorf(score*heightFactor));
	CGContextAddLineToPoint(context, width - floorf(totalTo*widthFactor), floorf(score*heightFactor));
	CGContextAddLineToPoint(context, width - floorf(totalTo*widthFactor), floorf(score*heightFactor));
	
	if(score == 100) {
		// close the top line because top drawing didn't
		CGContextAddLineToPoint(context, width - floorf(totalTo*widthFactor), height-1);
		CGContextAddLineToPoint(context, width, height-1);
	}
	
	for(NSUInteger i = score; i > 0; i--) {
		if(score == 0) {
			break;
		}
		totalFrom = [dataSource cumulatedTweetsForScore:i];
		totalTo = [dataSource cumulatedTweetsForScore:(i-1)];
		CGContextAddLineToPoint(context, width - floorf(totalFrom*widthFactor), floorf(i*heightFactor));
		CGContextAddLineToPoint(context, width - floorf(totalTo*widthFactor), floorf(i*heightFactor));
	}
	
	CGContextAddLineToPoint(context, 0, 0);
	CGContextAddLineToPoint(context, width-1, 0);
	CGContextAddLineToPoint(context, width-1, height);

#ifdef DRAW_BOTTOM
	CGContextDrawPath(context, kCGPathFillStroke);
#else
	CGContextClosePath(context);
#endif
	
	CGContextSetAllowsAntialiasing(context, true);
	
	CGColorSpaceRelease(colorSpace);
}

- (void)dealloc {
	[dataSource release];
	[delegate release];
	[super dealloc];
}

#pragma mark mouse events

- (BOOL)acceptsFirstResponder { 
	return YES; 
}

- (void)setScoreFromPoint:(NSPoint)p {
	CGFloat height = [self bounds].size.height;
	CGFloat heightFactor = height / (float)MAX_COUNT;
	NSUInteger theScore = p.y / heightFactor;
	[self setScore:theScore];
}

- (void)mouseDown:(NSEvent *)theEvent {

	NSUInteger formerScore = score;
	NSUInteger slidingScore;
	
	NSPoint p = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	[self setScoreFromPoint:p];
	
    BOOL keepOn = YES;
    NSPoint mouseLoc;
 
    while (keepOn) {
        theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
        mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
 
        switch ([theEvent type]) {
            case NSLeftMouseDragged:
				slidingScore = score;
				[self setScoreFromPoint:mouseLoc];
				if(score != slidingScore) [delegate didSlideToScore:score];
				break;
            case NSLeftMouseUp:
                keepOn = NO;
				break;
            default:
                break;
        } 
    }
	if(score != formerScore) [delegate didStopSlidingOnScore:score];
}
//
//- (void)sendValuesToDelegate {
//	[delegate didSlideToScore:score];
//}

@end
