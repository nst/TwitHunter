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
			NSLog( @"LinkMatch: %@", [attributes objectForKey:@"LinkMatch"]);
            NSString *urlString = [attributes objectForKey:@"LinkMatch"];
            NSURL *url = [NSURL URLWithString:urlString];
            [[NSWorkspace sharedWorkspace] openURL:url];
		}
		
		if( [attributes objectForKey:@"UsernameMatch"] != nil ) {
			NSLog( @"UsernameMatch: %@", [attributes objectForKey:@"UsernameMatch"] );
            NSString *username = [attributes objectForKey:@"LinkMatch"];
            NSString *urlString = [NSString stringWithFormat:@"http://www.twitter.com/%@", username];
            NSURL *url = [NSURL URLWithString:urlString];
            [[NSWorkspace sharedWorkspace] openURL:url];
		}
		
		if( [attributes objectForKey:@"HashtagMatch"] != nil ) {
			NSLog( @"HashtagMatch: %@", [attributes objectForKey:@"HashtagMatch"] );
            NSString *hashtag = [attributes objectForKey:@"HashtagMatch"];
            hashtag = [hashtag stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSString *escapedHashtag = [hashtag stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

            // https://twitter.com/search?q=%23free&src=hash
            
            NSString *urlString = [NSString stringWithFormat:@"https://twitter.com/search?q=%@&src=hash", escapedHashtag];
            NSURL *url = [NSURL URLWithString:urlString];
            [[NSWorkspace sharedWorkspace] openURL:url];
		}
		
	}
	
	[super mouseDown:theEvent];
}

@end
