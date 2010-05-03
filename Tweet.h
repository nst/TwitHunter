//
//  Tweet.h
//  TwitHunter
//
//  Created by Nicolas Seriot on 19.04.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import <CoreData/CoreData.h>

@class User;

@interface Tweet :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSNumber * uid;
@property (nonatomic, retain) NSNumber * score;
@property (nonatomic, retain) NSNumber * isRead;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) User * user;

+ (Tweet *)tweetWithUid:(NSString *)uid;
+ (BOOL)createTweetFromDictionary:(NSDictionary *)d;
+ (unsigned long long)saveTweetsFromDictionariesArray:(NSArray *)a;
+ (NSArray *)tweetsContainingKeyword:(NSString *)keyword;
+ (NSUInteger)nbOfTweetsForScore:(NSNumber *)aScore andSubpredicates:(NSArray *)subPredicates;

@end



