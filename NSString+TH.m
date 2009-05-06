//
//  NSString+TH.m
//  TwitHunter
//
//  Created by Nicolas Seriot on 06.05.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import "NSString+TH.h"


@implementation NSString (TH)

- (NSAttributedString *)textWithURLs {
	NSMutableAttributedString *as = [[NSMutableAttributedString alloc] initWithString:self];
	
	NSString *string = self;
	NSRange searchRange = NSMakeRange(0, [string length]);
	NSRange foundRange;
	
	[as beginEditing];
	do {
		foundRange=[string rangeOfString:@"http://" options:0 range:searchRange];
		
		if (foundRange.length > 0) {
			searchRange.location = foundRange.location + foundRange.length;
			searchRange.length = [string length] - searchRange.location;
			
			NSRange endOfURLRange = [string rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] options:0 range:searchRange];
			
			if (endOfURLRange.length==0) {
				endOfURLRange.location = [string length];
			}
			
			foundRange.length = endOfURLRange.location - foundRange.location;
			
			NSURL *url = [NSURL URLWithString:[string substringWithRange:foundRange]];
			
			NSDictionary *linkAttributes= [NSDictionary dictionaryWithObjectsAndKeys:
										   url, NSLinkAttributeName,
										   [NSNumber numberWithInt:NSSingleUnderlineStyle], NSUnderlineStyleAttributeName,
										   [NSColor blueColor], NSForegroundColorAttributeName,
										   [NSCursor pointingHandCursor], NSCursorAttributeName, NULL];
			
			[as addAttributes:linkAttributes range:foundRange];
		}
		
	} while (foundRange.length!=0);
	
	[as endEditing];
	return [as autorelease];
}

@end
