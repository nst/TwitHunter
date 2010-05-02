//
//  CumulativeChartView.m
//  TwitHunter
//
//  Created by Nicolas Seriot on 5/1/10.
//  Copyright 2010 seriot.ch. All rights reserved.
//

#import "CumulativeChartView.h"

@implementation CumulativeChartView

static CGColorRef CGColorCreateFromNSColor (CGColorSpaceRef colorSpace, NSColor *color) {
	NSColor *deviceColor = [color colorUsingColorSpaceName:NSDeviceRGBColorSpace];

	float components[4];
	[deviceColor getRed:&components[0] green:&components[1] blue:&components[2] alpha: &components[3]];

	return CGColorCreate (colorSpace, components);
}

- (void)setNumberOfTweets:(NSUInteger)nbOfTweets forScore:(NSUInteger)aScore {
	if(aScore < 0 || aScore > MAX_COUNT) return;
	
	array[aScore] = nbOfTweets;
}

- (void)setTweetsCount:(NSUInteger)count {
	tweetsCount = count;
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

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[[self window] setAcceptsMouseMovedEvents:YES];
		[self addTrackingRect:[self bounds] owner:self userData:nil assumeInside:NO];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {

	if(tweetsCount == 0) return;
	
	CGFloat height = [self bounds].size.height;
	CGFloat width = [self bounds].size.width;
	
	CGFloat heightFactor = height / (float)MAX_COUNT;
	CGFloat widthFactor = width / tweetsCount;
	
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
	
	CGContextMoveToPoint(context, width, MAX_COUNT*heightFactor);
	
	NSUInteger total = 0;
	for(NSUInteger i = MAX_COUNT; i > score; i--) {
		total += array[i];
		CGContextAddLineToPoint(context, width - total*widthFactor, i*heightFactor);
	}

	CGContextAddLineToPoint(context, width - total*widthFactor, score*heightFactor);
	CGContextAddLineToPoint(context, width-1, score*heightFactor);
	
	CGContextDrawPath(context, kCGPathFillStroke);
	
	/* draw bottom */
	
	CGColorRef fillColorBottom = CGColorCreateFromNSColor(colorSpace, [NSColor colorForControlTint:NSGraphiteControlTint]);
	CGContextSetFillColorWithColor(context, fillColorBottom);
	CGColorRelease(fillColorBottom);
	
	CGContextBeginPath(context);
	
	CGContextMoveToPoint(context, width, (score+1)*heightFactor);
	CGContextAddLineToPoint(context, width, score*heightFactor);
	
	for(NSUInteger i = score; i > 0; i--) {
		total += array[i];
		CGContextAddLineToPoint(context, width - total*widthFactor, i*heightFactor);
	}

	CGContextAddLineToPoint(context, 0, 0);
	CGContextAddLineToPoint(context, width-1, 0);
	CGContextAddLineToPoint(context, width-1, height);
	
	CGContextDrawPath(context, kCGPathFillStroke);
	
	
	CGContextSetAllowsAntialiasing(context, true);
	
	CGColorSpaceRelease(colorSpace);
}

- (void)dealloc {
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
    }
}

- (void)mouseEntered:(NSEvent *)theEvent {
	NSLog(@"-- mouseEntered");
	[[NSCursor resizeUpDownCursor] set];
}

- (void)mouseExited:(NSEvent *)theEvent {
	NSLog(@"-- mouseExited");
	[[NSCursor arrowCursor] set];
}

@end
