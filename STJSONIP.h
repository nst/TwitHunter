//
//  STIPAddress.h
//  TwitHunter
//
//  Created by Nicolas Seriot on 10/10/12.
//  Copyright (c) 2012 seriot.ch. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STJSONIP : NSObject

+ (void)getExternalIPAddressWithSuccessBlock:(void(^)(NSString *ipAddress))successBlock
                                  errorBlock:(void(^)(NSError *error))errorBlock;

@end
