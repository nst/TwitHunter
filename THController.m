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
#import "NSManagedObject+SingleContext.h"
#import "NSString+TH.h"
#import "STTwitterAPIWrapper.h"
#import "THTweetLocation.h"

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
	}
	cumulatedTweetsForScore[0] = tweetsCount;
}

- (void)updateCumulatedData {
	[latestTimeUpdateCulumatedDataWasAsked release];
	latestTimeUpdateCulumatedDataWasAsked = [[NSDate date] retain];
    
    NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
    
    [queue addOperationWithBlock:^{
        
        NSDate *startDate = [[latestTimeUpdateCulumatedDataWasAsked copy] autorelease];
        
        NSArray *predicates = [self predicatesWithoutScore];
        
        NSUInteger totalTweetsCount = [THTweet tweetsCountWithAndPredicates:predicates];
        NSLog(@"-- total number of tweets: %lu", totalTweetsCount);
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self setTweetsCount:totalTweetsCount];
        }];
        
        NSMutableArray *tweetsForScores = [NSMutableArray arrayWithCapacity:101];
        for(NSUInteger i = 0; i < 101; i++) {
            NSUInteger nbTweets = [THTweet nbOfTweetsForScore:[NSNumber numberWithUnsignedInt:i] andPredicates:[self predicatesWithoutScore]];
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
	for(THTweet *t in tweets) {
		NSInteger score = 50 + [t.user.score intValue];
		if(score < 0) score = 0;
		if(score > 100) score = 100;
		t.score = [NSNumber numberWithInt:score];
	}
    
	// text score
	for(THTextRule *rule in [THTextRule allObjects]) {
		NSArray *tweetsContainingKeyword = [THTweet tweetsContainingKeyword:rule.keyword];
		for(THTweet *t in tweetsContainingKeyword) {
			NSInteger score = [t.score intValue];
			score += [rule.score intValue];
			if(score < 0) score = 0;
			if(score > 100) score = 100;
			t.score = [NSNumber numberWithInt:score];
		}
	}
	
	NSError *error = nil;
	[[THTweet moc] save:&error];
	if(error) {
		NSLog(@"-- error:%@", error);
	}
	
	[tweetArrayController rearrangeObjects];
	
	[self updateCumulatedData];
    
	//[cumulativeChartView setNeedsDisplay:YES];
}

