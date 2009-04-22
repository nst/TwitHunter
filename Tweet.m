// 
//  Tweet.m
//  TwitHunter
//
//  Created by Nicolas Seriot on 19.04.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import "NSManagedObject+TH.h"

#import "Tweet.h"
#import "User.h"

@implementation Tweet 

@dynamic text;
@dynamic uid;
@dynamic score;
@dynamic date;
@dynamic user;
@dynamic isRead;

- (void)toggleIsRead {
	self.isRead = [NSNumber numberWithBool:![self.isRead boolValue]];
	NSLog(@"-- %@ %@", self.uid, self.isRead);
}

+ (NSArray *)tweetsContainingKeyword:(NSString *)keyword {

	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:[self entity]];
	NSPredicate *p = [NSPredicate predicateWithFormat:@"text contains[c] %@" argumentArray:[NSArray arrayWithObject:keyword]];
	[request setPredicate:p];
	
	NSError *error = nil;
	NSArray *array = [[self moc] executeFetchRequest:request error:&error];
	if(error) {
		NSLog(@"-- error:%@", error);
	}
	return array;
}

+ (Tweet *)twitFromDictionary:(NSDictionary *)d {
	NSNumber *uid = [d objectForKey:@"id"];
	
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:[self entity]];
	NSPredicate *p = [NSPredicate predicateWithFormat:@"uid == %@", uid, nil];
	[request setPredicate:p];
	[request setFetchLimit:1];
	
	NSError *error = nil;
	NSArray *array = [[self moc] executeFetchRequest:request error:&error];
	if(error) {
		NSLog(@"-- error:%@", error);
	}
	
	Tweet *tweet = [array lastObject];
	
	if(tweet) return tweet;
	
	NSDictionary *userDictionary = [d objectForKey:@"user"];
	User *user = [User getOrCreateUserWithDictionary:userDictionary];
	
	tweet = [NSEntityDescription insertNewObjectForEntityForName:@"Tweet" inManagedObjectContext:[self moc]];

	tweet.text = [d objectForKey:@"text"];
	tweet.uid = [d objectForKey:@"id"];
	tweet.date = [d objectForKey:@"created_at"];
	tweet.user = user;
	return tweet;
}

+ (void)saveTwittsFromDictionariesArray:(NSArray *)a {
	for(NSDictionary *d in a) {
		[self twitFromDictionary:d];
	}
	[[self moc] save:nil];	
}

@end
