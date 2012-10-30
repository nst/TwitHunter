//
//  THPreferencesWC.m
//  TwitHunter
//
//  Created by Nicolas Seriot on 10/28/12.
//  Copyright (c) 2012 seriot.ch. All rights reserved.
//

#import "THPreferencesWC.h"
#import "STTwitterAPIWrapper.h"

static NSString *kTHOSXTwitterIntegrationName = @"OSX Twitter Integration";

@interface THPreferencesWC ()

@end

static THPreferencesWC *sharedPreferencesWC = nil;

@implementation THPreferencesWC

+ (THPreferencesWC *)sharedPreferencesWC {
	if (!sharedPreferencesWC) {
		sharedPreferencesWC = [[THPreferencesWC alloc] initWithWindowNibName:@"THPreferencesWC"];
	}
	return sharedPreferencesWC;
}

- (id)initWithWindow:(NSWindow *)window {
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"TwitterXAuthClients" ofType:@"plist"];
    NSArray *xAuthClients = [NSArray arrayWithContentsOfFile:path];
    
    NSDictionary *defaultClient = @{@"name" : kTHOSXTwitterIntegrationName};
    
    self.twitterClients = [@[defaultClient] arrayByAddingObjectsFromArray:xAuthClients];
    
    /**/
    
    NSString *clientName = [[NSUserDefaults standardUserDefaults] valueForKey:@"clientName"];

    __block NSUInteger selectionIndex = 0;
    
    [_twitterClients enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *d = (NSDictionary *)obj;
        
        if([[d valueForKey:@"name"] isEqualToString:clientName]) {
            *stop = YES;
            selectionIndex = idx;
            
//            NSLog(@"---------- %d %@", selectionIndex, d);
        }
    }];

    [_twitterClientsController setSelectionIndex:selectionIndex];
    
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
    
    NSString *name = [[NSUserDefaults standardUserDefaults] valueForKey:@"clientName"];
    
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
    
    NSString *ak = [[NSUserDefaults standardUserDefaults] valueForKey:@"tokensAK"];
    NSString *as = [[NSUserDefaults standardUserDefaults] valueForKey:@"tokensAS"];
    NSString *name = [[NSUserDefaults standardUserDefaults] valueForKey:@"clientName"];
    
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

- (STTwitterAPIWrapper *)twitterWrapper {
    
    NSDictionary *d = [self preferedClientIdentityDictionary];
    
    if (d == nil) {
        NSLog(@"-- USING OSX");
        return [STTwitterAPIWrapper twitterAPIWithOAuthOSX];
    }
    
    NSLog(@"-- USING %@", d[@"name"]);
    return [STTwitterAPIWrapper twitterAPIWithOAuthConsumerName:d[@"name"]
                                                    consumerKey:d[@"ck"]
                                                 consumerSecret:d[@"cs"]
                                                     oauthToken:d[@"ak"]
                                               oauthTokenSecret:d[@"as"]];
}

- (IBAction)loginAction:(id)sender {
    
    self.connectionStatus = @"Trying to login...";

    NSDictionary *selectedClient = [[_twitterClientsController selectedObjects] lastObject];
    
    NSLog(@"-- %@", _twitterClientsController);
    NSLog(@"-- %@", [_twitterClientsController selectedObjects]);
    NSLog(@"-- %@", [[_twitterClientsController selectedObjects] lastObject]);
    
    if(selectedClient == nil || [[selectedClient valueForKey:@"name"] isEqualToString:kTHOSXTwitterIntegrationName]) {
        
        self.twitter = [STTwitterAPIWrapper twitterAPIWithOAuthOSX];
        
        [_twitter verifyCredentialsWithSuccessBlock:^(NSString *username) {
            
            self.connectionStatus = [NSString stringWithFormat:@"Access granted for %@", username];
            
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"tokensAK"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"tokensAS"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"clientName"];
            
            [[NSUserDefaults standardUserDefaults] setValue:username forKey:@"userName"];
            
            [_preferencesDelegate preferences:self didChooseTwitter:_twitter];
            
        } errorBlock:^(NSError *error) {
            
            self.connectionStatus = [error localizedDescription];
        }];
        
    } else {
                
        NSString *consumerName = selectedClient[@"name"];
        NSString *consumerKey = selectedClient[@"ck"];
        NSString *consumerSecret = selectedClient[@"cs"];
        
        NSLog(@"-- %@", consumerName);
        NSLog(@"-- %@", consumerKey);
        NSLog(@"-- %@", consumerSecret);
        
        if(consumerName == nil || consumerKey == nil || consumerSecret == nil) {
            self.connectionStatus = [NSString stringWithFormat:@"error: no name, consumer key or secret in %@", selectedClient];
            return;
        }
        
        [self askForUsernameAndPasswordWithCompletionBlock:^(NSString *username, NSString *password) {
            
            if(username == nil || password == nil) {
                self.connectionStatus = @"no username or password";
                return;
            };
            
            self.twitter = [STTwitterAPIWrapper twitterAPIWithOAuthConsumerName:consumerName
                                                                    consumerKey:consumerKey
                                                                 consumerSecret:consumerSecret
                                                                       username:username
                                                                       password:password];
            
            [_twitter verifyCredentialsWithSuccessBlock:^(NSString *username) {
                
                self.connectionStatus = [NSString stringWithFormat:@"Access granted for %@ on %@", username, selectedClient[@"name"]];
                
                [[NSUserDefaults standardUserDefaults] setValue:_twitter.oauthAccessToken forKey:@"tokensAK"];
                [[NSUserDefaults standardUserDefaults] setValue:_twitter.oauthAccessTokenSecret forKey:@"tokensAS"];

                [[NSUserDefaults standardUserDefaults] setValue:username forKey:@"userName"];
                [[NSUserDefaults standardUserDefaults] setValue:selectedClient[@"name"] forKey:@"clientName"];
                
                [_preferencesDelegate preferences:self didChooseTwitter:_twitter];
                
            } errorBlock:^(NSError *error) {
                
                self.connectionStatus = [error localizedDescription];
            }];
            
        }];
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