- (IBAction)updateTweetScores:(id)sender {
	NSLog(@"-- update scores");
	
	[self updateScoresForTweets:[THTweet allObjects]]; // TODO: optimize..
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

- (IBAction)openLocationPicker:(id)sender {
//    if(_locationPickerWindowController == nil) {
        self.locationPickerWindowController = [[[THLocationPickerWindowController alloc] initWithWindowNibName:@"LocationPicker"] autorelease];
//    }
    
    if(_tweetLocation == nil) {
        self.tweetLocation = [[[THTweetLocation alloc] init] autorelease];
    }
    
    _locationPickerWindowController.tweetLocation = [[_tweetLocation copy] autorelease];
    _locationPickerWindowController.delegate = self;
    [self.locationPickerWindowController showWindow:self];
}

- (IBAction)updateCredentials:(id)sender {
	[preferences close];
	
	[self update:self];
}

- (IBAction)tweet:(id)sender {
    
    if(tweetText == nil) return;
    
	self.requestStatus = @"Posting status...";

    if(_postMediaURL) {
        [_twitter postStatusUpdate:tweetText inReplyToStatusID:nil mediaURL:_postMediaURL lat:_latitude lon:_longitude successBlock:^(NSString *response) {
            self.tweetText = @"";
            self.requestStatus = @"OK, status was posted.";
            self.postMediaURL = nil;
            self.latitude = nil;
            self.longitude = nil;
            self.locationDescription = nil;
        } errorBlock:^(NSError *error) {
            self.requestStatus = error ? [error localizedDescription] : @"Unknown error";
        }];
    } else {
        [_twitter postStatusUpdate:tweetText inReplyToStatusID:nil lat:_latitude lon:_longitude successBlock:^(NSString *response) {
            self.tweetText = @"";
            self.requestStatus = @"OK, status was posted.";
            self.latitude = nil;
            self.longitude = nil;
            self.locationDescription = nil;
        } errorBlock:^(NSError *error) {
            self.requestStatus = [error localizedDescription];
        }];
    }
    
//    NSSharingService *service = [NSSharingService sharingServiceNamed:NSSharingServiceNamePostOnTwitter];
//    service.delegate = self;
//    [service performWithItems:@[tweetText]];
    
}

- (IBAction)chooseLocation:(id)sender {
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setMessageText:@"Please choose latitude and longitude:"];
    //[alert setInformativeText:@"STTwitter will login on Twitter through the website and parse the HTML to guess the PIN."];
    [alert setAlertStyle:NSInformationalAlertStyle];
    
    NSTextField *latitudeTextField = [[[NSTextField alloc] initWithFrame:NSMakeRect(0,32, 180, 24)] autorelease];
    NSTextField *longitudeTextField = [[[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 180, 24)] autorelease];
    
    NSView *accessoryView = [[[NSView alloc] initWithFrame:NSMakeRect(0, 0, 200, 64)] autorelease];
    [accessoryView addSubview:latitudeTextField];
    [accessoryView addSubview:longitudeTextField];
    
    [alert setAccessoryView:accessoryView];
    
    [alert beginSheetModalForWindow:_window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(NSDictionary *)contextInfo {
    if(returnCode != NSAlertFirstButtonReturn) {
        self.latitude = nil;
        self.longitude = nil;
        self.locationDescription = nil;
        return;
    }
    
    NSArray *subviews = [alert.accessoryView subviews];
    
    NSTextField *latitudeTextField = [subviews objectAtIndex:0];
    NSTextField *longitudeTextField = [subviews objectAtIndex:1];
    
    self.latitude = [latitudeTextField stringValue];
    self.longitude = [longitudeTextField stringValue];
  
    [_twitter getReverseGeocodeWithLatitude:_latitude longitude:_longitude successBlock:^(NSArray *places) {
        
        if([places count] == 0) return;
        
        NSArray *firstPlace = [places objectAtIndex:0];
        
        self.locationDescription = [firstPlace valueForKey:@"full_name"];
        
    } errorBlock:^(NSError *error) {
        NSLog(@"-- %@", [error localizedDescription]);
    }];
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
	
    THTweet *latestTweet = [THTweet tweetWithHighestUid];
	NSLog(@"-- found lastKnownID: %@", latestTweet.uid);
    
	NSNumber *lastKnownID = latestTweet.uid;
    
	if([lastKnownID unsignedLongLongValue] == 0) {
        lastKnownID = nil;
    }

    NSLog(@"-- fetch timeline since ID: %@", lastKnownID);
        
    self.requestStatus = @"fetching timeline since last known ID";
    
    self.isConnecting = @YES;
    
    [_twitter getHomeTimelineSinceID:[lastKnownID description] count:@"100" successBlock:^(id json) {
        self.isConnecting = @NO;
        self.requestStatus = @"";
        [self statusesReceived:json];
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
	
	[cumulativeChartView setScore:[currentScore unsignedIntegerValue]];
	[cumulativeChartView setNeedsDisplay:YES];
    
	[tweetArrayController rearrangeObjects];
}

- (void)synchronizeFavorites {
    
//    NSLog(@"-- %@", aUsername);
    
//    return; // FIXME
    
	self.requestStatus = @"Syncronizing Favorites";
	self.isConnecting = @YES;
    
    self.requestStatus = @"";
    
    [_twitter getFavoritesListWithSuccessBlock:^(NSArray *statuses) {
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
//	NSString *username = [[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:@"values.username"];
	[self synchronizeFavorites];
}

- (void)awakeFromNib {
	NSLog(@"-- awakeFromNib");
	
	NSNumber *currentScore = [[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:@"values.score"];
	[cumulativeChartView setScore:[currentScore integerValue]];
	
	[self updateTweetFilterPredicate];
	
	//[self updateTweetScores:self];
    
	[collectionView setMaxNumberOfColumns:1];
	
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

//        NSString *username = [_oauth username];

        [self synchronizeFavorites];
        
        [self resetTimer];
    } errorBlock:^(NSError *error) {
        NSLog(@"-- %@", [error localizedDescription]);
        self.requestStatus = [error localizedDescription];
    }];
    
//    [_oauth requestAccessWithCompletionBlock:^(ACAccount *twitterAccount) {
//        
//        self.requestStatus = [NSString stringWithFormat:@"access granted for %@", twitterAccount];
//        
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeTweetReadStatusNotification:) name:@"DidChangeTweetReadStateNotification" object:nil];
//        
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setFavoriteFlagForTweet:) name:@"SetFavoriteFlagForTweet" object:nil];
//        
//        [self update:self];
//        
//        [self updateCumulatedData];
//        
////        NSString *username = [_oauth username];
//        
//        [self synchronizeFavorites];
//        
//        [self resetTimer];
//        
//    } errorBlock:^(NSError *error) {
//        NSLog(@"-- %@", [error localizedDescription]);
//        self.requestStatus = [error localizedDescription];
//    }];
    
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
	[[tweetArrayController arrangedObjects] setValue:@YES forKey:@"isRead"];
	[tweetArrayController rearrangeObjects];
}

- (IBAction)markAllAsUnread:(id)sender {
	[[tweetArrayController arrangedObjects] setValue:@NO forKey:@"isRead"];
	[tweetArrayController rearrangeObjects];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
    [_window release];
	[_twitter release];
    [_postMediaURL release];
    [_locationDescription release];
    [_latitude release];
    [_longitude release];
    
    [timer release];
    [tweetSortDescriptors release];
	[tweetFilterPredicate release];
	[tweetText release];
	[isConnecting release];
	[requestStatus release];
    
    [_locationPickerWindowController release];
    [_tweetLocation release];
    
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
    
	NSDictionary *boundingIds = [THTweet saveTweetsFromDictionariesArray:statuses];
	
	NSNumber *lowestId = [boundingIds valueForKey:@"lowestId"];
//	NSNumber *higestId = [boundingIds valueForKey:@"higestId"];
	
    //	if(higestId) {
    //		[[NSUserDefaults standardUserDefaults] setObject:higestId forKey:@"highestID"];
    //		NSLog(@"-- stored highestID: %@", higestId);
    //	}
	
	[self updateScoresForTweets:[THTweet tweetsWithIdGreaterOrEqualTo:lowestId]];
	
	[self updateTweetFilterPredicate];
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

    if(tweetText == nil) return;
    
	self.requestStatus = @"Posting reply...";
    
    THTweet *selectedTweet = [[tweetArrayController selectedObjects] lastObject];
    
    [_twitter postStatusUpdate:tweetText inReplyToStatusID:[selectedTweet.uid description] lat:_latitude lon:_longitude successBlock:^(NSString *response) {
        self.tweetText = nil;
        self.requestStatus = @"OK, reply was posted.";
        self.latitude = nil;
        self.longitude = nil;
        self.locationDescription = nil;
    } errorBlock:^(NSError *error) {
        self.requestStatus = [error localizedDescription];
    }];
}

- (void)remoteDeleteTweet:(THTweet *)tweet {

    self.requestStatus = @"Posting remote delete...";

    [_twitter postDestroyStatusWithID:[tweet.uid description] successBlock:^(NSString *response) {
        self.requestStatus = @"Delete OK";
        [tweet deleteObject];
        [tweetArrayController rearrangeObjects];
    } errorBlock:^(NSError *error) {
        self.requestStatus = [error localizedDescription];
    }];

}

#pragma mark CumulativeChartViewDelegate

- (void)chartView:(THCumulativeChartView *)aChartView didSlideToScore:(NSUInteger)aScore {
	//NSLog(@"-- didSlideToScore:%d", aScore);
	
	[expectedNbTweetsLabel setStringValue:[NSString stringWithFormat:@"%ld", cumulatedTweetsForScore[aScore]]];
	[expectedScoreLabel setStringValue:[NSString stringWithFormat:@"%ld", aScore]];
}

- (void)chartView:(THCumulativeChartView *)aChartView didStopSlidingOnScore:(NSUInteger)aScore {
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

#pragma mark TWLocationPickerProtocol
- (void)locationPicker:(THLocationPickerWindowController *)locationPicker didChooseLocation:(THTweetLocation *)modifiedTweetLocation {
    self.tweetLocation = modifiedTweetLocation;
}

@end
