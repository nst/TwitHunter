//
//  STTwitterRequest.h
//  STTwitterRequests
//
//  Created by Nicolas Seriot on 9/5/12.
//  Copyright (c) 2012 Nicolas Seriot. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STHTTPRequest.h"
#import "STOAuthProtocol.h"

@interface STOAuth : NSObject <STOAuthProtocol>

+ (STOAuth *)twitterServiceWithConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret username:(NSString *)username password:(NSString *)password;
+ (STOAuth *)twitterServiceWithConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret oauthToken:(NSString *)oauthToken oauthTokenSecret:(NSString *)oauthTokenSecret;

// TODO: move the OAuth requests to STTwitterAPIWrapper?

- (void)postTokenRequest:(void(^)(NSURL *url, NSString *oauthToken))successBlock errorBlock:(void(^)(NSError *error))errorBlock;

- (void)postAccessTokenRequestWithPIN:(NSString *)pin
                           oauthToken:(NSString *)oauthToken
                         successBlock:(void(^)(NSString *oauthToken, NSString *oauthTokenSecret, NSString *userID, NSString *screenName))successBlock
                           errorBlock:(void(^)(NSError *error))errorBlock;

- (void)postXAuthAccessTokenRequestWithUsername:(NSString *)username
                                       password:(NSString *)password
                                   successBlock:(void(^)(NSString *oauthToken, NSString *oauthTokenSecret, NSString *userID, NSString *screenName))successBlock
                                     errorBlock:(void(^)(NSError *error))errorBlock;

- (void)verifyCredentialsWithSuccessBlock:(void(^)(NSString *username))successBlock errorBlock:(void(^)(NSError *error))errorBlock;

@property (nonatomic, retain) NSString *testOauthNonce;
@property (nonatomic, retain) NSString *testOauthTimestamp;

@end

@interface NSString (STTwitterOAuth)
+ (NSString *)random32Characters;
- (NSString *)signHmacSHA1WithKey:(NSString *)key;
- (NSDictionary *)parametersDictionary;
- (NSString *)urlEncodedString;
@end

@interface NSURL (STTwitterOAuth)
- (NSString *)normalizedForOauthSignatureString;
- (NSArray *)getParametersDictionaries;
@end

@interface NSData (STTwitterOAuth)
- (NSString *)base64EncodedString;
@end
