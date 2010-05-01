// 
//  Tweet.m
//  TwitHunter
//
//  Created by Nicolas Seriot on 19.04.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import "NSManagedObject+TH.h"
#import "NSString+TH.h"
#import "Tweet.h"
#import "User.h"

@implementation Tweet 

@dynamic text;
@dynamic uid;
@dynamic score;
@dynamic date;
@dynamic user;
@dynamic isRead;
/*
- (NSAttributedString *)textWithURLs {

	NSMutableAttributedString *as = [[NSMutableAttributedString alloc] initWithString:self.text];
	
	NSString *string=self.text;
	NSRange searchRange=NSMakeRange(0, [string length]);
	NSRange foundRange;
	
	[as beginEditing];
	do {
		//We assume that all URLs start with http://
		foundRange=[string rangeOfString:@"http://" options:0 range:searchRange];
		
		if (foundRange.length > 0) {
			searchRange.location = foundRange.location + foundRange.length;
			searchRange.length = [string length] - searchRange.location;
			
			//We assume the URL ends with whitespace
			NSRange endOfURLRange = [string rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] options:0 range:searchRange];
			
			//The URL could also end at the end of the text.  The next line fixes it in case it does
			if (endOfURLRange.length==0) {
				endOfURLRange.location = [string length];
			}
			
			foundRange.length = endOfURLRange.location-foundRange.location;
			
			NSURL *theURL = [NSURL URLWithString:[string substringWithRange:foundRange]];
			
			NSDictionary *linkAttributes= [NSDictionary dictionaryWithObjectsAndKeys:
										   theURL, NSLinkAttributeName,
										   [NSNumber numberWithInt:NSSingleUnderlineStyle], NSUnderlineStyleAttributeName,
										   [NSColor blueColor], NSForegroundColorAttributeName,
										   [NSCursor pointingHandCursor], NSCursorAttributeName, NULL];
			
			[as addAttributes:linkAttributes range:foundRange];
		}
		
	} while (foundRange.length!=0);
	
	[as endEditing];
	return [as autorelease];
}
*/
+ (NSArray *)tweetsContainingKeyword:(NSString *)keyword {

	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:[self entity]];
	NSPredicate *p = [NSPredicate predicateWithFormat:@"text contains[c] %@" argumentArray:[NSArray arrayWithObject:keyword]];
	[request setPredicate:p];
	
	NSError *error = nil;
	NSArray *array = [[self moc] executeFetchRequest:request error:&error];
	if(error) {
		NSLog(@"-- error:%@", error);
	}
	[request release];
	return array;
}

+ (Tweet *)tweetWithUid:(NSString *)uid {	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:[self entity]];
	NSNumber *uidNumber = [NSNumber numberWithUnsignedInteger:[uid longLongValue]];
	NSPredicate *p = [NSPredicate predicateWithFormat:@"uid == %@", uidNumber, nil];
	[request setPredicate:p];
	[request setFetchLimit:1];
	
	NSError *error = nil;
	NSArray *array = [[self moc] executeFetchRequest:request error:&error];
	if(error) {
		NSLog(@"-- error:%@", error);
	}
	[request release];
	
	return [array lastObject];
}

+ (Tweet *)createTweetFromDictionary:(NSDictionary *)d {
	//NSLog(@"-- twitFromDictionary");
	
	NSString *uid = [d objectForKey:@"id"];
	Tweet *tweet = [self tweetWithUid:uid];
	if(tweet) return nil;
	
	NSDictionary *userDictionary = [d objectForKey:@"user"];
	User *user = [User getOrCreateUserWithDictionary:userDictionary];
	
	tweet = [Tweet create];
	tweet.uid = [NSNumber numberWithUnsignedInteger:[[d objectForKey:@"id"] longLongValue]];
	tweet.text = [d objectForKey:@"text"];
	tweet.date = [d objectForKey:@"created_at"];
	tweet.user = user;
	
	return tweet;
}

+ (void)saveTweetsFromDictionariesArray:(NSArray *)a {
	for(NSDictionary *d in a) {
		Tweet *t = [Tweet createTweetFromDictionary:d];
		if(!t) NSLog(@"-- can't create tweet with dictionary: %@", d);
	}
	BOOL success = [Tweet save];
	if(!success) NSLog(@"-- can't save moc");
}

@end
