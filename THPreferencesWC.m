//
//  THPreferencesWC.m
//  TwitHunter
//
//  Created by Nicolas Seriot on 10/28/12.
//  Copyright (c) 2012 seriot.ch. All rights reserved.
//

#import "THPreferencesWC.h"

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
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)dealloc {
    [_twitterClients release];
    [_twitterClientsController release];
    
    [super dealloc];
}

@end
