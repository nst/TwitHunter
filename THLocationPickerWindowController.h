//
//  LocationPickerWindowController.h
//  TwitHunter
//
//  Created by Nicolas Seriot on 10/4/12.
//  Copyright (c) 2012 seriot.ch. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class STTwitterAPIWrapper;

@class THLocationPickerWindowController;

@class THTweetLocation;

@protocol TWLocationPickerProtocol
- (void)locationPicker:(THLocationPickerWindowController *)locationPicker didChooseLocation:(THTweetLocation *)tweetLocation;
- (void)locationPickerDidCancel:(THLocationPickerWindowController *)locationPicker;
@end

@interface THLocationPickerWindowController : NSWindowController

@property (nonatomic, retain) STTwitterAPIWrapper *twitter;
@property (nonatomic, copy) THTweetLocation *tweetLocation;
@property (nonatomic, assign) NSObject <TWLocationPickerProtocol> *delegate;

- (IBAction)ok:(id)sender;
- (IBAction)cancel:(id)sender;

@end
