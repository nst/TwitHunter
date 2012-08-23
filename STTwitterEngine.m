//
//  MGTwitterEngine+TH.m
//  TwitHunter
//
//  Created by Nicolas Seriot on 5/1/10.
//  Copyright 2010 seriot.ch. All rights reserved.
//

#import "STTwitterEngine.h"
#import <Social/Social.h>
#import <Accounts/Accounts.h>

@implementation STTwitterEngine

- (NSString *)username {
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    NSArray *accounts = [accountStore accountsWithAccountType:accountType];
    ACAccount *twitterAccount = [accounts objectAtIndex:0];
    return twitterAccount.username;
}

- (void)getFavoriteUpdatesForUsername:(NSString *)aUsername completionBlock:(STTE_completionBlock_t)completionBlock errorBlock:(STTE_errorBlock_t)errorBlock {

    NSAssert(aUsername != nil, @"no username");
    
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
        NSLog(@"-- granted: %d, error %@", granted, [error localizedDescription]);
        
        if(granted == NO) return;
        
        NSArray *accounts = [accountStore accountsWithAccountType:accountType];
        
        if ([accounts count] != 1) return;
        
        ACAccount *twitterAccount = [accounts objectAtIndex:0];
        
        //        NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1/statuses/update.json"];
        //        NSDictionary *params = [NSDictionary dictionaryWithObject:@"test" forKey:@"status"];
        //        SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:url parameters:params];
        //        request.account = twitterAccount;
        //
        //        [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        //            NSString *output = [NSString stringWithFormat:@"HTTP response status: %ld", [urlResponse statusCode]];
        //            NSLog(@"%@", output);
        //        }];
        
        NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1/statuses/favorites.json"];
        NSDictionary *params = @{@"screen_name":aUsername, @"count":@"200"};
        SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:url parameters:params];
        request.account = twitterAccount;
        
        [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
            NSString *output = [NSString stringWithFormat:@"HTTP response status: %ld", [urlResponse statusCode]];
            NSLog(@"%@", output);
                        
            NSError *jsonError = nil;
            NSJSONSerialization *json = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&jsonError];
            NSLog(@"-- json: %@", json);
            NSLog(@"-- error: %@", [jsonError localizedDescription]);
            
            if(json) {
                completionBlock(json);
            } else {
                errorBlock(jsonError);
            }
        }];
        
        
    }];

}

- (void)getHomeTimeline:(NSUInteger)nbTweets completionBlock:(STTE_completionBlock_t)completionBlock errorBlock:(STTE_errorBlock_t)errorBlock {
//	NSUInteger count = 20;
//	
//	NSUInteger pages = (nbTweets % count) ? (nbTweets / count) : (nbTweets / count) + 1;
//	
//	NSMutableArray *a = [NSMutableArray array];
//	for(NSUInteger i = 0; i <= pages; i++) {
//		NSString *requestID = [self getHomeTimelineSinceID:0 startingAtPage:i count:count];
//		[a addObject:requestID];
//	}
//	return a;

    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
        NSLog(@"-- granted: %d, error %@", granted, [error localizedDescription]);
        
        if(granted == NO) return;
        
        NSArray *accounts = [accountStore accountsWithAccountType:accountType];
        
        if ([accounts count] != 1) return;
        
        ACAccount *twitterAccount = [accounts objectAtIndex:0];
        
        //        NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1/statuses/update.json"];
        //        NSDictionary *params = [NSDictionary dictionaryWithObject:@"test" forKey:@"status"];
        //        SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:url parameters:params];
        //        request.account = twitterAccount;
        //
        //        [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        //            NSString *output = [NSString stringWithFormat:@"HTTP response status: %ld", [urlResponse statusCode]];
        //            NSLog(@"%@", output);
        //        }];
        
        NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1/statuses/home_timeline.json"];
        NSDictionary *params = @{@"include_entities":@"1"};
        SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:url parameters:params];
        request.account = twitterAccount;
        
        [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
            NSString *output = [NSString stringWithFormat:@"HTTP response status: %ld", [urlResponse statusCode]];
            NSLog(@"%@", output);
            
            if(responseData == nil) return;
            
            NSError *jsonError = nil;
            NSJSONSerialization *json = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&jsonError];
            NSLog(@"-- json: %@", json);
            NSLog(@"-- error: %@", [jsonError localizedDescription]);
            
            if(json) {
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    completionBlock(json);
                }];
                
            } else {

                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    errorBlock(jsonError);
                }];
            }
        }];
        
        
    }];

}

@end
