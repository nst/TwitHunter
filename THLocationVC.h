//
//  THLocationVC.h
//  TwitHunter
//
//  Created by Nicolas Seriot on 10/9/12.
//  Copyright (c) 2012 seriot.ch. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class STTwitterAPI;
@class THTweetLocation;
@class THLocationPanel;
@class THLocationVC;

@protocol THLocationVCProtocol
- (void)locationVC:(THLocationVC *)locationVC didChooseLocation:(THTweetLocation *)location;
- (void)locationVCDidCancel:(THLocationVC *)locationVC;
@end

@interface THLocationVC : NSViewController

@property (nonatomic, unsafe_unretained) id <THLocationVCProtocol> locationDelegate;
@property (nonatomic, strong) STTwitterAPI *twitter;
@property (nonatomic, strong) THTweetLocation *tweetLocation;
@property (nonatomic, strong) IBOutlet NSArrayController *twitterPlacesController;
@property (nonatomic, strong) NSArray *twitterPlaces;

- (IBAction)lookupIPAddress:(id)sender;
- (IBAction)lookupCoordinates:(id)sender;
- (IBAction)lookupQuery:(id)sender;

- (IBAction)ok:(id)sender;
- (IBAction)cancel:(id)sender;

@end
