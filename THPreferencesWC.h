//
//  THPreferencesWC.h
//  TwitHunter
//
//  Created by Nicolas Seriot on 10/28/12.
//  Copyright (c) 2012 seriot.ch. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface THPreferencesWC : NSWindowController

+ (THPreferencesWC *)sharedPreferencesWC;

@property (nonatomic, retain) NSArray *twitterClients;
@property (nonatomic, retain) IBOutlet NSArrayController *twitterClientsController;
@property (nonatomic, retain) IBOutlet NSTextField *textField;

@end
