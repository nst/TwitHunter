//
//  CumulativeChartView.m
//  TwitHunter
//
//  Created by Nicolas Seriot on 5/1/10.
//  Copyright 2010 seriot.ch. All rights reserved.
//

#import "CumulativeChartView.h"

@implementation CumulativeChartView

@synthesize delegate;

static CGColorRef CGColorCreateFromNSColor (CGColorSpaceRef colorSpace, NSColor *color) {
	NSColor *deviceColor = [color colorUsingColorSpaceName:NSDeviceRGBColorSpace];

	float components[4];
	[deviceColor getRed:&components[0] green:&components[1] blue:&components[2] alpha: &components[3]];

	return CGColorCreate (colorSpace, components);
}

- (void)setNumberOfTweets:(NSUInteger)nbOfTweets forScore:(NSUInteger)aScore {
	if(aScore < 0 || aScore > MAX_COUNT) return;
	
	tweetsCountForScore[aScore] = nbOfTweets;
}

- (void)setTweetsCount:(NSUInteger)count {
	totalTweets = count;
}

- (void)setScore:(NSUInteger)aScore {
	if(aScore < 0) {
		aScore = 0;
	} else if (aScore > MAX_COUNT) {
		aScore = MAX_COUNT;
	}

	score = aScore;
	[self setNeedsDisplay:YES];
}

- (void)resizeWithOldSuperviewSize:(NSSize)oldSize {
	[self removeTrackingRect:tag];
	tag = [self addTrackingRect:[self bounds] owner:self userData:nil assumeInside:NO];
	[super resizeWithOldSuperviewSize:oldSize];
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

	if(totalTweets == 0) return;
	
	CGFloat height = [self bounds].size.height;
	CGFloat width = [self bounds].size.width;
	
	CGFloat heightFactor = height / (float)MAX_COUNT;
	CGFloat widthFactor = width / totalTweets;
	
	NSGraphicsContext *gc = [NSGraphicsContext currentContext];
	CGContextRef context = (CGContextRef)[gc graphicsPort];

	/* set pen and colors */
	
	CGContextSetAllowsAntialiasing(context, false);
	
	CGContextSetLineWidth(context, 1.0);
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

	CGColorRef strokeColor = CGColorCreateFromNSColor(colorSpace, [NSColor blackColor]);
	CGContextSetStrokeColorWithColor(context, strokeColor);
	CGColorRelease(strokeColor);
	
	/* draw top */
	
	CGColorRef fillColorTop = CGColorCreateFromNSColor(colorSpace, [NSColor colorForControlTint:NSBlueControlTint]);
	CGContextSetFillColorWithColor(context, fillColorTop);
	CGColorRelease(fillColorTop);
	
	CGContextBeginPath(context);
	
	CGContextMoveToPoint(context, width, floorf(MAX_COUNT*heightFactor));
	
	//NSLog(@"--> %f", floorf(MAX_COUNT*heightFactor));
	
	NSUInteger total = 0;
	for(NSUInteger i = MAX_COUNT; i >= score; i--) {
		if(i == 0) break;
		total += tweetsCountForScore[i];
		culumatedTweetsForScore[i] = total;
		CGContextAddLineToPoint(context, width - floorf(total*widthFactor), floorf(i*heightFactor));

		//NSLog(@"--  %f %f", floorf(width - total*widthFactor), floorf(i*heightFactor));
	}

	CGContextAddLineToPoint(context, width - floor(total*widthFactor), score*heightFactor);
	CGContextAddLineToPoint(context, width-1, score*heightFactor);
	CGContextAddLineToPoint(context, width-1, 100*heightFactor-1);
	CGContextAddLineToPoint(context, width - floor(tweetsCountForScore[MAX_COUNT]*widthFactor), 100*heightFactor-1);
	
	CGContextDrawPath(context, kCGPathFillStroke);
	//CGContextClosePath(context);
	
	/* draw bottom */
	
	CGColorRef fillColorBottom = CGColorCreateFromNSColor(colorSpace, [NSColor colorForControlTint:NSGraphiteControlTint]);
	CGContextSetFillColorWithColor(context, fillColorBottom);
	CGColorRelease(fillColorBottom);
	
	CGContextBeginPath(context);
		
	CGContextMoveToPoint(context, width, floorf(score*heightFactor));
	CGContextAddLineToPoint(context, width - floorf(total*widthFactor), floorf(score*heightFactor));
	
	if(score == 100) {
		CGContextAddLineToPoint(context, width - floorf(total*widthFactor), height+1);
		CGContextAddLineToPoint(context, width, height+1);
	}
	
	for(NSUInteger i = score-1; i > 0; i--) {
		if(score == 0) {
			culumatedTweetsForScore[0] = total;
			break;
		}
		total += tweetsCountForScore[i];
		culumatedTweetsForScore[i] = total;
		CGContextAddLineToPoint(context, width - floorf(total*widthFactor), floorf(i*heightFactor));
	}

	CGContextAddLineToPoint(context, 0, 0);
	CGContextAddLineToPoint(context, width-1, 0);
	CGContextAddLineToPoint(context, width-1, height);
	
	CGContextDrawPath(context, kCGPathFillStroke);
	
	
	CGContextSetAllowsAntialiasing(context, true);
	
	CGColorSpaceRelease(colorSpace);
}

- (void)dealloc {
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
	NSPoint p = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	[self setScoreFromPoint:p];
	
    BOOL keepOn = YES;
    BOOL isInside = YES;
    NSPoint mouseLoc;
 
    while (keepOn) {
        theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
        mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        isInside = [self mouse:mouseLoc inRect:[self bounds]];
 
        switch ([theEvent type]) {
            case NSLeftMouseDragged:
				[self setScoreFromPoint:mouseLoc];
				break;
            case NSLeftMouseUp:
				if (isInside) {
					[[NSUserDefaultsController sharedUserDefaultsController]
					 setValue:[NSNumber numberWithUnsignedInteger:score]
					 forKeyPath:@"values.score"];
				}
                keepOn = NO;
                break;
            default:
                /* Ignore any other kind of event. */
                break;
        } 
		[delegate didSlideToScore:score cumulatedTweetsCount:culumatedTweetsForScore[score]];
    }
}

- (void)mouseEntered:(NSEvent *)theEvent {
	//NSLog(@"-- mouseEntered");
	[[NSCursor resizeUpDownCursor] set];
}

- (void)mouseExited:(NSEvent *)theEvent {
	//NSLog(@"-- mouseExited");
	[[NSCursor arrowCursor] set];
}

@end
