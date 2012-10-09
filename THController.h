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

#define MAX_COUNT 100

@class STTwitterAPIWrapper;
@class THTweet;
@class THTweetLocation;
@class THLocationPanel;
@class THLocationVC;

@interface THController : NSObject <CumulativeChartViewDelegate, CumulativeChartViewDataSource, THLocationVCProtocol> {
	NSTimer *timer;
    	
	IBOutlet NSArrayController *tweetArrayController;
	IBOutlet NSArrayController *userArrayController;
	IBOutlet NSArrayController *keywordArrayController;
	IBOutlet NSCollectionView *collectionView;
	IBOutlet NSPanel *preferences;
	IBOutlet THCumulativeChartView *cumulativeChartView;
    
	NSArray *tweetSortDescriptors;
	NSPredicate *tweetFilterPredicate;
	NSString *tweetText;
	NSNumber *isConnecting;
	NSString *requestStatus;
	
	IBOutlet NSTextField *expectedNbTweetsLabel;
	IBOutlet NSTextField *expectedScoreLabel;

	NSUInteger tweetsCount;
	NSUInteger numberOfTweetsForScore[MAX_COUNT+1];
	NSUInteger cumulatedTweetsForScore[MAX_COUNT+1];
	
	NSDate *latestTimeUpdateCulumatedDataWasAsked;
}

@property (nonatomic, retain) IBOutlet NSPanel *locationPanel;
@property (nonatomic, retain) THTweetLocation *tweetLocation;
@property (nonatomic, retain) THLocationVC *locationVC;

@property (nonatomic, retain) IBOutlet NSWindow *window;
@property (nonatomic, retain) STTwitterAPIWrapper *twitter;
@property (nonatomic, retain) NSArray *tweetSortDescriptors;
@property (nonatomic, retain) NSPredicate *tweetFilterPredicate;
@property (nonatomic, retain) NSString *tweetText;
@property (nonatomic, retain) NSNumber *isConnecting;
@property (nonatomic, retain) NSString *requestStatus;
@property (nonatomic, retain) NSTimer *timer;

@property (nonatomic, retain) NSURL *postMediaURL;

- (IBAction)update:(id)sender;
- (IBAction)synchronizeFavorites:(id)sender;
- (IBAction)chooseMedia:(id)sender;
- (IBAction)chooseLocation:(id)sender;
- (IBAction)tweet:(id)sender;
- (IBAction)updateCredentials:(id)sender;
- (IBAction)updateTweetScores:(id)sender;

- (IBAction)markAllAsRead:(id)sender;
- (IBAction)markAllAsUnread:(id)sender;

@end
