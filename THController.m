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
#import "STTwitterEngine.h"
#import "NSArray+Functional.h"
#import "NSString+TH.h"

@implementation THController

@synthesize tweetSortDescriptors;
@synthesize tweetFilterPredicate;
@synthesize tweetText;
@synthesize isConnecting;
@synthesize requestStatus;
@synthesize timer;

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
	[latestTimeUpdateCulumatedDataWasAsked release];
	latestTimeUpdateCulumatedDataWasAsked = [[NSDate date] retain];
	    
    NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
    
    [queue addOperationWithBlock:^{
        
        NSDate *startDate = [[latestTimeUpdateCulumatedDataWasAsked copy] autorelease];
        
        NSUInteger totalTweetsCount = [Tweet tweetsCountWithAndPredicates:[self predicatesWithoutScore]];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self setTweetsCount:totalTweetsCount];
        }];
    	
        NSMutableArray *tweetsForScores = [NSMutableArray arrayWithCapacity:101];
        for(NSUInteger i = 0; i < 101; i++) {
            NSUInteger nbTweets = [Tweet nbOfTweetsForScore:[NSNumber numberWithUnsignedInt:i] andPredicates:[self predicatesWithoutScore]];
            [tweetsForScores addObject:[NSNumber numberWithInt:nbTweets]];
            
            BOOL requestOutdated = [startDate compare:latestTimeUpdateCulumatedDataWasAsked] == NSOrderedAscending;
            if(requestOutdated) {
                NSLog(@"updateCumulatedData was cancelled by a newer request");
                return;
            }
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self didFinishUpdatingCumulatedData:tweetsForScores];
        }];
        
        NSLog(@"updateCumulatedData took %f seconds", [[NSDate date] timeIntervalSinceDate:startDate]);

    }];
    
}

- (void)setTweetsCount:(NSUInteger)count {
	tweetsCount = count;
    
    [cumulativeChartView setNeedsDisplay:YES];
}

- (void)didFinishUpdatingCumulatedData:(NSArray *)tweetsForScores {
	
	for(NSUInteger i = 0; i < [tweetsForScores count]; i++) {
		numberOfTweetsForScore[i] = [[tweetsForScores objectAtIndex:i] intValue];
	}
	
	[self recomputeCumulatedTweetsForScore];
	
	[cumulativeChartView setNeedsDisplay:YES];
}

