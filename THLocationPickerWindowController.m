//
//  LocationPickerWindowController.m
//  TwitHunter
//
//  Created by Nicolas Seriot on 10/4/12.
//  Copyright (c) 2012 seriot.ch. All rights reserved.
//

#import "THLocationPickerWindowController.h"
#import "STTwitterAPIWrapper.h"
#import "THTweetLocation.h"

@interface THLocationPickerWindowController ()

@end

@implementation THLocationPickerWindowController

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
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    
    NSAssert(_delegate, @"THLocationPickerWindowController delegate is missing");
}

- (void)dealloc {
    [_twitter release];
    [_tweetLocation release];
    [super dealloc];
}

- (IBAction)ok:(id)sender {
    [_delegate locationPicker:self didChooseLocation:_tweetLocation];
}

- (IBAction)cancel:(id)sender {
    [_delegate locationPickerDidCancel:self];
}

@end
