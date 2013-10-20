//
//  STTwitterAppOnly.m
//  STTwitter
//
//  Created by Nicolas Seriot on 3/13/13.
//  Copyright (c) 2013 Nicolas Seriot. All rights reserved.
//

#import "STTwitterAppOnly.h"
#import "STHTTPRequest.h"
#import "NSString+STTwitter.h"
#import "STHTTPRequest+STTwitter.h"

@interface NSData (Base64)
- (NSString *)base64Encoding; // private API
@end

@implementation STTwitterAppOnly

- (id)init {
    self = [super init];
    
    // TODO: remove cookies from Twitter if needed
    
    return self;
}

+ (instancetype)twitterAppOnlyWithConsumerName:(NSString *)consumerName consumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret {
    STTwitterAppOnly *twitterAppOnly = [[[self class] alloc] init];
    twitterAppOnly.consumerName = consumerName;
    twitterAppOnly.consumerKey = consumerKey;
    twitterAppOnly.consumerSecret = consumerSecret;
    return twitterAppOnly;
}

#pragma mark STTwitterOAuthProtocol

- (BOOL)canVerifyCredentials {
    return YES;
}

- (NSString *)oauthAccessToken {
    return nil;
}

- (NSString *)oauthAccessTokenSecret {
    return nil;
}

- (void)invalidateBearerTokenWithSuccessBlock:(void(^)())successBlock
                                   errorBlock:(void(^)(NSError *error))errorBlock {
    
    if(_bearerToken == nil) {
        NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:0 userInfo:@{NSLocalizedDescriptionKey : @"Cannot invalidate missing bearer token"}];
        errorBlock(error);
        return;
    }
    
    [self postResource:@"oauth2/invalidate_token"
         baseURLString:@"https://api.twitter.com"
            parameters:@{ @"access_token" : _bearerToken }
          useBasicAuth:YES
         progressBlock:nil
          successBlock:^(NSString *requestID, NSDictionary *requestHeaders, NSDictionary *responseHeaders, id json) {
              
              if([json isKindOfClass:[NSDictionary class]] == NO) {
                  successBlock(json);
                  return;
              }
              
              self.bearerToken = [json valueForKey:@"access_token"];
              
              NSString *oldToken = self.bearerToken;
              
              self.bearerToken = nil;
              
              successBlock(oldToken);
              
          } errorBlock:^(NSString *requestID, NSDictionary *requestHeaders, NSDictionary *responseHeaders, NSError *error) {
              errorBlock(error);
          }];
    
    // POST /oauth2/invalidate_token HTTP/1.1
    // Authorization: Basic eHZ6MWV2RlM0d0VFUFRHRUZQSEJvZzpMOHFxOVBaeVJn
    // NmllS0dFS2hab2xHQzB2SldMdzhpRUo4OERSZHlPZw==
    // User-Agent: My Twitter App v1.0.23
    // Host: api.twitter.com
    // Accept: */*
    //
    // Content-Length: 119
    // Content-Type: application/x-www-form-urlencoded
    //
    // access_token=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA%2FAAAAAAAAAAAAAAAAAAAA%3DAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    
    // HTTP/1.1 200 OK
    // Content-Type: application/json; charset=utf-8
    // Content-Length: 127
    // ...
    //
    // {"access_token":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA%2FAAAAAAAAAAAAAAAAAAAA%3DAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"}
}

