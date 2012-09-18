//
//  MGTwitterEngine+TH.m
//  TwitHunter
//
//  Created by Nicolas Seriot on 5/1/10.
//  Copyright 2010 seriot.ch. All rights reserved.
//

#import "THTwitterEngine.h"
#import <Social/Social.h>
#import <Accounts/Accounts.h>

@implementation THTwitterEngine

- (NSString *)username {
    ACAccountStore *accountStore = [[[ACAccountStore alloc] init] autorelease];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    NSArray *accounts = [accountStore accountsWithAccountType:accountType];
    NSAssert([accounts count] == 1, @"");
    ACAccount *twitterAccount = [accounts objectAtIndex:0];
    return twitterAccount.username;
}

- (void)requestAccessWithCompletionBlock:(void(^)(ACAccount *twitterAccount))completionBlock errorBlock:(void(^)(NSError *))errorBlock {
    
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if(granted) {
                
                NSArray *accounts = [accountStore accountsWithAccountType:accountType];
                
                NSAssert([accounts count] == 1, @"");
                
                ACAccount *twitterAccount = [accounts objectAtIndex:0];
                
                id cred = [twitterAccount credential];
                
                completionBlock(twitterAccount);
            } else {
                errorBlock(error);
            }
        }];
    }];
}

- (void)fetchFavoritesWithParameters:(NSDictionary *)params completionBlock:(STTE_completionBlock_t)completionBlock errorBlock:(STTE_errorBlock_t)errorBlock {
    
    [self fetchTwitterAPIResource:@"/statuses/favorites.json" parameters:params completionBlock:completionBlock errorBlock:errorBlock];
}

- (void)fetchAPIResource:(NSString *)resource httpMethod:(int)httpMethod parameters:(NSDictionary *)params completionBlock:(STTE_completionBlock_t)completionBlock errorBlock:(STTE_errorBlock_t)errorBlock {

    [self requestAccessWithCompletionBlock:^(ACAccount *twitterAccount) {
        NSString *urlString = [@"https://api.twitter.com/1.1" stringByAppendingString:resource];
        NSURL *url = [NSURL URLWithString:urlString];
        SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:httpMethod URL:url parameters:params];
        request.account = twitterAccount;
        
        [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
            NSString *output = [NSString stringWithFormat:@"HTTP response status: %ld", [urlResponse statusCode]];
            NSLog(@"%@", output);
            
            if(responseData == nil) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    errorBlock(nil);
                }];
                return;
            }
            
            NSError *jsonError = nil;
            NSJSONSerialization *json = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&jsonError];
            NSLog(@"-- json: %@", json);
            NSLog(@"-- error: %@", [jsonError localizedDescription]);
            
            /**/
            
            if([json isKindOfClass:[NSArray class]] == NO && [json valueForKey:@"error"]) {
                
                NSString *message = [json valueForKey:@"error"];
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
                NSError *jsonErrorFromResponse = [NSError errorWithDomain:NSStringFromClass([self class]) code:0 userInfo:userInfo];
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    errorBlock(jsonErrorFromResponse);
                }];
                
                return;
            }
            
            /**/
            
            NSArray *jsonErrors = [json valueForKey:@"errors"];
            
            if([jsonErrors count] > 0 && [[jsonErrors lastObject] isEqualTo:[NSNull null]] == NO) {
                
                NSDictionary *jsonErrorDictionary = [jsonErrors lastObject];
                NSString *message = jsonErrorDictionary[@"message"];
                NSInteger code = [jsonErrorDictionary[@"code"] intValue];
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
                NSError *jsonErrorFromResponse = [NSError errorWithDomain:NSStringFromClass([self class]) code:code userInfo:userInfo];
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    errorBlock(jsonErrorFromResponse);
                }];
                
                return;
            }
            
            /**/
            
            if(json) {
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    completionBlock((NSArray *)json);
                }];
                
            } else {
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    errorBlock(jsonError);
                }];
            }
        }];
        
    } errorBlock:^(NSError *error) {
        errorBlock(error);
    }];
}

- (void)getResource:(NSString *)resource parameters:(NSDictionary *)params completionBlock:(STTE_completionBlock_t)completionBlock errorBlock:(STTE_errorBlock_t)errorBlock {
    
    int HTTPMethod = SLRequestMethodGET;
    
    [self fetchAPIResource:resource httpMethod:HTTPMethod parameters:params completionBlock:completionBlock errorBlock:errorBlock];
}

- (void)postResource:(NSString *)resource parameters:(NSDictionary *)params completionBlock:(STTE_completionBlock_t)completionBlock errorBlock:(STTE_errorBlock_t)errorBlock {
    
    int HTTPMethod = SLRequestMethodPOST;
    
    [self fetchAPIResource:resource httpMethod:HTTPMethod parameters:params completionBlock:completionBlock errorBlock:errorBlock];
}

