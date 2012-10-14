//
//  THTextView.m
//  TwitHunter
//
//  Created by Nicolas Seriot on 10/13/12.
//  Copyright (c) 2012 seriot.ch. All rights reserved.
//

#import "THTextView.h"

@implementation THTextView

- (void)mouseDown:(NSEvent *)theEvent {
	NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
	NSInteger charIndex = [self characterIndexForInsertionAtPoint:point];
	
    BOOL clickOnATextCharacter = NSLocationInRange(charIndex, NSMakeRange(0, [[self string] length]));
    
	if (clickOnATextCharacter) {
		
		NSDictionary *attributes = [[self attributedString] attributesAtIndex:charIndex effectiveRange:NULL];
		
		if( [attributes objectForKey:@"LinkMatch"] != nil ) {
			NSLog( @"LinkMatch: %@", [attributes objectForKey:@"LinkMatch"] );
		}
		
		if( [attributes objectForKey:@"UsernameMatch"] != nil ) {
			NSLog( @"UsernameMatch: %@", [attributes objectForKey:@"UsernameMatch"] );
		}
		
		if( [attributes objectForKey:@"HashtagMatch"] != nil ) {
			NSLog( @"HashtagMatch: %@", [attributes objectForKey:@"HashtagMatch"] );
		}
		
	}
	
	[super mouseDown:theEvent];
}

@end