- (void)updateScoresForTweets:(NSArray *)tweets {

	NSLog(@"-- updating scores for %lu tweets", [tweets count]);
	
	// user score
	for(Tweet *t in tweets) {
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

	//[cumulativeChartView setNeedsDisplay:YES];
}

- (IBAction)updateTweetScores:(id)sender {
	NSLog(@"-- update scores");
	
	[self updateScoresForTweets:[Tweet allObjects]]; // TODO: optimize..
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
		
//		self.requestsIDs = [NSMutableSet set];
//		self.favoritesRequestsIDs = [NSMutableSet set];
		
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
	
	[self update:self];
}

- (IBAction)tweet:(id)sender {
    
    if(tweetText == nil) return;
    
	self.requestStatus = nil;

    NSSharingService *service = [NSSharingService sharingServiceNamed:NSSharingServiceNamePostOnTwitter];
    service.delegate = self;
    [service performWithItems:@[tweetText]];

    self.tweetText = nil;
}

- (IBAction)update:(id)sender {
	NSLog(@"-- update");
	
	self.requestStatus = nil;
	self.isConnecting = @YES;
	
	NSNumber *lastKnownID = [[NSUserDefaults standardUserDefaults] valueForKey:@"highestID"]; // TODO: get it programatically
	NSLog(@"-- found lastKnownID: %@", lastKnownID);
	
	if(lastKnownID && [lastKnownID unsignedLongLongValue] != 0) {
		NSLog(@"-- fetch timeline since ID: %@", lastKnownID);

        self.requestStatus = @"fetching timeline since last known ID";
        
        self.isConnecting = @YES;
        
        [_twitterEngine fetchHomeTimelineSinceID:[lastKnownID unsignedLongLongValue] count:100 completionBlock:^(NSArray *statuses) {
            self.isConnecting = @NO;
            self.requestStatus = @"";
            [self statusesReceived:statuses];
        } errorBlock:^(NSError *error) {
            self.isConnecting = @NO;
            NSLog(@"-- error: %@", [error localizedDescription]);
            self.requestStatus = [error localizedDescription];
        }];

	} else {
		NSLog(@"-- fetch timeline last 50");

        self.requestStatus = @"fetching last 50 statuses";

        self.isConnecting = @YES;

        [_twitterEngine fetchHomeTimeline:50 completionBlock:^(NSArray *statuses) {
            self.isConnecting = @NO;
            self.requestStatus = @"";
            [self statusesReceived:statuses];
        } errorBlock:^(NSError *error) {
            NSLog(@"-- error: %@", [error localizedDescription]);
            self.isConnecting = @NO;
            self.requestStatus = [error localizedDescription];
        }];
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

- (void)synchronizeFavoritesForUsername:(NSString *)aUsername {
    
    NSLog(@"-- %@", aUsername);
        
    return; // FIXME
    
	self.requestStatus = @"Syncronizing Favorites";
	self.isConnecting = @YES;

    self.requestStatus = @"";
    
	[_twitterEngine fetchFavoriteUpdatesForUsername:aUsername completionBlock:^(NSArray *statuses) {
        self.isConnecting = @NO;
        [self statusesReceived:statuses];
    } errorBlock:^(NSError *error) {
        NSLog(@"-- error: %@", [error localizedDescription]);
        self.isConnecting = @NO;
        self.requestStatus = [error localizedDescription];
        
    }];
    
//	[requestsIDs addObject:s];
//	[favoritesRequestsIDs addObject:s];
}

- (IBAction)synchronizeFavorites:(id)sender {
	NSString *username = [[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:@"values.username"];
	[self synchronizeFavoritesForUsername:username];
}

- (void)awakeFromNib {
	NSLog(@"awakeFromNib");
	
	NSNumber *currentScore = [[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:@"values.score"];
	[cumulativeChartView setScore:[currentScore integerValue]];
	
	[self updateTweetFilterPredicate];
	
	//[self updateTweetScores:self];

	[collectionView setMaxNumberOfColumns:1];
	
	self.twitterEngine = [[[STTwitterEngine alloc] init] autorelease];
    
    self.requestStatus = @"requesting access";
    
    [_twitterEngine requestAccessWithCompletionBlock:^(ACAccount *twitterAccount) {

        self.requestStatus = [NSString stringWithFormat:@"access granted for %@", twitterAccount];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeTweetReadStatusNotification:) name:@"DidChangeTweetReadStateNotification" object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setFavoriteFlagForTweet:) name:@"SetFavoriteFlagForTweet" object:nil];
        
        [self update:self];
        
        [self updateCumulatedData];
        
        NSString *username = [_twitterEngine username];
        
        [self synchronizeFavoritesForUsername:username];
        
        [self resetTimer];
        
    } errorBlock:^(NSError *error) {
        NSLog(@"-- %@", [error localizedDescription]);
        self.requestStatus = [error localizedDescription];
    }];
		
}

- (void)setFavoriteFlagForTweet:(NSNotification *)aNotification {
	Tweet *tweet = [aNotification object];
	BOOL value = [[[aNotification userInfo] valueForKey:@"value"] boolValue];
	
	//NSLog(@"-- %d %@", value, tweet);
	NSString *s = [_twitterEngine markUpdate:[tweet.uid unsignedLongLongValue] asFavorite:value];
//	[requestsIDs addObject:s];
//	self.isConnecting = [NSNumber numberWithBool:[requestsIDs count] != 0];
}

- (IBAction)markAllAsRead:(id)sender {
	[[tweetArrayController arrangedObjects] setValue:@YES forKey:@"isRead"];
	[tweetArrayController rearrangeObjects];
}

- (IBAction)markAllAsUnread:(id)sender {
	[[tweetArrayController arrangedObjects] setValue:@NO forKey:@"isRead"];
	[tweetArrayController rearrangeObjects];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[_twitterEngine release];
	[timer release];
	[tweetSortDescriptors release];
	[tweetFilterPredicate release];
	[tweetText release];
	[isConnecting release];
	[requestStatus release];	
	[super dealloc];
}

//- (void)requestSucceeded:(NSString *)requestIdentifier {
//	NSLog(@"requestSucceeded:%@", requestIdentifier);
//
//	self.requestStatus = nil;
////	[requestsIDs removeObject:requestIdentifier];
////	self.isConnecting = [NSNumber numberWithBool:[requestsIDs count] != 0];
//}
//
//- (void)requestFailed:(NSString *)requestIdentifier withError:(NSError *)error {
//	NSLog(@"requestFailed:%@ withError:%@", requestIdentifier, [error localizedDescription]);
//
//	self.requestStatus = [error localizedDescription];
////	[requestsIDs removeObject:requestIdentifier];
////	self.isConnecting = [NSNumber numberWithBool:[requestsIDs count] != 0];
//}

- (void)statusesReceived:(NSArray *)statuses {
	NSLog(@"-- statusesReceived: %ld", [statuses count]);
	
	self.requestStatus = nil;
//	[requestsIDs removeObject:identifier];
//	self.isConnecting = [NSNumber numberWithBool:[requestsIDs count] != 0];

	if([statuses count] == 0) return;
	
	BOOL isFavoritesRequest = NO; // TODO: sometimes YES
	
	if(isFavoritesRequest) {
		// statuses are assumed to be ordered by DESC id
		NSArray *statusesIds = [statuses valueForKeyPath:@"id"];
		NSString *minIdString = [statusesIds lastObject];
		NSString *maxIdString = [statusesIds objectAtIndex:0];
		
		NSNumber *unfavorMinId = [NSNumber numberWithUnsignedLongLong:[minIdString unsignedLongLongValue]];
		NSNumber *unfavorMaxId = [NSNumber numberWithUnsignedLongLong:[maxIdString unsignedLongLongValue]];
		
		[Tweet unfavorFavoritesBetweenMinId:unfavorMinId maxId:unfavorMaxId];
	}
		
	NSDictionary *boundingIds = [Tweet saveTweetsFromDictionariesArray:statuses];
	
	NSNumber *lowestId = [boundingIds valueForKey:@"lowestId"];
	NSNumber *higestId = [boundingIds valueForKey:@"higestId"];
	
	if(higestId) {
		[[NSUserDefaults standardUserDefaults] setObject:higestId forKey:@"highestID"];
		NSLog(@"-- stored highestID: %@", higestId);
	}
	
	[self updateScoresForTweets:[Tweet tweetsWithIdGreaterOrEqualTo:lowestId]];
	
	[self updateTweetFilterPredicate];
}

#pragma mark CumulativeChartViewDelegate

- (void)chartView:(CumulativeChartView *)aChartView didSlideToScore:(NSUInteger)aScore {
	//NSLog(@"-- didSlideToScore:%d", aScore);
	
	[expectedNbTweetsLabel setStringValue:[NSString stringWithFormat:@"%ld", cumulatedTweetsForScore[aScore]]];
	[expectedScoreLabel setStringValue:[NSString stringWithFormat:@"%ld", aScore]];	
}

- (void)chartView:(CumulativeChartView *)aChartView didStopSlidingOnScore:(NSUInteger)aScore {
	//NSLog(@"-- didStopSlidingOnScore:%d", aScore);
	
	[expectedNbTweetsLabel setStringValue:[NSString stringWithFormat:@"%ld", cumulatedTweetsForScore[aScore]]];
	[expectedScoreLabel setStringValue:[NSString stringWithFormat:@"%ld", aScore]];

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

#pragma mark NSSharingServiceDelegate

//- (void)sharingService:(NSSharingService *)sharingService willShareItems:(NSArray *)items;
//- (void)sharingService:(NSSharingService *)sharingService didFailToShareItems:(NSArray *)items error:(NSError *)error;
//- (void)sharingService:(NSSharingService *)sharingService didShareItems:(NSArray *)items;
//
///* The following methods are invoked when the service is performed and the sharing window pops up, to present a transition between the original items and the sharing window.
// */
//- (NSRect)sharingService:(NSSharingService *)sharingService sourceFrameOnScreenForShareItem:(id <NSPasteboardWriting>)item;
//- (NSImage *)sharingService:(NSSharingService *)sharingService transitionImageForShareItem:(id <NSPasteboardWriting>)item contentRect:(NSRect *)contentRect;
//- (NSWindow *)sharingService:(NSSharingService *)sharingService sourceWindowForShareItems:(NSArray *)items sharingContentScope:(NSSharingContentScope *)sharingContentScope;

@end
