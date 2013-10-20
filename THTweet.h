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

@property (nonatomic, strong) NSString * text;
@property (nonatomic, strong) NSNumber * uid;
@property (nonatomic, strong) NSNumber * score;
@property (nonatomic, strong) NSNumber * isRead;
//@property (nonatomic, retain) NSNumber * containsURL;
@property (nonatomic, strong) NSNumber * isFavorite;
@property (nonatomic, strong) NSDate * date;
@property (nonatomic, strong) THUser * user;

+ (THTweet *)tweetWithHighestUidInContext:(NSManagedObjectContext *)context;
+ (THTweet *)tweetWithUid:(NSString *)uid context:(NSManagedObjectContext *)context;
+ (void)unfavorFavoritesBetweenMinId:(NSNumber *)unfavorMinId maxId:(NSNumber *)unfavorMaxId context:(NSManagedObjectContext *)context;
+ (THTweet *)updateOrCreateTweetFromDictionary:(NSDictionary *)d context:(NSManagedObjectContext *)context;
+ (NSArray *)saveTweetsFromDictionariesArray:(NSArray *)a;
+ (NSArray *)tweetsContainingKeyword:(NSString *)keyword context:(NSManagedObjectContext *)context;
+ (NSUInteger)nbOfTweetsForScore:(NSNumber *)aScore andPredicates:(NSArray *)predicates context:(NSManagedObjectContext *)context;
+ (NSArray *)tweetsWithAndPredicates:(NSArray *)predicates context:(NSManagedObjectContext *)context;
+ (NSUInteger)tweetsCountWithAndPredicates:(NSArray *)predicates context:(NSManagedObjectContext *)context;
+ (NSArray *)tweetsWithIdGreaterOrEqualTo:(NSNumber *)anId context:(NSManagedObjectContext *)context;

- (NSAttributedString *)attributedString;

@end
