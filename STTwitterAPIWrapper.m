//
//  STTwitterAPI.m
//  STTwitterRequests
//
//  Created by Nicolas Seriot on 9/18/12.
//  Copyright (c) 2012 Nicolas Seriot. All rights reserved.
//

#import "STTwitterAPIWrapper.h"

@interface STTwitterAPIWrapper ()
@property (nonatomic, retain) NSObject <STOAuthProtocol> *oauth;
@end

@implementation STTwitterAPIWrapper

+ (STTwitterAPIWrapper *)twitterAPIWithOAuthService:(NSObject <STOAuthProtocol> *)oauth {
    STTwitterAPIWrapper *twitter = [[STTwitterAPIWrapper alloc] init];
    twitter.oauth = oauth;
    return [twitter autorelease];
}

- (void)dealloc {
    [_oauth release];
    [super dealloc];
}

/**/

- (void)postDestroyStatusWithID:(NSString *)statusID
                   successBlock:(void(^)(NSString *jsonString))successBlock
                     errorBlock:(void(^)(NSError *error))errorBlock {
    
    // set trim_user to true?
    
    NSString *resource = [NSString stringWithFormat:@"statuses/destroy/%@.json", statusID];
    
    [_oauth postResource:resource parameters:nil successBlock:^(NSString *response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)postStatusUpdate:(NSString *)status
       inReplyToStatusID:(NSString *)optionalExistingStatusID
            successBlock:(void(^)(NSString *response))successBlock
              errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSMutableDictionary *md = [NSMutableDictionary dictionaryWithObject:status forKey:@"status"];
    
    if(optionalExistingStatusID) {
        [md setObject:optionalExistingStatusID forKey:@"in_reply_to_status_id"];
    }
    
    [_oauth postResource:@"statuses/update.json" parameters:md successBlock:^(NSString *response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)getHomeTimelineSinceID:(NSString *)optionalSinceID
                         count:(NSString *)optionalCount
                  successBlock:(void(^)(NSString *response))successBlock
                    errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    if(optionalSinceID) [md setObject:optionalSinceID forKey:@"since_id"];
    if(optionalCount) [md setObject:optionalCount forKey:@"count"];
    
    [_oauth getResource:@"statuses/home_timeline.json" parameters:md successBlock:^(NSString *response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)getFollowersWithScreenName:(NSString *)screenName
                      successBlock:(void(^)(NSString *response))successBlock
                        errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSDictionary *d = @{@"screen_name" : screenName};
    
    [_oauth getResource:@"followers/ids.json" parameters:d successBlock:^(NSString *response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)getSearchTweetsWithQuery:(NSString *)q successBlock:(void(^)(NSString *jsonString))successBlock errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSDictionary *d = @{@"q" : q};
    
    [_oauth getResource:@"search/tweets.json" parameters:d successBlock:^(NSString *response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)getAccountVerifyCredentialsSkipStatus:(BOOL)skipStatus successBlock:(void(^)(NSString *jsonString))successBlock errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSDictionary *d = @{@"skip_status" : (skipStatus ? @"true" : @"false")};
    
    [_oauth getResource:@"account/verify_credentials.json" parameters:d successBlock:^(NSString *response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)getFavoritesListWithSuccessBlock:(void(^)(NSString *jsonString))successBlock
                              errorBlock:(void(^)(NSError *error))errorBlock {
    
    [_oauth getResource:@"favorites/list.json" parameters:nil successBlock:^(NSString *response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)postFavoriteState:(BOOL)favoriteState
              forStatusID:(NSString *)statusID
             successBlock:(void(^)(NSString *jsonString))successBlock
               errorBlock:(void(^)(NSError *error))errorBlock {
    
    NSString *action = favoriteState ? @"create" : @"destroy";
    
    NSString *resource = [NSString stringWithFormat:@"favorites/%@.json", action];
    
    NSDictionary *d = @{@"id" : statusID};
    
    [_oauth postResource:resource parameters:d successBlock:^(NSString *response) {
        successBlock(response);
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

@end
