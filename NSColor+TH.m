//
//  NSColor+TH.m
//  TwitHunter
//
//  Created by Nicolas Seriot on 5/8/10.
//  Copyright 2010 seriot.ch. All rights reserved.
//

#import "NSColor+TH.h"


@implementation NSColor (TH)

- (CGColorRef)createCGColorInColorSpace:(CGColorSpaceRef)colorSpace {
	NSColor *deviceColor = [self colorUsingColorSpaceName:NSDeviceRGBColorSpace];

	float components[4];
	[deviceColor getRed:&components[0] green:&components[1] blue:&components[2] alpha: &components[3]];

	return CGColorCreate(colorSpace, components);
}

@end
