//
//  THController.m
//  TwitHunter
//
//  Created by Nicolas Seriot on 19.04.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import "THController.h"
#import "THTweet.h"
#import "THUser.h"
#import "THTextRule.h"
#import "NSManagedObject+ST.h"
#import "NSString+TH.h"
#import "STTwitterAPIWrapper.h"
#import "THTweetLocation.h"
#import "THLocationVC.h"
#import "THCumulativeChartView.h"
#import "THPreferencesWC.h"

// TODO: https://developer.apple.com/library/mac/#qa/qa2006/qa1487.html
// TODO: https://github.com/blladnar/AutoLink
// TODO: http://www.nightproductions.net/developer.htm

@interface THController ()
@property (nonatomic, retain) THTweetLocation *tweetLocation;
@property (nonatomic, retain) THLocationVC *locationVC;
@property (nonatomic, retain) STTwitterAPIWrapper *twitter;
@property (nonatomic, retain) NSDate *latestTimeUpdateCulumatedDataWasAsked;
@property (nonatomic, retain) NSArray *tweetSortDescriptors;
@property (nonatomic, retain) NSPredicate *tweetFilterPredicate;
@property (nonatomic, retain) NSString *tweetText;
@property (nonatomic, retain) NSNumber *isConnecting;
@property (nonatomic, retain) NSString *requestStatus;
@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, retain) NSURL *postMediaURL;
@end

@implementation THController

- (NSMutableArray *)predicatesWithoutScore {
	NSMutableArray *a = [NSMutableArray array];
	
	NSNumber *hideRead = [[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:@"values.hideRead"];
	if([hideRead boolValue]) {
		NSPredicate *p2 = [NSPredicate predicateWithFormat:@"isRead == NO"];
		[a addObject:p2];
	}
	
    //	NSNumber *hideURLs = [[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:@"values.hideURLs"];
    //	if([hideURLs boolValue]) {
    //		NSPredicate *p3 = [NSPredicate predicateWithFormat:@"containsURL == NO"];
    //		[a addObject:p3];
    //	}
	
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
        printf("%lu ", total);
	}
	cumulatedTweetsForScore[0] = tweetsCount;
    printf("\n");
}

