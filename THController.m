//
//  THController.m
//  TwitHunter
//
//  Created by Nicolas Seriot on 19.04.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import "THController.h"
#import "Tweet.h"
#import "User.h"
#import "TextRule.h"
#import "NSManagedObject+TH.h"
#import "TweetCollectionViewItem.h"
#import "MGTwitterEngine+TH.h"

@implementation THController

@synthesize tweetSortDescriptors;
@synthesize tweetFilterPredicate;
@synthesize tweetText;
@synthesize requestsIDs;
@synthesize isConnecting;
@synthesize requestStatus;
@synthesize timer;
@synthesize twitterEngine;

- (NSMutableArray *)predicatesWithoutScore {
	NSMutableArray *a = [NSMutableArray array];
	
	NSNumber *hideRead = [[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:@"values.hideRead"];
	if([hideRead boolValue]) {
		NSPredicate *p2 = [NSPredicate predicateWithFormat:@"isRead == NO"];
		[a addObject:p2];
	}
	
	NSNumber *hideURLs = [[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:@"values.hideURLs"];
	if([hideURLs boolValue]) {
		NSPredicate *p3 = [NSPredicate predicateWithFormat:@"containsURL == NO"];
		[a addObject:p3];
	}
	
	return a;
}

- (NSUInteger)tweetsCount {
	return tweetsCount;	
}

- (void)recomputeCumulatedTweetsForScore {
	NSUInteger total = 0;
	for(NSUInteger i = 100; i > 0; i--) {
		total += numberOfTweetsForScore[i];
		cumulatedTweetsForScore[i] = total;
	}
	cumulatedTweetsForScore[0] = tweetsCount;
}

- (void)updateCumulatedData {
	NSDate *startDate = [NSDate date];
	
	tweetsCount = [Tweet tweetsCountWithAndPredicates:[self predicatesWithoutScore]];
	
	NSUInteger total = 0;
	
	for(NSUInteger i = 101; i > 0; i--) {
		NSUInteger nbTweets = [Tweet nbOfTweetsForScore:[NSNumber numberWithUnsignedInt:i] andPredicates:[self predicatesWithoutScore]];
		total += nbTweets;
		numberOfTweetsForScore[i] = nbTweets;
	}

	NSLog(@"updateCumulatedData took %f seconds", [[NSDate date] timeIntervalSinceDate:startDate]);
	
	[self recomputeCumulatedTweetsForScore];
	
	[cumulativeChartView setNeedsDisplay:YES];
}

- (IBAction)updateTweetScores:(id)sender {
	NSLog(@"-- update scores");
	
	// user score
	for(Tweet *t in [Tweet allObjects]) {
		NSInteger score = 50 + [t.user.score intValue];
		if(score < 0) score = 0;
		if(score > 100) score = 100;		
		t.score = [NSNumber numberWithInt:score];
	}

	// text score
	for(TextRule *rule in [TextRule allObjects]) {
		NSArray *tweetsContainingKeyword = [Tweet tweetsContainingKeyword:rule.keyword];
		for(Tweet *t in tweetsContainingKeyword) {
			NSInteger score = [t.score intValue];
			score += [rule.score intValue];
			if(score < 0) score = 0;
			if(score > 100) score = 100;
			t.score = [NSNumber numberWithInt:score];
		}
	}
	
	NSError *error = nil;
	[[Tweet moc] save:&error];
	if(error) {
		NSLog(@"-- error:%@", error);
	}
	
	[tweetArrayController rearrangeObjects];
	
	[self updateCumulatedData];

	[cumulativeChartView setNeedsDisplay:YES];
}

- (void)updateTweetFilterPredicate {
	NSMutableArray *predicates = [self predicatesWithoutScore];

	NSNumber *score = [[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:@"values.score"];
	NSPredicate *p1 = [NSPredicate predicateWithFormat:@"score >= %@", score];
	[predicates addObject:p1];
		
	self.tweetFilterPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
	
	[tweetArrayController rearrangeObjects];

	//[self updateCumulatedData];

	//[cumulativeChartView setNeedsDisplay:YES];
}

- (id)init {
	if (self = [super init]) {
		NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
		self.tweetSortDescriptors = [NSArray arrayWithObject:sd];
		[sd release];

		NSString *defaultsPath = [[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"];
		NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:defaultsPath];
		[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
		
		self.requestsIDs = [NSMutableSet set];
		
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.score" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:NULL];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.hideRead" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:NULL];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.hideURLs" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:NULL];
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.updateFrequency" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:NULL];
	}
	
	return self;
}

- (void)timerTick {
	[self update:self];
}

- (void)resetTimer {
	if(self.timer) {
		[timer invalidate];
	}
	
	NSTimeInterval seconds = [[[NSUserDefaults standardUserDefaults] valueForKey:@"updateFrequency"] doubleValue] * 60;
	
	seconds = MAX(seconds, 60);
	
	self.timer = [NSTimer scheduledTimerWithTimeInterval:seconds
												  target:self
												selector:@selector(timerTick)
												userInfo:NULL
												 repeats:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	//NSLog(@"-- keyPath %@", keyPath);
	
	if(object == [NSUserDefaultsController sharedUserDefaultsController] &&
	   [[NSArray arrayWithObjects:@"values.score", nil] containsObject:keyPath]) {
		[self updateTweetFilterPredicate];
		return;
	}
	
	if(object == [NSUserDefaultsController sharedUserDefaultsController] &&
	   [[NSArray arrayWithObjects:@"values.hideRead", @"values.hideURLs", nil] containsObject:keyPath]) {
		[self updateTweetFilterPredicate];
		[self updateCumulatedData];
		return;
	}
	
	if(object == [NSUserDefaultsController sharedUserDefaultsController] &&
	   [[NSArray arrayWithObjects:@"values.updateFrequency", nil] containsObject:keyPath]) {
		[self resetTimer];
		return;
	}
	
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (IBAction)updateCredentials:(id)sender {
	[preferences close];
	
	NSString *username = [[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:@"values.username"];
	NSString *password = [[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:@"values.password"];
	[twitterEngine setUsername:username password:password];
	
	[self update:self];
}

- (IBAction)tweet:(id)sender {
	self.requestStatus = nil;
	NSString *requestID = [twitterEngine sendUpdate:tweetText];
	if(requestID) {
		[requestsIDs addObject:requestID];
	}
	self.tweetText = nil;
}

- (IBAction)update:(id)sender {
	NSLog(@"-- update");
	
	self.requestStatus = nil;
	self.isConnecting = [NSNumber numberWithBool:YES];
	
	NSNumber *lastKnownID = [[NSUserDefaults standardUserDefaults] valueForKey:@"highestID"]; 
	NSLog(@"-- found lastKnownID: %@", lastKnownID);
	
	if(lastKnownID && [lastKnownID unsignedLongLongValue] != 0) {
		NSLog(@"-- fetch timeline since ID: %@", lastKnownID);
		NSString *requestID = [twitterEngine getHomeTimelineSinceID:[lastKnownID unsignedLongLongValue] withMaximumID:0 startingAtPage:0 count:100];
		[requestsIDs addObject:requestID];
	} else {
		NSLog(@"-- fetch timeline last 50");
		NSArray *requestIDs = [twitterEngine getHomeTimeline:50];
		[requestsIDs addObjectsFromArray:requestIDs];		
	}
}

- (void)didChangeTweetReadStatusNotification:(NSNotification *)aNotification {
	BOOL hideRead = [[[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:@"values.hideRead"] boolValue];
	if(!hideRead) return;

	Tweet *tweet = [[aNotification userInfo] objectForKey:@"Tweet"];
	NSUInteger tweetScore = [tweet.score unsignedIntegerValue];

	numberOfTweetsForScore[tweetScore] += [tweet.isRead boolValue] ? -1 : +1;
	if([[tweet isRead] boolValue]) tweetsCount -= 1;
	
	[self recomputeCumulatedTweetsForScore];
	
	NSNumber *currentScore = [[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:@"values.score"];
	
	[cumulativeChartView setScore:[currentScore unsignedIntegerValue]];
	[cumulativeChartView setNeedsDisplay:YES];
		
	[tweetArrayController rearrangeObjects];	
}

- (void)awakeFromNib {
	NSLog(@"awakeFromNib");
	
	NSNumber *currentScore = [[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:@"values.score"];
	[cumulativeChartView setScore:[currentScore integerValue]];
	
	[self updateTweetFilterPredicate];
	
	[self updateTweetScores:self];

	[collectionView setMaxNumberOfColumns:1];
	
	self.twitterEngine = [[[MGTwitterEngine alloc] initWithDelegate:self] autorelease];
	
	NSString *username = [[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:@"values.username"];
	NSString *password = [[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:@"values.password"];
	
	if([username length] == 0 || [password length] == 0) {
        NSLog(@"You forgot to specify your username/password!");
		[preferences makeKeyAndOrderFront:self];
		return;
	}
	
    [twitterEngine setUsername:username password:password];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeTweetReadStatusNotification:) name:@"DidChangeTweetReadStateNotification" object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setFavoriteFlagForTweet:) name:@"SetFavoriteFlagForTweet" object:nil];
	
	[self update:self];
	
	[self resetTimer];
}

- (void)setFavoriteFlagForTweet:(NSNotification *)aNotification {
	Tweet *tweet = [aNotification object];
	BOOL value = [[[aNotification userInfo] valueForKey:@"value"] boolValue];
	
	//NSLog(@"-- %d %@", value, tweet);
	NSString *s = [twitterEngine markUpdate:[tweet.uid unsignedLongLongValue] asFavorite:value];
	[requestsIDs addObject:s];
	self.isConnecting = [NSNumber numberWithBool:[requestsIDs count] != 0];
}

- (IBAction)markAllAsRead:(id)sender {
	[[tweetArrayController arrangedObjects] setValue:[NSNumber numberWithBool:YES] forKey:@"isRead"];
	[tweetArrayController rearrangeObjects];
}

- (IBAction)markAllAsUnread:(id)sender {
	[[tweetArrayController arrangedObjects] setValue:[NSNumber numberWithBool:NO] forKey:@"isRead"];
	[tweetArrayController rearrangeObjects];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[twitterEngine release];
	[timer release];
	[tweetSortDescriptors release];
	[tweetFilterPredicate release];
	[tweetText release];
	[requestsIDs release];
	[isConnecting release];
	[requestStatus release];
	[requestsIDs release];
	
	[super dealloc];
}

#pragma mark MGTwitterEngineDelegate

- (void)requestSucceeded:(NSString *)requestIdentifier {
	NSLog(@"requestSucceeded:%@", requestIdentifier);

	self.requestStatus = nil;
	[requestsIDs removeObject:requestIdentifier];
	self.isConnecting = [NSNumber numberWithBool:[requestsIDs count] != 0];
}

- (void)requestFailed:(NSString *)requestIdentifier withError:(NSError *)error {
	NSLog(@"requestFailed:%@ withError:%@", requestIdentifier, [error localizedDescription]);

	self.requestStatus = [error localizedDescription];
	[requestsIDs removeObject:requestIdentifier];
	self.isConnecting = [NSNumber numberWithBool:[requestsIDs count] != 0];
}

- (void)statusesReceived:(NSArray *)statuses forRequest:(NSString *)identifier {
	NSLog(@"-- statusesReceived: %d", [statuses count]);
	
	self.requestStatus = nil;
	[requestsIDs removeObject:identifier];
	self.isConnecting = [NSNumber numberWithBool:[requestsIDs count] != 0];
	
	MGTwitterEngineID highestID = [Tweet saveTweetsFromDictionariesArray:statuses];
	
	NSNumber *highestKnownID = [NSNumber numberWithUnsignedLongLong:highestID];
	
	if(highestID != 0) {
		[[NSUserDefaults standardUserDefaults] setObject:highestKnownID forKey:@"highestID"];
		NSLog(@"-- stored highestID: %@", highestKnownID);
	}
	
	[self updateTweetScores:self];
}

- (void)directMessagesReceived:(NSArray *)messages forRequest:(NSString *)identifier {
	NSLog(@"directMessagesReceived:%@ forRequest:", messages, identifier);
}

- (void)userInfoReceived:(NSArray *)userInfo forRequest:(NSString *)identifier {
	NSLog(@"userInfoReceived:%@ forRequest:", userInfo, identifier);
}

- (void)connectionFinished {
	NSLog(@"connectionFinished");
}

- (void)miscInfoReceived:(NSArray *)miscInfo forRequest:(NSString *)connectionIdentifier {
	NSLog(@"miscInfoReceived:%@ forRequest:%@", miscInfo, connectionIdentifier);
}

- (void)imageReceived:(NSImage *)image forRequest:(NSString *)connectionIdentifier {
	NSLog(@"imageReceived:%@ forRequest:%@", image, connectionIdentifier);
}

#pragma mark CumulativeChartViewDelegate

- (void)didSlideToScore:(NSUInteger)aScore {
	//NSLog(@"-- didSlideToScore:%d", aScore);
	
	[expectedNbTweetsLabel setStringValue:[NSString stringWithFormat:@"%d", cumulatedTweetsForScore[aScore]]];
	[expectedScoreLabel setStringValue:[NSString stringWithFormat:@"%d", aScore]];	
}

- (void)didStopSlidingOnScore:(NSUInteger)aScore {
	//NSLog(@"-- didStopSlidingOnScore:%d", aScore);
	
	[expectedNbTweetsLabel setStringValue:[NSString stringWithFormat:@"%d", cumulatedTweetsForScore[aScore]]];
	[expectedScoreLabel setStringValue:[NSString stringWithFormat:@"%d", aScore]];	

	NSUInteger score = [[[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:@"values.score"] unsignedIntegerValue];
	
	if(aScore == score) return;
	
	[[NSUserDefaultsController sharedUserDefaultsController] setValue:[NSNumber numberWithUnsignedInteger:aScore] forKeyPath:@"values.score"];
}

#pragma mark CumulativeChartViewDataSource

- (NSUInteger)numberOfTweets {
	return tweetsCount;
}

- (NSUInteger)cumulatedTweetsForScore:(NSUInteger)aScore {
	return cumulatedTweetsForScore[aScore];
}

@end