+ (NSString *)base64EncodedBearerTokenCredentialsWithConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret {
    NSString *encodedConsumerToken = [consumerKey st_stringByAddingRFC3986PercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *encodedConsumerSecret = [consumerSecret st_stringByAddingRFC3986PercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *bearerTokenCredentials = [NSString stringWithFormat:@"%@:%@", encodedConsumerToken, encodedConsumerSecret];
    NSData *data = [bearerTokenCredentials dataUsingEncoding:NSUTF8StringEncoding];
    return [data base64Encoding];
}

- (void)verifyCredentialsWithSuccessBlock:(void(^)(NSString *username))successBlock
                               errorBlock:(void(^)(NSError *error))errorBlock {
    
    [self postResource:@"oauth2/token"
         baseURLString:@"https://api.twitter.com"
            parameters:@{ @"grant_type" : @"client_credentials" }
          useBasicAuth:YES
         progressBlock:nil
          successBlock:^(NSString *requestID, NSDictionary *requestHeaders, NSDictionary *responseHeaders, id json) {
              
              NSString *tokenType = [json valueForKey:@"token_type"];
              if([tokenType isEqualToString:@"bearer"] == NO) {
                  NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:0 userInfo:@{NSLocalizedDescriptionKey : @"Cannot find bearer token in server response"}];
                  errorBlock(error);
                  return;
              }
              
              self.bearerToken = [json valueForKey:@"access_token"];
              
              successBlock(_bearerToken);
              
          } errorBlock:^(NSString *requestID, NSDictionary *requestHeaders, NSDictionary *responseHeaders, NSError *error) {
              errorBlock(error);
          }];
}

- (NSString *)getResource:(NSString *)resource
            baseURLString:(NSString *)baseURLString // no trailing slash
               parameters:(NSDictionary *)params
            progressBlock:(void(^)(NSString *requestID, id json))progressBlock
             successBlock:(void (^)(NSString *requestID, NSDictionary *requestHeaders, NSDictionary *responseHeaders, id json))successBlock
               errorBlock:(void (^)(NSString *requestID, NSDictionary *requestHeaders, NSDictionary *responseHeaders, NSError *error))errorBlock {
    
    /*
     GET /1.1/statuses/user_timeline.json?count=100&screen_name=twitterapi HTTP/1.1
     Host: api.twitter.com
     User-Agent: My Twitter App v1.0.23
     Authorization: Bearer AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA%2FAAAAAAAAAAAA
     AAAAAAAA%3DAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
     Accept-Encoding: gzip
     */
    
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@/%@", baseURLString, resource];
    
    NSMutableArray *parameters = [NSMutableArray array];
    
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *s = [NSString stringWithFormat:@"%@=%@", key, obj];
        [parameters addObject:s];
    }];
    
    if([parameters count]) {
        NSString *parameterString = [parameters componentsJoinedByString:@"&"];
        
        [urlString appendFormat:@"?%@", parameterString];
    }
    
    NSString *requestID = [[NSUUID UUID] UUIDString];
    
    __block STHTTPRequest *r = [STHTTPRequest twitterRequestWithURLString:urlString
                                                   stTwitterProgressBlock:^(id json) {
                                                       if(progressBlock) progressBlock(requestID, json);
                                                   } stTwitterSuccessBlock:^(NSDictionary *requestHeaders, NSDictionary *responseHeaders, id json) {
                                                       successBlock(requestID, requestHeaders, responseHeaders, json);
                                                   } stTwitterErrorBlock:^(NSDictionary *requestHeaders, NSDictionary *responseHeaders, NSError *error) {
                                                       errorBlock(requestID, requestHeaders, responseHeaders, error);
                                                   }];
    if(_bearerToken) {
        [r setHeaderWithName:@"Authorization" value:[NSString stringWithFormat:@"Bearer %@", _bearerToken]];
    }
    
    [r startAsynchronous];
    
    return requestID;
}

