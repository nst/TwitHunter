//
//  THController.h
//  TwitHunter
//
//  Created by Nicolas Seriot on 19.04.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGTwitterEngine.h"
#import "CumulativeChartView.h"

#define MAX_COUNT 100

@interface THController : NSObject <MGTwitterEngineDelegate, CumulativeChartViewDelegate, CumulativeChartViewDataSource> {
    MGTwitterEngine *twitterEngine;
	NSTimer *timer;
	
	IBOutlet NSArrayController *tweetArrayController;
	IBOutlet NSArrayController *userArrayController;
	IBOutlet NSArrayController *keywordArrayController;
	IBOutlet NSCollectionView *collectionView;
	IBOutlet NSPanel *preferences;
	IBOutlet CumulativeChartView *cumulativeChartView;

	NSArray *tweetSortDescriptors;
	NSPredicate *tweetFilterPredicate;
	NSString *tweetText;
	NSMutableSet *requestsIDs;
	NSMutableSet *favoritesRequestsIDs;
	NSNumber *isConnecting;
	NSString *requestStatus;
	
	IBOutlet NSTextField *expectedNbTweetsLabel;
	IBOutlet NSTextField *expectedScoreLabel;

	NSUInteger tweetsCount;
	NSUInteger numberOfTweetsForScore[MAX_COUNT+1];
	NSUInteger cumulatedTweetsForScore[MAX_COUNT+1];
}

@property (nonatomic, retain) MGTwitterEngine *twitterEngine;
@property (nonatomic, retain) NSArray *tweetSortDescriptors;
@property (nonatomic, retain) NSPredicate *tweetFilterPredicate;
@property (nonatomic, retain) NSString *tweetText;
@property (nonatomic, retain) NSMutableSet *requestsIDs;
@property (nonatomic, retain) NSMutableSet *favoritesRequestsIDs;
@property (nonatomic, retain) NSNumber *isConnecting;
@property (nonatomic, retain) NSString *requestStatus;
@property (nonatomic, retain) NSTimer *timer;

- (IBAction)update:(id)sender;
- (IBAction)synchronizeFavorites:(id)sender;
- (IBAction)tweet:(id)sender;
- (IBAction)updateCredentials:(id)sender;
- (IBAction)updateTweetScores:(id)sender;

- (IBAction)markAllAsRead:(id)sender;
- (IBAction)markAllAsUnread:(id)sender;

@end
