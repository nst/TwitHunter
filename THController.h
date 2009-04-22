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

	IBOutlet NSArrayController *tweetArrayController;
	IBOutlet NSArrayController *userArrayController;
	IBOutlet NSArrayController *textRuleArrayController;
	IBOutlet NSCollectionView *collectionView;
	IBOutlet NSPanel *preferences;

	NSArray *tweetSortDescriptors;
	NSPredicate *tweetFilterPredicate;
	NSString *tweetText;
	NSMutableSet *requestsIDs;
	NSNumber *isConnecting;
	NSString *requestStatus;
}

@property (nonatomic, retain) NSArray *tweetSortDescriptors;
@property (nonatomic, retain) NSPredicate *tweetFilterPredicate;
@property (nonatomic, retain) NSString *tweetText;
@property (nonatomic, retain) NSMutableSet *requestsIDs;
@property (nonatomic, retain) NSNumber *isConnecting;
@property (nonatomic, retain) NSString *requestStatus;

- (IBAction)update:(id)sender;
- (IBAction)tweet:(id)sender;
- (IBAction)updateCredentials:(id)sender;
- (IBAction)updateTweetScores:(id)sender;

@end
