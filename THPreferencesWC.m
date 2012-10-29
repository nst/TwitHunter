//
//  THPreferencesWC.m
//  TwitHunter
//
//  Created by Nicolas Seriot on 10/28/12.
//  Copyright (c) 2012 seriot.ch. All rights reserved.
//

#import "THPreferencesWC.h"
#import "STTwitterAPIWrapper.h"

@interface THPreferencesWC ()

@end

static THPreferencesWC *sharedPreferencesWC = nil;

typedef enum {
    OSX = 0,
    Known = 1,
    Custom = 2
} THPreferencesConnectionIdentityIndex;

@implementation THPreferencesWC

+ (THPreferencesWC *)sharedPreferencesWC {
	if (!sharedPreferencesWC) {
		sharedPreferencesWC = [[THPreferencesWC alloc] initWithWindowNibName:@"THPreferencesWC"];
	}
	return sharedPreferencesWC;
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"TwitterClients" ofType:@"plist"];
    self.twitterClients = [NSArray arrayWithContentsOfFile:path];

    /**/
    
    NSUInteger i = [self indexOfUsedKnownClientIdentity];
    
    if(i == NSNotFound) i = 0;
    
    [[NSUserDefaults standardUserDefaults] setInteger:i forKey:@"PreferencesKnownClientIdentityIndex"];

    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)askForUsernameAndPasswordWithCompletionBlock:(UsernamePasswordBlock_t)completionBlock {
    self.usernamePasswordBlock = completionBlock;
    
    [NSApp beginSheet:_usernameAndPasswordPanel
       modalForWindow:self.window
        modalDelegate:self
       didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
          contextInfo:nil];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(NSDictionary *)contextInfo {
    
    NSLog(@"-- %lu", returnCode);
    
    if(returnCode != 1) {
        self.username = nil;
        self.password = nil;
    }
    
    _usernamePasswordBlock(_username, _password);

    self.username = nil;
    self.password = nil;
}

- (IBAction)usernamePasswordCancel:(id)sender {
    [NSApp endSheet:_usernameAndPasswordPanel returnCode:0];
    [_usernameAndPasswordPanel orderOut:self];
}

- (IBAction)usernamePasswordOK:(id)sender {
    [NSApp endSheet:_usernameAndPasswordPanel returnCode:1];
    [_usernameAndPasswordPanel orderOut:self];
}

- (NSUInteger)indexOfUsedKnownClientIdentity {
    
    NSString *name = [[NSUserDefaults standardUserDefaults] valueForKeyPath:@"clientName"];
    
    if(name == nil) return NSNotFound;
    
    __block NSUInteger index = NSNotFound;
    
    NSArray *twitterClients = [_twitterClientsController arrangedObjects];
    
    [twitterClients enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *d = (NSDictionary *)obj;
        
        if([d[@"name"] isEqualToString:name]) {
            *stop = YES;
            index = idx;
        }
    }];

    return index;
}

- (NSDictionary *)preferedClientIdentityDictionary {
    
    NSString *ak = [[NSUserDefaults standardUserDefaults] valueForKeyPath:@"tokensAK"];
    NSString *as = [[NSUserDefaults standardUserDefaults] valueForKeyPath:@"tokensAS"];
    NSString *name = [[NSUserDefaults standardUserDefaults] valueForKeyPath:@"clientName"];
    
    __block NSDictionary *d = nil;
    
    [_twitterClients enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        d = (NSDictionary *)obj;
        
        if([d[@"name"] isEqualToString:name]) {
            *stop = YES;
        }
    }];
    
    NSString *ck = d[@"ck"];
    NSString *cs = d[@"cs"];
    
    if(ck && cs && ak && as && name) {
        return @{@"ck":ck, @"cs":cs, @"ak":ak, @"as":as, @"name":name};
    }
    
    return nil;
}

