//
//  THSliderView.m
//  TwitHunter
//
//  Created by Nicolas Seriot on 5/1/10.
//  Copyright 2010 seriot.ch. All rights reserved.
//

#import "THSliderView.h"


@implementation THSliderView

static CGColorRef CGColorCreateFromNSColor (CGColorSpaceRef colorSpace, NSColor *color) {
	NSColor *deviceColor = [color colorUsingColorSpaceName:NSDeviceRGBColorSpace];

	float components[4];
	[deviceColor getRed:&components[0] green:&components[1] blue:&components[2] alpha: &components[3]];

	return CGColorCreate (colorSpace, components);
}

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

	if(tweetsCount == 0) return;
	
	CGFloat height = [self bounds].size.height;
	CGFloat width = [self bounds].size.width;
	
	CGFloat heightFactor = height / 100.0;
	CGFloat widthFactor = width / tweetsCount;
	
	NSGraphicsContext *gc = [NSGraphicsContext currentContext];
	CGContextRef context = (CGContextRef)[gc graphicsPort];

	/* set pen and colors */
	
	CGContextSetAllowsAntialiasing(context, false);
	
	CGContextSetLineWidth(context, 1.0);
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

	CGColorRef cgColor1 = CGColorCreateFromNSColor(colorSpace, [NSColor colorForControlTint:NSBlueControlTint]);
	CGContextSetFillColorWithColor(context, cgColor1);
	CGColorRelease(cgColor1);

	CGColorRef cgColor2 = CGColorCreateFromNSColor(colorSpace, [NSColor blackColor]);
	CGContextSetStrokeColorWithColor(context, cgColor2);
	CGColorRelease(cgColor2);

	CGColorSpaceRelease(colorSpace);
	
	/* draw */
	
	CGContextBeginPath(context);
	
	CGContextMoveToPoint(context, width, 100.0*heightFactor);
	
	NSUInteger total = 0;
	for(NSUInteger i = 100; i > 0; i--) {
		total += array[i];
		CGContextAddLineToPoint(context, width - total*widthFactor, i*heightFactor);
	}

	CGContextAddLineToPoint(context, 0, 0);
	CGContextAddLineToPoint(context, width-1, 0);
	CGContextAddLineToPoint(context, width-1, height);
	
	CGContextDrawPath(context, kCGPathFillStroke);
	
	CGContextSetAllowsAntialiasing(context, true);
}

- (void)dealloc {
	[super dealloc];
}

@end
