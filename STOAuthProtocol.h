//
//  STOAuthProtocol.h
//  STTwitterRequests
//
//  Created by Nicolas Seriot on 9/18/12.
//  Copyright (c) 2012 Nicolas Seriot. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol STOAuthProtocol <NSObject>

- (void)getResource:(NSString *)resource
         parameters:(NSDictionary *)params
       successBlock:(void(^)(NSString *response))successBlock
         errorBlock:(void(^)(NSError *error))errorBlock;

- (void)postResource:(NSString *)resource
          parameters:(NSDictionary *)params
        successBlock:(void(^)(NSString *response))successBlock
          errorBlock:(void(^)(NSError *error))errorBlock;

@end
