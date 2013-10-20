//
//  THPreferencesWC.h
//  TwitHunter
//
//  Created by Nicolas Seriot on 10/28/12.
//  Copyright (c) 2012 seriot.ch. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef void (^UsernamePasswordBlock_t)(NSString *username, NSString *password);

@class STTwitterAPI;
@class THPreferencesWC;

@protocol THPreferencesWCDelegate
- (void)preferences:(THPreferencesWC *)preferences didChooseTwitter:(STTwitterAPI *)twitter;
@end

@interface THPreferencesWC : NSWindowController

+ (THPreferencesWC *)sharedPreferencesWC;

@property (nonatomic, unsafe_unretained) id <THPreferencesWCDelegate> preferencesDelegate;

@property (nonatomic, copy) UsernamePasswordBlock_t usernamePasswordBlock;

@property (nonatomic, strong) NSString *connectionStatus;

@property (nonatomic, strong) STTwitterAPI *twitter;

@property (nonatomic, strong) NSArray *twitterClients;

@property (nonatomic, strong) IBOutlet NSArrayController *twitterClientsController;
@property (nonatomic, strong) IBOutlet NSPanel *usernameAndPasswordPanel;

@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;

- (IBAction)usernamePasswordCancel:(id)sender;
- (IBAction)usernamePasswordOK:(id)sender;

- (IBAction)loginAction:(id)sender;

- (STTwitterAPI *)twitterWrapper;

@end
