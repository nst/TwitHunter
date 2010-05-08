//
//  NSColor+TH.m
//  TwitHunter
//
//  Created by Nicolas Seriot on 5/8/10.
//  Copyright 2010 seriot.ch. All rights reserved.
//

#import "NSColor+TH.h"


@implementation NSColor (TH)

- (CGColorRef)copyAsCGColor {
	NSColor *deviceColor = [self colorUsingColorSpaceName:NSDeviceRGBColorSpace];

	float components[4];
	[deviceColor getRed:&components[0] green:&components[1] blue:&components[2] alpha: &components[3]];

	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGColorRef cgColor = CGColorCreate(colorSpace, components);
	CGColorSpaceRelease(colorSpace);

	return cgColor;
}

@end
