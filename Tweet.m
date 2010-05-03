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

+ (NSUInteger)tweetsCountWithAndPredicates:(NSArray *)predicates {
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:[self entity]];
	
	NSPredicate *p = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
	[request setPredicate:p];
	
	NSError *error = nil;
	NSUInteger count = [[self moc] countForFetchRequest:request error:&error];
	[request release];
	if(error) {
		NSLog(@"-- error:%@", error);
	}
	return count;	
}

+ (NSUInteger)nbOfTweetsForScore:(NSNumber *)aScore andPredicates:(NSArray *)predicates {
	NSPredicate *p = [NSPredicate predicateWithFormat:@"score == %@", aScore];
	NSArray *ps = [predicates arrayByAddingObject:p];

	return [self tweetsCountWithAndPredicates:ps];
}

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
	NSNumber *uidNumber = [NSNumber numberWithUnsignedLongLong:[uid unsignedLongLongValue]];
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

+ (BOOL)createTweetFromDictionary:(NSDictionary *)d {	
	NSString *uid = [d objectForKey:@"id"];
	Tweet *tweet = [self tweetWithUid:uid];
	if(tweet) return NO;
	
	NSDictionary *userDictionary = [d objectForKey:@"user"];
	User *user = [User getOrCreateUserWithDictionary:userDictionary];
	
	tweet = [Tweet create];
	tweet.uid = [NSNumber numberWithUnsignedLongLong:[[d objectForKey:@"id"] unsignedLongLongValue]];
	tweet.text = [d objectForKey:@"text"];
	
	NSLog(@"-- %@ %@", [[d objectForKey:@"created_at"] className], [d objectForKey:@"created_at"]);
	
	tweet.date = [d objectForKey:@"created_at"];
	tweet.user = user;
	
	NSLog(@"** created %@", tweet.uid);
	
	return YES;
}

+ (unsigned long long)saveTweetsFromDictionariesArray:(NSArray *)a {
	unsigned long long biggestID = 0;

	for(NSDictionary *d in a) {
		BOOL success = [Tweet createTweetFromDictionary:d];
		if(success) {
			unsigned long long currentID = [[d objectForKey:@"id"] unsignedLongLongValue];
			biggestID = MAX(biggestID, currentID);
		}
	}
	
	BOOL success = [Tweet save];
	if(!success) {
		NSLog(@"-- can't save moc");
		return 0;
	}
	
	return biggestID;
}

@end
