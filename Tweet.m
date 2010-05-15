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
@dynamic isFavorite;
@dynamic containsURL;

- (NSNumber *)isFavoriteWrapper {
	return self.isFavorite;
}

- (void)setIsFavoriteWrapper:(NSNumber *)n {
	BOOL flag = [n boolValue];
	NSLog(@"-- set %d", flag);
	
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:n forKey:@"value"];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"SetFavoriteFlagForTweet" object:self userInfo:userInfo];
	
	self.isFavorite = n;
	BOOL success = [self save];
	if(!success) NSLog(@"-- can't save");
}

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

+ (NSArray *)tweetsWithIdGreaterOrEqualTo:(NSNumber *)anId {
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:[self entity]];
	NSPredicate *p = [NSPredicate predicateWithFormat:@"uid >= %@", anId, nil];
	[request setPredicate:p];
	
	NSError *error = nil;
	NSArray *array = [[self moc] executeFetchRequest:request error:&error];
	if(error) {
		NSLog(@"-- error:%@", error);
	}
	[request release];
	
	return [array lastObject];
}

+ (void)unfavorFavoritesBetweenMinId:(NSNumber *)unfavorMinId maxId:(NSNumber *)unfavorMaxId {
	if([unfavorMinId isGreaterThanOrEqualTo:unfavorMaxId]) {
		NSLog(@"-- can't unfavor ids, given maxId is smaller than minId");
		return;
	}
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:[self entity]];
	NSPredicate *p = [NSPredicate predicateWithFormat:@"isFavorite == YES AND uid <= %@ AND uid >= %@", unfavorMaxId, unfavorMinId, nil];
	[request setPredicate:p];
	
	NSError *error = nil;
	NSArray *array = [[self moc] executeFetchRequest:request error:&error];
	if(error) {
		NSLog(@"-- error:%@", error);
	}
	[request release];
	
	for(Tweet *t in array) {
		t.isFavorite = [NSNumber numberWithBool:NO];
		NSLog(@"** unfavor %@", t.user.screenName);
	}
}

+ (BOOL)updateOrCreateTweetFromDictionary:(NSDictionary *)d {
	// TODO: keep lower and bigger uids and if request was favorites, then un-favorite the ones out of bounds..
	
	NSString *uid = [d objectForKey:@"id"];
	
	BOOL wasCreated = NO;
	Tweet *tweet = [self tweetWithUid:uid];
	if(!tweet) {
		tweet = [Tweet create];
		wasCreated = YES;
		tweet.uid = [NSNumber numberWithUnsignedLongLong:[[d objectForKey:@"id"] unsignedLongLongValue]];

		NSDictionary *userDictionary = [d objectForKey:@"user"];
		User *user = [User getOrCreateUserWithDictionary:userDictionary];
		
		NSMutableString *s = [d objectForKey:@"text"];
		[s replaceOccurrencesOfString:@"<" withString:@"&lt;" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
		[s replaceOccurrencesOfString:@">" withString:@"&gt;" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
		tweet.text = s;
		
		BOOL doesContainURL = [tweet.text rangeOfString:@"http"].location != NSNotFound;
		tweet.containsURL = [NSNumber numberWithBool:doesContainURL];
				
		tweet.date = [d objectForKey:@"created_at"];
		tweet.user = user;
	}
	tweet.isFavorite = [NSNumber numberWithBool:[[d objectForKey:@"favorited"] isEqualToString:@"true"]];

	NSLog(@"** created %d favorite %@ %@ %@ %@", wasCreated, tweet.isFavorite, tweet.uid, tweet.user.screenName, tweet.text);
	
	return YES;
}

+ (NSDictionary *)saveTweetsFromDictionariesArray:(NSArray *)a {
	// TODO: remove non-favorites between new favorites bounds
	
	unsigned long long lowestID = 0;
	unsigned long long highestID = 0;
		
	for(NSDictionary *d in a) {
		[Tweet updateOrCreateTweetFromDictionary:d];
		
		unsigned long long currentID = [[d objectForKey:@"id"] unsignedLongLongValue];
		highestID = MAX(highestID, currentID);
		lowestID = MIN(lowestID, currentID);
	}
	
	BOOL success = [Tweet save];
	if(!success) {
		NSLog(@"-- can't save moc");
		return 0;
	}
	
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithUnsignedLongLong:lowestID], @"lowestID",
			[NSNumber numberWithUnsignedLongLong:highestID], @"higestId", nil];
}

@end
