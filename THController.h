//
//  THController.h
//  TwitHunter
//
//  Created by Nicolas Seriot on 19.04.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "THCumulativeChartView.h"
#import "THLocationVC.h"
#import "THPreferencesWC.h"

#pragma mark FIXME: favorites syncronisation

#define MAX_COUNT 100

@class STTwitterAPI;
@class THTweet;
@class THTweetLocation;
@class THLocationPanel;
@class THLocationVC;
@class THCumulativeChartView;
@class THPreferencesWC;

@interface THController : NSObject <CumulativeChartViewDelegate, CumulativeChartViewDataSource, THLocationVCProtocol, THPreferencesWCDelegate> {
	NSUInteger tweetsCount;
	NSUInteger numberOfTweetsForScore[MAX_COUNT+1];
	NSUInteger cumulatedTweetsForScore[MAX_COUNT+1];
}

@property (nonatomic, strong) IBOutlet NSWindow *window;
@property (nonatomic, strong) IBOutlet NSArrayController *tweetArrayController;
@property (nonatomic, strong) IBOutlet NSArrayController *userArrayController;
@property (nonatomic, strong) IBOutlet NSArrayController *keywordArrayController;
@property (nonatomic, strong) IBOutlet NSPanel *locationPanel;
@property (nonatomic, strong) IBOutlet NSCollectionView *collectionView;
@property (nonatomic, strong) IBOutlet THCumulativeChartView *cumulativeChartView;
@property (nonatomic, strong) IBOutlet NSTextField *expectedNbTweetsLabel;
@property (nonatomic, strong) IBOutlet NSTextField *expectedScoreLabel;
@property (nonatomic, strong) NSArray *twitterClients;
@property (nonatomic, strong) THPreferencesWC *preferencesWC;

- (IBAction)update:(id)sender;
- (IBAction)synchronizeFavorites:(id)sender;
- (IBAction)chooseMedia:(id)sender;
- (IBAction)chooseLocation:(id)sender;
- (IBAction)tweet:(id)sender;
- (IBAction)updateTweetScores:(id)sender;

- (IBAction)markAllAsRead:(id)sender;
- (IBAction)markAllAsUnread:(id)sender;

- (IBAction)openPreferences:(id)sender;

@end
