//
//  THLocationVC.h
//  TwitHunter
//
//  Created by Nicolas Seriot on 10/9/12.
//  Copyright (c) 2012 seriot.ch. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class STTwitterAPIWrapper;
@class THTweetLocation;
@class THLocationPanel;
@class THLocationVC;

@protocol THLocationVCProtocol
- (void)locationVC:(THLocationVC *)locationVC didChooseLocation:(THTweetLocation *)location;
- (void)locationVCDidCancel:(THLocationVC *)locationVC;
@end

@interface THLocationVC : NSViewController

@property (nonatomic, assign) id <THLocationVCProtocol> locationDelegate;
@property (nonatomic, retain) STTwitterAPIWrapper *twitter;
@property (nonatomic, retain) THTweetLocation *tweetLocation;
@property (nonatomic, retain) NSArray *twitterPlaces;

- (IBAction)lookupLocation:(id)sender;

- (IBAction)ok:(id)sender;
- (IBAction)cancel:(id)sender;

@end
