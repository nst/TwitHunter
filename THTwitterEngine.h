//
//  MGTwitterEngine+TH.h
//  TwitHunter
//
//  Created by Nicolas Seriot on 5/1/10.
//  Copyright 2010 seriot.ch. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^STTE_completionBlock_t)(NSArray *statuses);
typedef void (^STTE_errorBlock_t)(NSError *error);

@class ACAccount;

@interface THTwitterEngine : NSObject {

}

- (void)requestAccessWithCompletionBlock:(void(^)(ACAccount *twitterAccount))completionBlock errorBlock:(void(^)(NSError *error))errorBlock;

- (NSString *)username;

- (void)fetchHomeTimeline:(NSUInteger)nbTweets
        completionBlock:(STTE_completionBlock_t)completionBlock
             errorBlock:(STTE_errorBlock_t)errorBlock;

- (void)fetchHomeTimelineSinceID:(unsigned long long)sinceID
                         count:(NSUInteger)nbTweets
               completionBlock:(STTE_completionBlock_t)completionBlock
                    errorBlock:(STTE_errorBlock_t)errorBlock;

- (void)fetchFavoriteUpdatesForUsername:(NSString *)aUsername completionBlock:(STTE_completionBlock_t)completionBlock errorBlock:(STTE_errorBlock_t)errorBlock;

- (void)sendFavorite:(BOOL)favorite forStatus:(NSNumber *)statusUid completionBlock:(void(^)(BOOL favorite))completionBlock errorBlock:(void(^)(NSError *error))errorBlock;

@end
