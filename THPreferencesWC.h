//
//  THPreferencesWC.h
//  TwitHunter
//
//  Created by Nicolas Seriot on 10/28/12.
//  Copyright (c) 2012 seriot.ch. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef void (^UsernamePasswordBlock_t)(NSString *username, NSString *password);

@class STTwitterAPIWrapper;
@class THPreferencesWC;

@protocol THPreferencesWCDelegate
- (void)preferences:(THPreferencesWC *)preferences didChooseTwitter:(STTwitterAPIWrapper *)twitter;
@end

@interface THPreferencesWC : NSWindowController

+ (THPreferencesWC *)sharedPreferencesWC;

@property (nonatomic, assign) id <THPreferencesWCDelegate> preferencesDelegate;

@property (nonatomic, copy) UsernamePasswordBlock_t usernamePasswordBlock;

@property (nonatomic, retain) NSString *connectionStatus;

@property (nonatomic, retain) STTwitterAPIWrapper *twitter;

@property (nonatomic, retain) NSArray *twitterClients;

@property (nonatomic, retain) IBOutlet NSArrayController *twitterClientsController;
@property (nonatomic, retain) IBOutlet NSPanel *usernameAndPasswordPanel;

@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *password;

- (IBAction)usernamePasswordCancel:(id)sender;
- (IBAction)usernamePasswordOK:(id)sender;

@end
