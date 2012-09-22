//
//  STTwitterAPI.h
//  STTwitterRequests
//
//  Created by Nicolas Seriot on 9/18/12.
//  Copyright (c) 2012 Nicolas Seriot. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STOAuthProtocol.h"

/*
 Partial Objective-C front-end for https://dev.twitter.com/docs/api/1.1
 */

/*
 FWIW Twitter.app for iOS 5 implements this:
 https://api.twitter.com/1/statuses/update.json
 https://upload.twitter.com/1/statuses/update_with_media.json
 https://api.twitter.com/1/geo/nearby_places.json
 https://api.twitter.com/1/friendships/show.json
 https://api.twitter.com/1/statuses/friends.json
 https://api.twitter.com/1/help/configuration.json
 https://api.twitter.com/1/apps/configuration.json
 https://api.twitter.com/1/users/show.json
 https://api.twitter.com/1/account/verify_credentials.json
 */

@interface STTwitterAPIWrapper : NSObject

+ (STTwitterAPIWrapper *)twitterAPIWithOAuthService:(NSObject <STOAuthProtocol> *)oauth;

#pragma mark Timelines

// GET statuses/mentions_timeline

// GET statuses/user_timeline

// GET statuses/home_timeline
- (void)getHomeTimelineSinceID:(NSString *)optionalSinceID
                         count:(NSString *)optionalCount
                  successBlock:(void(^)(NSString *response))successBlock
                    errorBlock:(void(^)(NSError *error))errorBlock;

#pragma mark Tweets

// GET statuses/retweets/:id

// GET statuses/show/:id

// POST statuses/destroy/:id
- (void)postDestroyStatusWithID:(NSString *)statusID
                   successBlock:(void(^)(NSString *response))successBlock
                     errorBlock:(void(^)(NSError *error))errorBlock;

// POST statuses/update
- (void)postStatusUpdate:(NSString *)status
       inReplyToStatusID:(NSString *)optionalExistingStatusID
            successBlock:(void(^)(NSString *response))successBlock
              errorBlock:(void(^)(NSError *error))errorBlock;

// POST statuses/retweet/:id
- (void)postStatusRetweetWithID:(NSString *)statusID
                   successBlock:(void(^)(NSString *response))successBlock
                     errorBlock:(void(^)(NSError *error))errorBlock;


// POST statuses/update_with_media

// GET statuses/oembed

#pragma mark Search

// GET search/tweets

#pragma mark Streaming

// POST statuses/filter

// GET statuses/sample

// GET statuses/firehose

// GET user

// GET site

#pragma mark Direct Messages

// GET direct_messages

// GET direct_messages/sent

// GET direct_messages/show

// POST direct_messages/destroy

// POST direct_messages/new

#pragma mark Friends & Followers

// GET friends/ids

// GET followers/ids
- (void)getFollowersWithScreenName:(NSString *)screenName
                      successBlock:(void(^)(NSString *jsonString))successBlock
                        errorBlock:(void(^)(NSError *error))errorBlock;

// GET friendships/lookup

// GET friendships/incoming

// GET friendships/outgoing

// POST friendships/create

// POST friendships/destroy

// POST friendships/update

// GET friendships/show

#pragma mark Users

// GET account/settings

// GET account/verify_credentials

- (void)getAccountVerifyCredentialsSkipStatus:(BOOL)skipStatus
                                 successBlock:(void(^)(NSString *jsonString))successBlock
                                   errorBlock:(void(^)(NSError *error))errorBlock;

// POST account/settings

// POST account/update_delivery_device

// POST account/update_profile

// POST account/update_profile_background_image

// POST account/update_profile_colors

// POST account/update_profile_image

// GET blocks/list

// GET blocks/ids

// POST blocks/create

// POST blocks/destroy

// GET users/lookup

// GET users/show

// GET users/search

// GET users/contributees

// GET users/contributors

#pragma mark Suggested Users

// GET users/suggestions/:slug

// GET users/suggestions

// GET users/suggestions/:slug/members

#pragma mark Favorites

// GET favorites/list
- (void)getFavoritesListWithSuccessBlock:(void(^)(NSString *jsonString))successBlock
                              errorBlock:(void(^)(NSError *error))errorBlock;

// POST favorites/destroy
// POST favorites/create
- (void)postFavoriteState:(BOOL)favoriteState
              forStatusID:(NSString *)statusID
             successBlock:(void(^)(NSString *jsonString))successBlock
               errorBlock:(void(^)(NSError *error))errorBlock;

#pragma mark Lists

// GET lists/list

// GET lists/statuses

// POST lists/members/destroy

// GET lists/memberships

// GET lists/subscribers

// POST lists/subscribers/create

// GET lists/subscribers/show

// POST lists/subscribers/destroy

// POST lists/members/create_all

// GET lists/members/show

// GET lists/members

// POST lists/members/create

// POST lists/destroy

// POST lists/update

// POST lists/create

// GET lists/show

// GET lists/subscriptions

// POST lists/members/destroy_all

#pragma mark Saved Searches

#pragma mark Places & Geo

#pragma mark Trends

#pragma mark Spam Reporting

#pragma mark OAuth

#pragma mark Help

@end
