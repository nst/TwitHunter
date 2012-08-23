//
//  MGTwitterEngine+TH.h
//  TwitHunter
//
//  Created by Nicolas Seriot on 5/1/10.
//  Copyright 2010 seriot.ch. All rights reserved.
//

typedef void (^STTE_completionBlock_t)(NSArray *statuses);
typedef void (^STTE_errorBlock_t)(NSError *error);

@interface STTwitterEngine : NSObject {

}

- (void)requestAccessWithCompletionBlock:(void(^)())completionBlock errorBlock:(void(^)(NSError *))errorBlock;

- (NSString *)username;

- (void)getHomeTimeline:(NSUInteger)nbTweets
        completionBlock:(STTE_completionBlock_t)completionBlock
             errorBlock:(STTE_errorBlock_t)errorBlock;

- (void)getHomeTimelineSinceID:(unsigned long long)sinceID
                         count:(NSUInteger)nbTweets
               completionBlock:(STTE_completionBlock_t)completionBlock
                    errorBlock:(STTE_errorBlock_t)errorBlock;

- (void)getFavoriteUpdatesForUsername:(NSString *)aUsername completionBlock:(STTE_completionBlock_t)completionBlock errorBlock:(STTE_errorBlock_t)errorBlock;

//- (NSArray *)getHomeTimelineSinceID:(NSUInteger)since_id count:(NSUInteger)count;
//
//- (NSString *)getFavoriteUpdatesFor:(NSString *)username startingAtPage:(NSUInteger)page;
//- (NSString *)markUpdate:(NSUInteger)updatedID asFavorite:(BOOL)favorite;

@end
