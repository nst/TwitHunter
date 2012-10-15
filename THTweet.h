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
//@property (nonatomic, retain) NSNumber * containsURL;
@property (nonatomic, retain) NSNumber * isFavorite;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) THUser * user;

+ (THTweet *)tweetWithHighestUidInContext:(NSManagedObjectContext *)context;
+ (THTweet *)tweetWithUid:(NSString *)uid context:(NSManagedObjectContext *)context;
+ (void)unfavorFavoritesBetweenMinId:(NSNumber *)unfavorMinId maxId:(NSNumber *)unfavorMaxId context:(NSManagedObjectContext *)context;
+ (BOOL)updateOrCreateTweetFromDictionary:(NSDictionary *)d context:(NSManagedObjectContext *)context;
+ (NSDictionary *)saveTweetsFromDictionariesArray:(NSArray *)a;
+ (NSArray *)tweetsContainingKeyword:(NSString *)keyword context:(NSManagedObjectContext *)context;
+ (NSUInteger)nbOfTweetsForScore:(NSNumber *)aScore andPredicates:(NSArray *)predicates context:(NSManagedObjectContext *)context;
+ (NSArray *)tweetsWithAndPredicates:(NSArray *)predicates context:(NSManagedObjectContext *)context;
+ (NSUInteger)tweetsCountWithAndPredicates:(NSArray *)predicates context:(NSManagedObjectContext *)context;
+ (NSArray *)tweetsWithIdGreaterOrEqualTo:(NSNumber *)anId context:(NSManagedObjectContext *)context;

- (NSAttributedString *)attributedString;

@end