- (NSString *)fetchResource:(NSString *)resource
                 HTTPMethod:(NSString *)HTTPMethod
              baseURLString:(NSString *)baseURLString
                 parameters:(NSDictionary *)params
              progressBlock:(void(^)(NSString *requestID, id json))progressBlock
               successBlock:(void(^)(NSString *requestID, NSDictionary *requestHeaders, NSDictionary *responseHeaders, id json))successBlock
                 errorBlock:(void(^)(NSString *requestID, NSDictionary *requestHeaders, NSDictionary *responseHeaders, NSError *error))errorBlock {
    
    if([baseURLString hasSuffix:@"/"]) {
        baseURLString = [baseURLString substringToIndex:[baseURLString length]-1];
    }
    
    if([HTTPMethod isEqualToString:@"GET"]) {
        
        return [self getResource:resource
                   baseURLString:baseURLString
                      parameters:params
                   progressBlock:progressBlock
                    successBlock:successBlock
                      errorBlock:errorBlock];
        
    } else if ([HTTPMethod isEqualToString:@"POST"]) {
        
        return [self postResource:resource
                    baseURLString:baseURLString
                       parameters:params
                    progressBlock:progressBlock
                     successBlock:successBlock
                       errorBlock:errorBlock];
        
    } else {
        NSAssert(NO, @"unsupported HTTP method");
        return nil;
    }
}

- (NSString *)postResource:(NSString *)resource
             baseURLString:(NSString *)baseURLString // no trailing slash
                parameters:(NSDictionary *)params
              useBasicAuth:(BOOL)useBasicAuth
             progressBlock:(void(^)(NSString *requestID, id json))progressBlock
              successBlock:(void(^)(NSString *requestID, NSDictionary *requestHeaders, NSDictionary *responseHeaders, id json))successBlock
                errorBlock:(void(^)(NSString *requestID, NSDictionary *requestHeaders, NSDictionary *responseHeaders, NSError *error))errorBlock {
    
    NSString *urlString = [NSString stringWithFormat:@"%@/%@", baseURLString, resource];
    
    NSString *requestID = [[NSUUID UUID] UUIDString];
    
    __block STHTTPRequest *r = [STHTTPRequest twitterRequestWithURLString:urlString
                                                   stTwitterProgressBlock:^(id json) {
                                                       if(progressBlock) progressBlock(requestID, json);
                                                   } stTwitterSuccessBlock:^(NSDictionary *requestHeaders, NSDictionary *responseHeaders, id json) {
                                                       successBlock(requestID, requestHeaders, responseHeaders, json);
                                                   } stTwitterErrorBlock:^(NSDictionary *requestHeaders, NSDictionary *responseHeaders, NSError *error) {
                                                       errorBlock(requestID, requestHeaders, responseHeaders, error);
                                                   }];
    
    r.POSTDictionary = params;
    
    NSMutableDictionary *mutableParams = [params mutableCopy];
    
    r.encodePOSTDictionary = NO;
    
    r.POSTDictionary = mutableParams ? mutableParams : @{};
    
    if(useBasicAuth) {
        NSString *base64EncodedTokens = [[self class] base64EncodedBearerTokenCredentialsWithConsumerKey:_consumerKey consumerSecret:_consumerSecret];
        
        [r setHeaderWithName:@"Authorization" value:[NSString stringWithFormat:@"Basic %@", base64EncodedTokens]];
    } else if(_bearerToken) {
        [r setHeaderWithName:@"Authorization" value:[NSString stringWithFormat:@"Bearer %@", _bearerToken]];
        r.encodePOSTDictionary = YES;
    }
    
    [r startAsynchronous];
    
    return requestID;
}

- (NSString *)postResource:(NSString *)resource
             baseURLString:(NSString *)baseURLString
                parameters:(NSDictionary *)params
             progressBlock:(void(^)(NSString *requestID, id json))progressBlock
              successBlock:(void(^)(NSString *requestID, NSDictionary *requestHeaders, NSDictionary *responseHeaders, id json))successBlock
                errorBlock:(void(^)(NSString *requestID, NSDictionary *requestHeaders, NSDictionary *responseHeaders, NSError *error))errorBlock {
    
    return [self postResource:resource
                baseURLString:baseURLString
                   parameters:params
                 useBasicAuth:NO
                progressBlock:progressBlock
                 successBlock:successBlock
                   errorBlock:errorBlock];
}

- (NSString *)loginTypeDescription {
    return @"App Only";
}

@end
