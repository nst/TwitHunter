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
#import "STTwitter.h"
#import "THTweetLocation.h"
#import "THLocationVC.h"
#import "THCumulativeChartView.h"

// TODO: https://developer.apple.com/library/mac/#qa/qa2006/qa1487.html
// TODO: https://github.com/blladnar/AutoLink
// TODO: http://www.nightproductions.net/developer.htm

// $ rm ~/Library/Application\ Support/TwitHunter/TwitHunter.sqlite3
// $ rm ~/Library/Preferences/ch.seriot.TwitHunter.plist

@interface THController ()
@property (nonatomic, strong) THTweetLocation *tweetLocation;
@property (nonatomic, strong) THLocationVC *locationVC;
@property (nonatomic, strong) STTwitterAPI *twitter;
@property (nonatomic, strong) NSDate *latestTimeUpdateCulumatedDataWasAsked;
@property (nonatomic, strong) NSArray *tweetSortDescriptors;
@property (nonatomic, strong) NSPredicate *tweetFilterPredicate;
@property (nonatomic, strong) NSString *tweetText;
@property (nonatomic, strong) NSNumber *isConnecting;
@property (nonatomic, strong) NSString *requestStatus;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSURL *postMediaURL;
@end

@implementation THController

@synthesize twitter = _twitter;
@synthesize window = _window;
@synthesize cumulativeChartView = _cumulativeChartView;
@synthesize latestTimeUpdateCulumatedDataWasAsked = _latestTimeUpdateCulumatedDataWasAsked;
@synthesize timer = _timer;
@synthesize tweetText = _tweetText;
@synthesize postMediaURL = _postMediaURL;
@synthesize tweetLocation = _tweetLocation;
@synthesize locationPanel = _locationPanel;
@synthesize collectionView = _collectionView;
@synthesize locationVC = _locationVC;
@synthesize tweetArrayController = _tweetArrayController;
@synthesize preferencesWC = _preferencesWC;
@synthesize keywordArrayController = _keywordArrayController;
@synthesize expectedNbTweetsLabel = _expectedNbTweetsLabel;
@synthesize userArrayController = _userArrayController;
@synthesize expectedScoreLabel = _expectedScoreLabel;
@synthesize tweetSortDescriptors = _tweetSortDescriptors;
@synthesize tweetFilterPredicate = _tweetFilterPredicate;
@synthesize isConnecting = _isConnecting;
@synthesize requestStatus = _requestStatus;

- (void)setTwitter:(STTwitterAPI *)twitter {
    _twitter = twitter;
    
    NSString *title = [NSString stringWithFormat:@"TwitHunter"];
    
    NSString *username = [[NSUserDefaults standardUserDefaults] valueForKey:@"userName"];
    NSString *consumerName = [[NSUserDefaults standardUserDefaults] valueForKey:@"clientName"];
    
    if(username) {
        title = [title stringByAppendingFormat:@" - @%@", username];
    }
    
    if(consumerName) {
        title = [title stringByAppendingFormat:@" (%@)", consumerName];
    }
    
    [_window setTitle:title];
}

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
    
	self.latestTimeUpdateCulumatedDataWasAsked = [NSDate date];
    
    NSDate *startDate = [_latestTimeUpdateCulumatedDataWasAsked copy];
    
    NSArray *predicates = [self predicatesWithoutScore];
    
    NSManagedObjectContext *mainContext = [(id)[[NSApplication sharedApplication] delegate] managedObjectContext];
    NSManagedObjectContext *privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
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

    NSLog(@"-- updateCumulatedData -> _cumulativeChartView %@", _cumulativeChartView);
    
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
    NSManagedObjectContext *privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    privateContext.parentContext = mainContext;
    
    __block NSArray *allTweets = nil;
    
    [privateContext performBlockAndWait:^{
        NSFetchRequest *fr = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [THTweet entityInContext:privateContext];
        [fr setEntity:entity];
        allTweets = [privateContext executeFetchRequest:fr error:nil];
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
		NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"uid" ascending:NO];
		self.tweetSortDescriptors = @[sd];
        
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
        
        [_twitter postStatusUpdate:_tweetText inReplyToStatusID:nil mediaURL:_postMediaURL placeID:_tweetLocation.placeID latitude:_tweetLocation.latitude longitude:_tweetLocation.longitude successBlock:^(NSDictionary *status) {
            self.tweetText = @"";
            self.requestStatus = @"OK, status was posted.";
            self.postMediaURL = nil;
        } errorBlock:^(NSError *error) {
            self.requestStatus = error ? [error localizedDescription] : @"Unknown error";
        }];

    } else {
        
        [_twitter postStatusUpdate:_tweetText inReplyToStatusID:nil latitude:_tweetLocation.latitude longitude:_tweetLocation.longitude placeID:_tweetLocation.placeID displayCoordinates:nil trimUser:nil successBlock:^(NSDictionary *status) {
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
    
    NSTextField *latitudeTextField = [[NSTextField alloc] initWithFrame:NSMakeRect(0,32, 180, 24)];
    NSTextField *longitudeTextField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 180, 24)];
    
    NSView *accessoryView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 200, 64)];
    [accessoryView addSubview:latitudeTextField];
    [accessoryView addSubview:longitudeTextField];
    
    
    //    self.locationVC = [[[THLocationVC alloc] initWithNibName:@"THLocationVC" bundle:[NSBundle mainBundle]] autorelease];
    
    if(_tweetLocation == nil) {
        self.tweetLocation = [[THTweetLocation alloc] init];
    }
    
