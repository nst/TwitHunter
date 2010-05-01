//
//  THController.h
//  TwitHunter
//
//  Created by Nicolas Seriot on 19.04.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MGTwitterEngine.h"

@interface THController : NSObject <MGTwitterEngineDelegate> {
    MGTwitterEngine *twitterEngine;
	NSTimer *timer;

	IBOutlet NSArrayController *tweetArrayController;
	IBOutlet NSArrayController *userArrayController;
	IBOutlet NSArrayController *keywordArrayController;
	IBOutlet NSCollectionView *collectionView;
	IBOutlet NSPanel *preferences;

	NSArray *tweetSortDescriptors;
	NSPredicate *tweetFilterPredicate;
	NSString *tweetText;
	NSMutableSet *requestsIDs;
	NSNumber *isConnecting;
	NSString *requestStatus;
}

@property (nonatomic, retain) MGTwitterEngine *twitterEngine;
@property (nonatomic, retain) NSArray *tweetSortDescriptors;
@property (nonatomic, retain) NSPredicate *tweetFilterPredicate;
@property (nonatomic, retain) NSString *tweetText;
@property (nonatomic, retain) NSMutableSet *requestsIDs;
@property (nonatomic, retain) NSNumber *isConnecting;
@property (nonatomic, retain) NSString *requestStatus;
@property (nonatomic, retain) NSTimer *timer;

- (IBAction)update:(id)sender;
- (IBAction)tweet:(id)sender;
- (IBAction)updateCredentials:(id)sender;
- (IBAction)updateTweetScores:(id)sender;

- (IBAction)markAllAsRead:(id)sender;
- (IBAction)markAllAsUnread:(id)sender;

@end