- (void)sendFavorite:(BOOL)favorite forStatus:(NSNumber *)statusUid completionBlock:(void(^)(BOOL favorite))completionBlock errorBlock:(void(^)(NSError *error))errorBlock {
    // https://api.twitter.com/1/favorites/create/132256714090229760.json
    // https://api.twitter.com/1/favorites/destroy/132256714090229760.json
    
    [self requestAccessWithCompletionBlock:^(ACAccount *twitterAccount) {
        
        NSString *createOrDestroy = favorite ? @"create" : @"destroy";
        
        NSString *urlString = [NSString stringWithFormat:@"https://api.twitter.com/1.1/favorites/%@/%@.json", createOrDestroy, statusUid];
        NSLog(@"-- %@", urlString);
        NSURL *url = [NSURL URLWithString:urlString];
        SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:url parameters:nil];
        [request addMultipartData:nil withName:@"foo" type:@"text/plain"]; // necessary
        request.account = twitterAccount;
                
        [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
            NSString *output = [NSString stringWithFormat:@"HTTP response status: %ld", [urlResponse statusCode]];
            NSLog(@"---------------> %@", output);
            
            if(responseData == nil) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    errorBlock(nil);
                }];
                return;
            }
            
            NSError *jsonError = nil;
            NSJSONSerialization *json = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&jsonError];
            NSLog(@"-- json: %@", json);
            NSLog(@"-- error: %@", [jsonError localizedDescription]);
            
            /**/
            
            if([json valueForKey:@"error"]) {
                
                NSString *message = [json valueForKey:@"error"];
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
                NSError *jsonErrorFromResponse = [NSError errorWithDomain:NSStringFromClass([self class]) code:0 userInfo:userInfo];
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    errorBlock(jsonErrorFromResponse);
                }];
                
                return;
            }
            
            /**/
            
            NSArray *jsonErrors = [json valueForKey:@"errors"];
            
            if([jsonErrors count] > 0 && [[jsonErrors lastObject] isEqualTo:[NSNull null]] == NO) {
                
                NSDictionary *jsonErrorDictionary = [jsonErrors lastObject];
                NSString *message = jsonErrorDictionary[@"message"];
                NSInteger code = [jsonErrorDictionary[@"code"] intValue];
                NSDictionary *userInfo = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
                NSError *jsonErrorFromResponse = [NSError errorWithDomain:NSStringFromClass([self class]) code:code userInfo:userInfo];
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    errorBlock(jsonErrorFromResponse);
                }];
                
                return;
            }
                        
            NSNumber *isFavoriteNumber = [json valueForKey:@"favorited"];
            BOOL isFavorite = ([isFavoriteNumber boolValue] == NO); // for some reason the result is inverted
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                completionBlock(isFavorite);
            }];
            
        }];
        
    } errorBlock:^(NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            errorBlock(error);
        }];
    }];
}

- (void)getHomeTimelineWithParameters:(NSDictionary *)params completionBlock:(STTE_completionBlock_t)completionBlock errorBlock:(STTE_errorBlock_t)errorBlock {

    [self getResource:@"/statuses/home_timeline.json" parameters:params completionBlock:completionBlock errorBlock:errorBlock];
}

- (void)getHomeTimelineSinceID:(unsigned long long)sinceID count:(NSUInteger)nbTweets completionBlock:(STTE_completionBlock_t)completionBlock errorBlock:(STTE_errorBlock_t)errorBlock {
        
    NSDictionary *params = @{@"include_entities":@"1", @"since_id":[@(sinceID) description]};
    
    [self getHomeTimelineWithParameters:params completionBlock:completionBlock errorBlock:errorBlock];
}

- (void)getHomeTimeline:(NSUInteger)nbTweets completionBlock:(STTE_completionBlock_t)completionBlock errorBlock:(STTE_errorBlock_t)errorBlock {
    
    NSDictionary *params = @{@"include_entities":@"0"};
    
    [self getHomeTimelineWithParameters:params completionBlock:completionBlock errorBlock:errorBlock];
}

- (void)fetchFavoriteUpdatesForUsername:(NSString *)aUsername completionBlock:(STTE_completionBlock_t)completionBlock errorBlock:(STTE_errorBlock_t)errorBlock {
    
    NSParameterAssert(aUsername);
    
    NSDictionary *params = @{@"screen_name":aUsername, @"count":@"200"};
    
    [self fetchFavoritesWithParameters:params completionBlock:completionBlock errorBlock:errorBlock];
}

//        NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1/statuses/update.json"];
//        NSDictionary *params = [NSDictionary dictionaryWithObject:@"test" forKey:@"status"];
//        SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:url parameters:params];
//        request.account = twitterAccount;
//
//        [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
//            NSString *output = [NSString stringWithFormat:@"HTTP response status: %ld", [urlResponse statusCode]];
//            NSLog(@"%@", output);
//        }];

@end
