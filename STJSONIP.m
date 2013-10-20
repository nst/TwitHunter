//
//  STIPAddress.m
//  TwitHunter
//
//  Created by Nicolas Seriot on 10/10/12.
//  Copyright (c) 2012 seriot.ch. All rights reserved.
//

#import "STJSONIP.h"
#import "STHTTPRequest.h"

@implementation STJSONIP

+ (void)getExternalIPAddressWithSuccessBlock:(void(^)(NSString *ipAddress))successBlock
                                  errorBlock:(void(^)(NSError *error))errorBlock {
    
    __block STHTTPRequest *r = [STHTTPRequest requestWithURLString:@"http://jsonip.com/"];
    __weak STHTTPRequest *wr = r;
    
    r.completionBlock = ^(NSDictionary *headers, NSString *body) {

        NSError *jsonError = nil;
        id json = [NSJSONSerialization JSONObjectWithData:wr.responseData options:NSJSONReadingMutableLeaves error:&jsonError];
        
        if(json == nil) {
            errorBlock(jsonError);
            return;
        }
        
        NSString *ip = [json valueForKey:@"ip"];
        
        if(ip) {
            successBlock(ip);
        } else {
            errorBlock(nil);
        }        
    };
    
    r.errorBlock = ^(NSError *error) {
        errorBlock(error);
    };
    
    [r startAsynchronous];    
}

@end