- (STTwitterAPIWrapper *)twitterWrapperAsPrefered {

    NSDictionary *d = [self preferedClientIdentityDictionary];
    
#warning TODO: add -[STTwitterAPIWrapper name]
    
    if (d == nil) {
        NSLog(@"-- USING OSX");
        return [STTwitterAPIWrapper twitterAPIWithOAuthOSX];
    }
    
    NSLog(@"-- USING %@", d[@"name"]);
    return [STTwitterAPIWrapper twitterAPIWithOAuthConsumerKey:d[@"ck"]
                                                consumerSecret:d[@"cs"]
                                                    oauthToken:d[@"ak"]
                                              oauthTokenSecret:d[@"as"]];
    
//    NSUInteger i = [[NSUserDefaults standardUserDefaults] integerForKey:@"TwitterConnectionIdentityIndex"];
//    
//    if (i == OSX) {
//        
//        return [STTwitterAPIWrapper twitterAPIWithOAuthOSX];
//    
//    } else  if (i == Known) {
//    
//        NSUInteger i = [self indexOfUsedKnownClientIdentity];
//        
//        NSArray *twitterClients = [_twitterClientsController arrangedObjects];
//
//
//
//    } else if (i == Custom) {
//        return 
//    }
    
}

- (IBAction)testConnection:(id)sender {
    
    self.connectionStatus = @"Testing connection...";
    
    NSUInteger i = [[NSUserDefaults standardUserDefaults] integerForKey:@"TwitterConnectionIdentityIndex"];
    
    if(i == OSX) {
        
        self.twitter = [STTwitterAPIWrapper twitterAPIWithOAuthOSX];
        
        [_twitter verifyCredentialsWithSuccessBlock:^(NSString *username) {
            
            self.connectionStatus = [NSString stringWithFormat:@"Access granted for %@", username];
            
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"tokensAK"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"tokensAS"];

            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"clientName"];
            
            [_preferencesDelegate preferences:self didChooseTwitter:_twitter];

        } errorBlock:^(NSError *error) {
            
            self.connectionStatus = [error localizedDescription];
        }];

    } else if (i == Known) {
        
        NSUInteger i = [self indexOfUsedKnownClientIdentity];
        
        NSArray *twitterClients = [_twitterClientsController arrangedObjects];
        
        if([twitterClients count] == 0) {
            NSLog(@"-- error: no twitter clients");
            return;
        }
        
        if(i >= [twitterClients count]) i = 0;
        
        NSDictionary *twitterClient = [twitterClients objectAtIndex:i];
        
        NSString *consumerKey = twitterClient[@"ck"];
        NSString *consumerSecret = twitterClient[@"cs"];
        
        NSLog(@"-- %@", consumerKey);
        NSLog(@"-- %@", consumerSecret);
        
        if(consumerKey == nil || consumerSecret == nil) {
            self.connectionStatus = [NSString stringWithFormat:@"error: no consumer key or secret in %@", twitterClient];
            return;
        }
        
        [self askForUsernameAndPasswordWithCompletionBlock:^(NSString *username, NSString *password) {
            
            if(username == nil || password == nil) {
                self.connectionStatus = @"no username or password";
                return;
            };
            
            self.twitter = [STTwitterAPIWrapper twitterAPIWithOAuthConsumerKey:consumerKey consumerSecret:consumerSecret username:username password:password];
            
            [_twitter verifyCredentialsWithSuccessBlock:^(NSString *username) {
                
                self.connectionStatus = [NSString stringWithFormat:@"Access granted for %@ on %@", username, twitterClient[@"name"]];
                
                [[NSUserDefaults standardUserDefaults] setValue:_twitter.oauthAccessToken forKey:@"tokensAK"];
                [[NSUserDefaults standardUserDefaults] setValue:_twitter.oauthAccessTokenSecret forKey:@"tokensAS"];
                
                [[NSUserDefaults standardUserDefaults] setValue:twitterClient[@"name"] forKey:@"clientName"];
                
                [_preferencesDelegate preferences:self didChooseTwitter:_twitter];

            } errorBlock:^(NSError *error) {
                
                self.connectionStatus = [error localizedDescription];
            }];
            
        }];

    } else if (i == Custom) {
        
    }

}

- (void)dealloc {
    if (_usernamePasswordBlock) [_usernamePasswordBlock release];

    [_usernameAndPasswordPanel release];
    [_twitterClients release];
    [_twitterClientsController release];
    [_username release];
    [_password release];
    [_twitter release];
    [_connectionStatus release];
    
    [super dealloc];
}

@end