#pragma mark TODO:
    // NSWindow setContentView:
    
    self.locationVC = [[THLocationVC alloc] initWithNibName:@"THLocationVC" bundle:nil];
    _locationVC.twitter = _twitter;
    _locationVC.tweetLocation = [_tweetLocation copy];
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
    NSManagedObjectContext *privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
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
    
	self.requestStatus = @"Syncronizing favorites...";
	self.isConnecting = @YES;
        
    [_twitter getFavoritesListWithSuccessBlock:^(NSArray *statuses) {
        self.isConnecting = @NO;
        [self saveFavoritesFromDictionaries:statuses];
        self.requestStatus = @"Favorites are synchronized.";
    } errorBlock:^(NSError *error) {
        NSLog(@"-- error: %@", [error localizedDescription]);
        self.isConnecting = @NO;
        self.requestStatus = [NSString stringWithFormat:@"Error in synchronizing favorites, %@.", [error localizedDescription]];
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

	[_collectionView setMaxNumberOfColumns:1];
    
    self.twitter = [[THPreferencesWC sharedPreferencesWC] twitterWrapper];
    
	[self updateCumulatedData];
    
    [_twitter verifyCredentialsWithSuccessBlock:^(NSString *username) {
        [self update:self];
    } errorBlock:^(NSError *error) {
        NSLog(@"-- %@", [error localizedDescription]);
    }];
    
    
//    [_twitter getUserTimelineWithScreenName:@"dickc" successBlock:^(NSArray *statuses) {        
//        for(NSDictionary *d in statuses) {
//            NSLog(@"-- %@ %@", d[@"uid"], d[@"source"]);
//        }
//        
//    } errorBlock:^(NSError *error) {
//        NSLog(@"-- %@", error);
//    }];
}

- (void)setFavoriteFlagForTweet:(NSNotification *)aNotification {
	THTweet *tweet = [aNotification object];
	BOOL value = [[[aNotification userInfo] valueForKey:@"value"] boolValue];
	
	NSLog(@"-- %d %@", value, tweet);
    
    self.requestStatus = @"Setting favorite...";
    self.isConnecting = @YES;
    
    [_twitter postFavoriteState:(BOOL)value forStatusID:[tweet.uid description] successBlock:^(NSDictionary *status) {
        self.isConnecting = @NO;
        NSLog(@"-- success : %@", status);
        
        BOOL updatedFavoriteValue = [[status valueForKey:@"favorited"] boolValue];
        
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
    
    THPreferencesWC *preferences = [THPreferencesWC sharedPreferencesWC];
    preferences.preferencesDelegate = self;
    [preferences showWindow:nil];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];

    
    
    
    
    
}

- (void)saveStatusesFromDictionaries:(NSArray *)statuses {
	NSLog(@"-- statusesReceived: %ld", [statuses count]);
	
//	if([statuses count] == 0) return;
	
    NSArray *tweets = [THTweet saveTweetsFromDictionariesArray:statuses];
    //NSNumber *lowestId = [boundingIds valueForKey:@"lowestId"];

    /**/
    
    NSManagedObjectContext *mainContext = [(id)[[NSApplication sharedApplication] delegate] managedObjectContext];
    NSManagedObjectContext *privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    privateContext.parentContext = mainContext;
    
    NSLog(@"-- mainContext   : %@ type %lu", privateContext.parentContext, privateContext.parentContext.concurrencyType);
    NSLog(@"-- privateContext: %@ type %lu", privateContext, privateContext.concurrencyType);

    [privateContext performBlockAndWait:^{
        [self updateScoresForTweets:tweets context:privateContext];
    }];

	[self updateTweetFilterPredicate];

	[self updateCumulatedData];
    
//    [_tweetArrayController rearrangeObjects];
}

- (void)saveFavoritesFromDictionaries:(NSArray *)statuses {
	NSLog(@"-- favoritesReceived: %ld", [statuses count]);

	if([statuses count] == 0) return;

    NSManagedObjectContext *mainContext = [(id)[[NSApplication sharedApplication] delegate] managedObjectContext];
    NSManagedObjectContext *privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
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
    
    [_twitter postStatusRetweetWithID:[tweet.uid description] successBlock:^(NSDictionary *status) {
        self.requestStatus = @"Retweet OK";
    } errorBlock:^(NSError *error) {
        self.requestStatus = [error localizedDescription];
    }];
}

- (void)replyToTweet:(THTweet *)tweet {
    
    if(_tweetText == nil) return;
    
	self.requestStatus = @"Posting reply...";
    
    THTweet *selectedTweet = [[_tweetArrayController selectedObjects] lastObject];
    
    [_twitter postStatusUpdate:_tweetText inReplyToStatusID:[selectedTweet.uid description] latitude:_tweetLocation.latitude longitude:_tweetLocation.longitude placeID:_tweetLocation.placeID displayCoordinates:nil trimUser:nil successBlock:^(NSDictionary *status) {
        self.tweetText = nil;
        self.requestStatus = @"OK, reply was posted.";
    } errorBlock:^(NSError *error) {
        self.requestStatus = [error localizedDescription];
    }];
}

- (void)remoteDeleteTweet:(THTweet *)tweet {
    
    self.requestStatus = @"Posting remote delete...";
    
    [_twitter postStatusesDestroy:[tweet.uid description] trimUser:nil successBlock:^(NSDictionary *status) {
        self.requestStatus = @"Delete OK";
        [tweet deleteObject];
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

#pragma mark THPreferencesWCDelegate

- (void)preferences:(THPreferencesWC *)preferences didChooseTwitter:(STTwitterAPI *)twitter {

    NSManagedObjectContext *mainContext = [(id)[[NSApplication sharedApplication] delegate] managedObjectContext];

    NSString *formerUserName = _twitter.userName;
    NSString *newUserName = twitter.userName;
        
    NSLog(@"--> formerUserName: %@", formerUserName);
    NSLog(@"--> newUserName: %@", newUserName);
    
    BOOL cleanupDatabaseForNewUser = newUserName && ([formerUserName isEqualToString:newUserName] == NO);
    
    if(cleanupDatabaseForNewUser) {

        [_tweetArrayController willChangeValueForKey:@"selectionIndexes"];
        _tweetArrayController.selectionIndexes = nil;
        [_tweetArrayController didChangeValueForKey:@"selectionIndexes"];
        
        [_tweetArrayController willChangeValueForKey:@"arrangedObjects"];
        [THTweet deleteAllObjectsInContext:mainContext];
        [_tweetArrayController didChangeValueForKey:@"arrangedObjects"];

        [_userArrayController willChangeValueForKey:@"arrangedObjects"];
        [THUser deleteAllObjectsInContext:mainContext];
        [_userArrayController didChangeValueForKey:@"arrangedObjects"];
        
        NSError *saveError = nil;
        BOOL success = [mainContext save:&saveError];

        if(success == NO) {
            NSLog(@"-- saveError: %@", [saveError localizedDescription]);
        }
    }
    
    self.twitter = twitter;
}

@end