- (void)updateCumulatedData {
    
	self.latestTimeUpdateCulumatedDataWasAsked = [[NSDate date] retain];
    
    NSDate *startDate = [[_latestTimeUpdateCulumatedDataWasAsked copy] autorelease];
    
    NSArray *predicates = [self predicatesWithoutScore];
    
    NSManagedObjectContext *mainContext = [(id)[[NSApplication sharedApplication] delegate] managedObjectContext];
    NSManagedObjectContext *privateContext = [[[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType] autorelease];
    privateContext.parentContext = mainContext;
    
    __block NSArray *tweets = nil;
    
    [privateContext performBlockAndWait:^{
        tweets = [THTweet tweetsWithAndPredicates:predicates context:privateContext];
    }];
    
    NSUInteger count = [tweets count];
    NSLog(@"-- total number of tweets: %lu", count);
    
    [self setTweetsCount:count];
    
    for(NSUInteger i = 0; i < 101; i++) {
        numberOfTweetsForScore[i] = 0;
    }
    
    for(THTweet *t in tweets) {
        NSInteger score = [t.score integerValue];
        numberOfTweetsForScore[score] += 1;
    }

    NSLog(@"updateCumulatedData took %f seconds", [[NSDate date] timeIntervalSinceDate:startDate]);

	[self recomputeCumulatedTweetsForScore];
	[_cumulativeChartView setNeedsDisplay:YES];
}

- (void)setTweetsCount:(NSUInteger)count {
	tweetsCount = count;
    
    [_cumulativeChartView setNeedsDisplay:YES];
}

- (void)updateScoresForTweets:(NSArray *)tweets context:(NSManagedObjectContext *)context {
    
    NSParameterAssert(context);
    
	NSLog(@"-- updating scores for %lu tweets", [tweets count]);

	__block BOOL success = NO;
    __block NSError *error = nil;
    
    [context performBlockAndWait:^{
        
        // user score
        for(THTweet *t in tweets) {
            NSInteger score = 50 + [t.user.score intValue];
            if(score < 0) score = 0;
            if(score > 100) score = 100;
            t.score = [NSNumber numberWithInt:score];
        }
        
        NSFetchRequest *fr = [[NSFetchRequest alloc] init];
        [fr setEntity:[THTextRule entityInContext:context]];
        NSArray *allRules = [context executeFetchRequest:fr error:nil];
        [fr release];
        
        // text score
        for(THTextRule *rule in allRules) {
            NSArray *tweetsContainingKeyword = [THTweet tweetsContainingKeyword:rule.keyword context:context];
            for(THTweet *t in tweetsContainingKeyword) {
                NSInteger score = [t.score intValue];
                score += [rule.score intValue];
                if(score < 0) score = 0;
                if(score > 100) score = 100;
                t.score = [NSNumber numberWithInt:score];
            }
        }
        
        success = [context save:&error];
    }];
    
    if(success == NO) {
        NSLog(@"-- save error: %@", [error localizedDescription]);
    }
}

- (IBAction)updateTweetScores:(id)sender {
	NSLog(@"-- update scores");
	
    NSManagedObjectContext *mainContext = [(id)[[NSApplication sharedApplication] delegate] managedObjectContext];
    NSManagedObjectContext *privateContext = [[[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType] autorelease];
    privateContext.parentContext = mainContext;
    
    __block NSArray *allTweets = nil;
    
    [privateContext performBlockAndWait:^{
        NSFetchRequest *fr = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [THTweet entityInContext:privateContext];
        [fr setEntity:entity];
        allTweets = [privateContext executeFetchRequest:fr error:nil];
        [fr release];
    }];
    
	[self updateScoresForTweets:allTweets context:privateContext];

    [self updateCumulatedData];

    NSError *error = nil;
    BOOL success = [mainContext save:&error];
    if(success == NO) {
        NSLog(@"-- save error: %@", [error localizedDescription]);
    }
}

- (void)updateTweetFilterPredicate {
	NSMutableArray *predicates = [self predicatesWithoutScore];
    
	NSNumber *score = [[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:@"values.score"];
	NSPredicate *p1 = [NSPredicate predicateWithFormat:@"score >= %@", score];
	[predicates addObject:p1];
    
    NSLog(@"-- NOW CONSIDERING SCORE >= %@", score);
    
	self.tweetFilterPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
}

- (id)init {
	if (self = [super init]) {
		NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
		self.tweetSortDescriptors = @[sd];
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
        
        [[NSNotificationCenter defaultCenter] addObserverForName:@"THTweetAction" object:nil queue:nil usingBlock:^(NSNotification *note) {
            NSDictionary *unserInfo = [note userInfo];
            THTweet *tweet = [unserInfo valueForKey:@"Tweet"];
            NSString *action = [unserInfo valueForKey:@"Action"];
            
            if([action isEqualToString:@"Retweet"]) {
                [self retweetTweet:tweet];
            } else if ([action isEqualToString:@"Reply"]) {
                [self replyToTweet:tweet];
            } else if ([action isEqualToString:@"RemoteDelete"]) {
                [self remoteDeleteTweet:tweet];
            }
            
        }];
    }
	
	return self;
}

- (void)timerTick {
	[self update:self];
}

- (void)resetTimer {
	if(self.timer) {
		[_timer invalidate];
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
        //[_tweetArrayController rearrangeObjects];
		return;
	}
	
	if(object == [NSUserDefaultsController sharedUserDefaultsController] &&
	   [[NSArray arrayWithObjects:@"values.hideRead", @"values.hideURLs", nil] containsObject:keyPath]) {
		[self updateTweetFilterPredicate];
		[self updateCumulatedData];
        //[_tweetArrayController rearrangeObjects];
		return;
	}
	
	if(object == [NSUserDefaultsController sharedUserDefaultsController] &&
	   [[NSArray arrayWithObjects:@"values.updateFrequency", nil] containsObject:keyPath]) {
		[self resetTimer];
		return;
	}
	    
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (IBAction)tweet:(id)sender {
    
    if(_tweetText == nil) return;
    
	self.requestStatus = @"Posting status...";
    
    if(_postMediaURL) {
        [_twitter postStatusUpdate:_tweetText inReplyToStatusID:nil mediaURL:_postMediaURL placeID:_tweetLocation.placeID lat:_tweetLocation.latitude lon:_tweetLocation.longitude successBlock:^(NSString *response) {
            self.tweetText = @"";
            self.requestStatus = @"OK, status was posted.";
            self.postMediaURL = nil;
        } errorBlock:^(NSError *error) {
            self.requestStatus = error ? [error localizedDescription] : @"Unknown error";
        }];
    } else {
        [_twitter postStatusUpdate:_tweetText inReplyToStatusID:nil placeID:_tweetLocation.placeID lat:_tweetLocation.latitude lon:_tweetLocation.longitude successBlock:^(NSString *response) {
            self.tweetText = @"";
            self.requestStatus = @"OK, status was posted.";
        } errorBlock:^(NSError *error) {
            self.requestStatus = [error localizedDescription];
        }];
    }
    
    //    NSSharingService *service = [NSSharingService sharingServiceNamed:NSSharingServiceNamePostOnTwitter];
    //    service.delegate = self;
    //    [service performWithItems:@[tweetText]];
    
}

- (IBAction)chooseLocation:(id)sender {
    
    NSTextField *latitudeTextField = [[[NSTextField alloc] initWithFrame:NSMakeRect(0,32, 180, 24)] autorelease];
    NSTextField *longitudeTextField = [[[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 180, 24)] autorelease];
    
    NSView *accessoryView = [[[NSView alloc] initWithFrame:NSMakeRect(0, 0, 200, 64)] autorelease];
    [accessoryView addSubview:latitudeTextField];
    [accessoryView addSubview:longitudeTextField];
    
    
    //    self.locationVC = [[[THLocationVC alloc] initWithNibName:@"THLocationVC" bundle:[NSBundle mainBundle]] autorelease];
    
    if(_tweetLocation == nil) {
        self.tweetLocation = [[[THTweetLocation alloc] init] autorelease];
    }
    
#pragma mark TODO:
    // NSWindow setContentView:
    
    self.locationVC = [[[THLocationVC alloc] initWithNibName:@"THLocationVC" bundle:nil] autorelease];
    _locationVC.twitter = _twitter;
    _locationVC.tweetLocation = [[_tweetLocation copy] autorelease];
    _locationVC.locationDelegate = self;
    
//    _locationVC.tweetLocation.latitude = @"46.5199617";
//    _locationVC.tweetLocation.longitude = @"6.6335971";
    
//    NSPanel *panel = [[[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, 800, 600)
//                                                 styleMask:NSBorderlessWindowMask
//                                                   backing:NSBackingStoreBuffered
//                                                     defer:NO] autorelease];

    [_locationPanel setFrame:NSMakeRect(0, 0, 600, 300) display:YES];
    
    [_locationPanel setContentView:_locationVC.view];
    
    [[NSApplication sharedApplication] beginSheet:_locationPanel
                                   modalForWindow:[[NSApplication sharedApplication] mainWindow]
                                    modalDelegate:self
                                   didEndSelector:NULL
                                      contextInfo:NULL];
    
    //    [panel setAccessoryView:_locationVC.view];
    //
    //    [panel beginSheetModalForWindow:_window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

#pragma mark THLocationVCProtocol
- (void)locationVC:(THLocationVC *)locationVC didChooseLocation:(THTweetLocation *)location {
    
    self.tweetLocation = locationVC.tweetLocation;
    
    [[NSApplication sharedApplication] endSheet:_locationPanel];
    [_locationPanel orderOut:self];
    
    self.locationVC = nil;
}

- (void)locationVCDidCancel:(THLocationVC *)locationVC {

    [[NSApplication sharedApplication] endSheet:_locationPanel];
    [_locationPanel orderOut:self];

    self.tweetLocation = nil;

    self.locationVC = nil;
}

- (IBAction)chooseMedia:(id)sender {
    self.postMediaURL = nil;
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    
    [panel setCanChooseDirectories:NO];
    [panel setCanChooseFiles:YES];
    [panel setAllowedFileTypes:@[ @"png", @"PNG", @"jpg", @"JPG", @"jpeg", @"JPEG", @"gif", @"GIF"] ];
    
    [panel beginSheetModalForWindow:_window completionHandler:^(NSInteger result) {
        
        if (result != NSFileHandlingPanelOKButton) return;
        
        NSArray *urls = [panel URLs];
        
        NSPredicate *p = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            if([evaluatedObject isKindOfClass:[NSURL class]] == NO) return NO;
            
            NSURL *url = (NSURL *)evaluatedObject;
            
            return [url isFileURL];
        }];
        
        NSArray *fileURLS = [urls filteredArrayUsingPredicate:p];
        
        NSURL *fileURL = [fileURLS lastObject];
        
        BOOL isDir = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath: fileURL.path isDirectory: &isDir] == NO) return;
        
        self.postMediaURL = fileURL;
        NSLog(@"** postMediaURL: %@", fileURL);
    }];
}

- (IBAction)update:(id)sender {
	NSLog(@"-- update");
	
	self.requestStatus = nil;
	self.isConnecting = @YES;
	
    NSManagedObjectContext *mainContext = [(id)[[NSApplication sharedApplication] delegate] managedObjectContext];
    NSManagedObjectContext *privateContext = [[[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType] autorelease];
    privateContext.parentContext = mainContext;
    
    __block THTweet *latestTweet = nil;
    
    [privateContext performBlockAndWait:^{
        latestTweet = [THTweet tweetWithHighestUidInContext:privateContext];
    }];
    
	NSLog(@"-- found lastKnownID: %@", latestTweet.uid);
    
	NSNumber *lastKnownID = latestTweet.uid;
    
	if([lastKnownID unsignedLongLongValue] == 0) {
        lastKnownID = nil;
    }
    
    self.requestStatus = [NSString stringWithFormat:@"fetching timeline since last known ID %@", lastKnownID];
    
    self.isConnecting = @YES;
    
    [_twitter getHomeTimelineSinceID:[lastKnownID description] count:@"100" successBlock:^(id json) {
        self.isConnecting = @NO;
        self.requestStatus = @"";
        [self saveStatusesFromDictionaries:json];
    } errorBlock:^(NSError *error) {
        self.isConnecting = @NO;
        NSLog(@"-- error: %@", [error localizedDescription]);
        self.requestStatus = [error localizedDescription];
    }];
}

- (void)didChangeTweetReadStatusNotification:(NSNotification *)aNotification {
	BOOL hideRead = [[[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:@"values.hideRead"] boolValue];
	if(!hideRead) return;
    
	THTweet *tweet = [[aNotification userInfo] objectForKey:@"Tweet"];
	NSUInteger tweetScore = [tweet.score unsignedIntegerValue];
    
	numberOfTweetsForScore[tweetScore] += [tweet.isRead boolValue] ? -1 : +1;
	if([[tweet isRead] boolValue]) tweetsCount -= 1;
	
	[self recomputeCumulatedTweetsForScore];
	
	NSNumber *currentScore = [[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:@"values.score"];
	
	[_cumulativeChartView setScore:[currentScore unsignedIntegerValue]];
	[_cumulativeChartView setNeedsDisplay:YES];
    
	//[_tweetArrayController rearrangeObjects];
}

- (void)synchronizeFavorites {
    
	self.requestStatus = @"Syncronizing Favorites";
	self.isConnecting = @YES;
    
    self.requestStatus = @"";
    
    [_twitter getFavoritesListWithSuccessBlock:^(NSArray *statuses) {
        self.isConnecting = @NO;
        [self saveFavoritesFromDictionaries:statuses];
    } errorBlock:^(NSError *error) {
        NSLog(@"-- error: %@", [error localizedDescription]);
        self.isConnecting = @NO;
        self.requestStatus = [error localizedDescription];
    }];
    
    //	[requestsIDs addObject:s];
    //	[favoritesRequestsIDs addObject:s];
}

- (IBAction)synchronizeFavorites:(id)sender {
    //	NSString *username = [[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:@"values.username"];
	[self synchronizeFavorites];
}

- (void)awakeFromNib {
	NSLog(@"-- awakeFromNib");
    
	NSNumber *currentScore = [[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:@"values.score"];
	[_cumulativeChartView setScore:[currentScore integerValue]];
	
	[self updateTweetFilterPredicate];
    //[_tweetArrayController rearrangeObjects];

	//[self updateTweetScores:self];
    
	[_collectionView setMaxNumberOfColumns:1];
	
    self.twitter = [STTwitterAPIWrapper twitterAPIWithOAuthOSX];
    
    //    self.twitter = [STTwitterAPIWrapper twitterAPIWithOAuthConsumerKey:@"" consumerSecret:@"" username:@"" password:@""];
    
    self.requestStatus = @"requesting access";
    
    [_twitter verifyCredentialsWithSuccessBlock:^(NSString *username) {
        NSLog(@"-- access granted for %@", username);
        
        self.requestStatus = [NSString stringWithFormat:@"access granted for %@", username];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeTweetReadStatusNotification:) name:@"DidChangeTweetReadStateNotification" object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setFavoriteFlagForTweet:) name:@"SetFavoriteFlagForTweet" object:nil];
        
        [self update:self];
        
        [self updateCumulatedData];

        //[_tweetArrayController rearrangeObjects];
        //        NSString *username = [_oauth username];
        
        [self synchronizeFavorites];
        
        [self resetTimer];
    } errorBlock:^(NSError *error) {
        NSLog(@"-- %@", [error localizedDescription]);
        self.requestStatus = [error localizedDescription];
    }];
}

- (void)setFavoriteFlagForTweet:(NSNotification *)aNotification {
	THTweet *tweet = [aNotification object];
	BOOL value = [[[aNotification userInfo] valueForKey:@"value"] boolValue];
	
	NSLog(@"-- %d %@", value, tweet);
    
    self.requestStatus = @"Setting favorite...";
    self.isConnecting = @YES;
    
    [_twitter postFavoriteState:(BOOL)value forStatusID:[tweet.uid description] successBlock:^(NSString *jsonString) {
        self.isConnecting = @NO;
        NSLog(@"-- success : %@", jsonString);
        
        BOOL updatedFavoriteValue = [[jsonString valueForKey:@"favorited"] boolValue];
        
        self.requestStatus = [NSString stringWithFormat:@"Did set favorite to %d", updatedFavoriteValue];
        tweet.isFavorite = @(updatedFavoriteValue);
    } errorBlock:^(NSError *error) {
        self.isConnecting = @NO;
        NSLog(@"-- error: %@", [error localizedDescription]);
        self.requestStatus = [error localizedDescription];
    }];
}

- (IBAction)markAllAsRead:(id)sender {
	[[_tweetArrayController arrangedObjects] setValue:@YES forKey:@"isRead"];
	//[_tweetArrayController rearrangeObjects];
}

- (IBAction)markAllAsUnread:(id)sender {
	[[_tweetArrayController arrangedObjects] setValue:@NO forKey:@"isRead"];
	//[_tweetArrayController rearrangeObjects];
}

- (IBAction)openPreferences:(id)sender {
    
    [[THPreferencesWC sharedPreferencesWC] showWindow:nil];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];

    [_preferencesWC release];
    
    [_tweetArrayController release];
    [_userArrayController release];
    [_keywordArrayController release];    
    [_latestTimeUpdateCulumatedDataWasAsked release];
    [_window release];
	[_twitter release];
    [_postMediaURL release];
    
    [_collectionView release];
	[_cumulativeChartView release];
	[_expectedNbTweetsLabel release];
	[_expectedScoreLabel release];
    
    [_tweetSortDescriptors release];
    [_tweetFilterPredicate release];
    [_tweetText release];
    [_isConnecting release];
    [_requestStatus release];
    [_timer release];
    
    [_locationPanel release];
    [_tweetLocation release];
    
	[super dealloc];
}

- (void)saveStatusesFromDictionaries:(NSArray *)statuses {
	NSLog(@"-- statusesReceived: %ld", [statuses count]);
	
	if([statuses count] == 0) return;
	
    //	BOOL isFavoritesRequest = NO; // TODO: sometimes YES
    //
    //	if(isFavoritesRequest) {
    //		// statuses are assumed to be ordered by DESC id
    //		NSArray *statusesIds = [statuses valueForKeyPath:@"id"];
    //		NSString *minIdString = [statusesIds lastObject];
    //		NSString *maxIdString = [statusesIds objectAtIndex:0];
    //
    //		NSNumber *unfavorMinId = [NSNumber numberWithUnsignedLongLong:[minIdString unsignedLongLongValue]];
    //		NSNumber *unfavorMaxId = [NSNumber numberWithUnsignedLongLong:[maxIdString unsignedLongLongValue]];
    //
    //		[THTweet unfavorFavoritesBetweenMinId:unfavorMinId maxId:unfavorMaxId];
    //	}

    NSArray *tweets = [THTweet saveTweetsFromDictionariesArray:statuses];
    //NSNumber *lowestId = [boundingIds valueForKey:@"lowestId"];

    /**/
    
    NSManagedObjectContext *mainContext = [(id)[[NSApplication sharedApplication] delegate] managedObjectContext];
    NSManagedObjectContext *privateContext = [[[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType] autorelease];
    privateContext.parentContext = mainContext;
    
    NSLog(@"-- mainContext   : %@ type %lu", privateContext.parentContext, privateContext.parentContext.concurrencyType);
    NSLog(@"-- privateContext: %@ type %lu", privateContext, privateContext.concurrencyType);

    [privateContext performBlockAndWait:^{
        [self updateScoresForTweets:tweets context:privateContext];
    }];
    
	[self updateTweetFilterPredicate];

	[self updateCumulatedData];

	//[_tweetArrayController rearrangeObjects];
}

- (void)saveFavoritesFromDictionaries:(NSArray *)statuses {
	NSLog(@"-- favoritesReceived: %ld", [statuses count]);

	if([statuses count] == 0) return;

    NSManagedObjectContext *mainContext = [(id)[[NSApplication sharedApplication] delegate] managedObjectContext];
    NSManagedObjectContext *privateContext = [[[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType] autorelease];
    privateContext.parentContext = mainContext;

    // statuses are assumed to be ordered by DESC id
    NSArray *statusesIds = [statuses valueForKeyPath:@"id"];
    NSString *minIdString = [statusesIds lastObject];
//    NSString *maxIdString = [statusesIds objectAtIndex:0];

    NSNumber *unfavorMinId = [NSNumber numberWithUnsignedLongLong:[minIdString unsignedLongLongValue]];
//    NSNumber *unfavorMaxId = [NSNumber numberWithUnsignedLongLong:[maxIdString unsignedLongLongValue]];

    NSArray *favoritesBoundsTweets = [THTweet tweetsWithIdGreaterOrEqualTo:unfavorMinId context:privateContext];
    
    for(THTweet *t in favoritesBoundsTweets) {
        t.isFavorite = @NO;
    }
    
    NSError *error = nil;
    BOOL success = [privateContext save:&error];
    if(success == NO) {
        NSLog(@"-- save error: %@", [error localizedDescription]);
    }
    
    NSArray *tweets = [THTweet saveTweetsFromDictionariesArray:statuses];
    
    [self updateScoresForTweets:tweets context:privateContext];
    
    [self updateTweetFilterPredicate];
    
	[self updateCumulatedData];
    
	//[_tweetArrayController rearrangeObjects];
}

- (void)retweetTweet:(THTweet *)tweet {
    
    self.requestStatus = @"Posting retweet...";
    
    [_twitter postStatusRetweetWithID:[tweet.uid description] successBlock:^(NSString *response) {
        self.requestStatus = @"Retweet OK";
    } errorBlock:^(NSError *error) {
        self.requestStatus = [error localizedDescription];
    }];
}

- (void)replyToTweet:(THTweet *)tweet {
    
    if(_tweetText == nil) return;
    
	self.requestStatus = @"Posting reply...";
    
    THTweet *selectedTweet = [[_tweetArrayController selectedObjects] lastObject];
    
    [_twitter postStatusUpdate:_tweetText inReplyToStatusID:[selectedTweet.uid description] placeID:_tweetLocation.placeID lat:_tweetLocation.latitude lon:_tweetLocation.longitude successBlock:^(NSString *response) {
        self.tweetText = nil;
        self.requestStatus = @"OK, reply was posted.";
    } errorBlock:^(NSError *error) {
        self.requestStatus = [error localizedDescription];
    }];
}

- (void)remoteDeleteTweet:(THTweet *)tweet {
    
    self.requestStatus = @"Posting remote delete...";
    
    [_twitter postDestroyStatusWithID:[tweet.uid description] successBlock:^(NSString *response) {
        self.requestStatus = @"Delete OK";
        [tweet deleteObject];
        //[_tweetArrayController rearrangeObjects];
    } errorBlock:^(NSError *error) {
        self.requestStatus = [error localizedDescription];
    }];
}

#pragma mark CumulativeChartViewDelegate

- (void)chartView:(THCumulativeChartView *)aChartView didSlideToScore:(NSUInteger)aScore {
	//NSLog(@"-- didSlideToScore:%d", aScore);
	
	[_expectedNbTweetsLabel setStringValue:[NSString stringWithFormat:@"%ld", cumulatedTweetsForScore[aScore]]];
	[_expectedScoreLabel setStringValue:[NSString stringWithFormat:@"%ld", aScore]];
}

- (void)chartView:(THCumulativeChartView *)aChartView didStopSlidingOnScore:(NSUInteger)aScore {
	//NSLog(@"-- didStopSlidingOnScore:%d", aScore);
	
	[_expectedNbTweetsLabel setStringValue:[NSString stringWithFormat:@"%ld", cumulatedTweetsForScore[aScore]]];
	[_expectedScoreLabel setStringValue:[NSString stringWithFormat:@"%ld", aScore]];
    
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

//#pragma mark TWLocationPickerProtocol
//- (void)locationPicker:(THLocationPickerWindowController *)locationPicker didChooseLocation:(THTweetLocation *)modifiedTweetLocation {
//    self.tweetLocation = modifiedTweetLocation;
//    [_locationPickerWindowController close];
//}
//
//- (void)locationPickerDidCancel:(THLocationPickerWindowController *)locationPicker {
//    [_locationPickerWindowController close];
//}

@end
