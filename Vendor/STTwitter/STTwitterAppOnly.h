//
//  STTwitterAppOnly.h
//  STTwitter
//
//  Created by Nicolas Seriot on 3/13/13.
//  Copyright (c) 2013 Nicolas Seriot. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STTwitterProtocol.h"

#if DEBUG
#   define STLog(...) NSLog(__VA_ARGS__)
#else
#   define STLog(...)
#endif

@interface STTwitterAppOnly : NSObject <STTwitterProtocol> {
    
}

@property (nonatomic, strong) NSString *consumerName;
@property (nonatomic, strong) NSString *consumerKey;
@property (nonatomic, strong) NSString *consumerSecret;
@property (nonatomic, strong) NSString *bearerToken;

+ (instancetype)twitterAppOnlyWithConsumerName:(NSString *)conumerName consumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret;

+ (NSString *)base64EncodedBearerTokenCredentialsWithConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret;

- (void)invalidateBearerTokenWithSuccessBlock:(void(^)())successBlock
                                   errorBlock:(void(^)(NSError *error))errorBlock;

@end
