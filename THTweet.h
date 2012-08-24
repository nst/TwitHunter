//
//  Tweet.h
//  TwitHunter
//
//  Created by Nicolas Seriot on 19.04.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import <CoreData/CoreData.h>

@class THUser;

@interface THTweet :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSNumber * uid;
@property (nonatomic, retain) NSNumber * score;
@property (nonatomic, retain) NSNumber * isRead;
@property (nonatomic, retain) NSNumber * containsURL;
@property (nonatomic, retain) NSNumber * isFavorite;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) THUser * user;

+ (THTweet *)tweetWithUid:(NSString *)uid;
+ (void)unfavorFavoritesBetweenMinId:(NSNumber *)unfavorMinId maxId:(NSNumber *)unfavorMaxId;
+ (BOOL)updateOrCreateTweetFromDictionary:(NSDictionary *)d;
+ (NSDictionary *)saveTweetsFromDictionariesArray:(NSArray *)a;
+ (NSArray *)tweetsContainingKeyword:(NSString *)keyword;
+ (NSUInteger)nbOfTweetsForScore:(NSNumber *)aScore andPredicates:(NSArray *)predicates;
+ (NSUInteger)tweetsCountWithAndPredicates:(NSArray *)predicates;
+ (NSArray *)tweetsWithIdGreaterOrEqualTo:(NSNumber *)anId;

@end



