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

@implementation THController

@synthesize tweetSortDescriptors;
@synthesize tweetFilterPredicate;
@synthesize tweetText;
@synthesize requestsIDs;
@synthesize isConnecting;
@synthesize requestStatus;

- (IBAction)updateTweetScores:(id)sender {
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
		//NSLog(@"-- %@ %d", rule.keyword, [tweetsContainingKeyword count]);
		for(Tweet *t in tweetsContainingKeyword) {
			//NSLog(@"-- %@ %@ %@", t.user.name, t.score, rule.score);
			NSInteger score = [t.score intValue];
			score += [rule.score intValue];
			if(score < 0) score = 0;
			if(score > 100) score = 100;
			t.score = [NSNumber numberWithInt:score];
		}
	}
	
	NSError *error = nil;
	[[[[NSApplication sharedApplication] delegate] managedObjectContext] save:&error];
	if(error) {
		NSLog(@"-- error:%@", error);
	};
}

- (void)updateTweetFilterPredicate {
	NSNumber *score = [[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:@"values.score"];
	NSPredicate *p1 = [NSPredicate predicateWithFormat:@"score >= %@" argumentArray:[NSArray arrayWithObject:score]];
	NSMutableArray *subPredicates = [NSMutableArray arrayWithObject:p1];

	NSNumber *showRead = [[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:@"values.showRead"];
	if(![showRead boolValue]) {
		NSPredicate *p2 = [NSPredicate predicateWithFormat:@"isRead == NO"];
		[subPredicates addObject:p2];
	}
	
	NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:subPredicates];		
	NSLog(@"-- predicate: %@", predicate);
	self.tweetFilterPredicate = predicate;
	
	[tweetArrayController rearrangeObjects];
}

- (id)init {
	self = [super init];
	NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
	self.tweetSortDescriptors = [NSArray arrayWithObject:sd];
	[sd release];

	NSString *defaultsPath = [[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"];
	NSDictionary *defaults = [NSDictionary dictionaryWithContentsOfFile:defaultsPath];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
	
	self.requestsIDs = [NSMutableSet set];
	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.score" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:NULL];
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.showRead" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:NULL];

	return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	//NSLog(@"-- keyPath %@", keyPath);
	
	if(object == [NSUserDefaultsController sharedUserDefaultsController] &&
	   [[NSArray arrayWithObjects:@"values.score", @"values.showRead", nil] containsObject:keyPath]) {
		[self updateTweetFilterPredicate];
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
		NSLog(@"--1 %@", requestID);
		[requestsIDs addObject:requestID];
	}
	self.tweetText = nil;
}

- (IBAction)update:(id)sender {
	NSString *username = [[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:@"values.username"];
	//NSString *password = [[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:@"values.password"];
	
	self.requestStatus = nil;
	self.isConnecting = [NSNumber numberWithBool:YES];
	NSString *requestID = [twitterEngine getFollowedTimelineFor:username since:[NSDate distantPast] startingAtPage:0];
	NSLog(@"--2 %@", requestID);
	[requestsIDs addObject:requestID];
}

- (void)awakeFromNib {
	NSLog(@"awakeFromNib");
	
	[self updateTweetScores:self];

	[self updateTweetFilterPredicate];
	
	[collectionView setMaxNumberOfColumns:1];
	
	twitterEngine = [[MGTwitterEngine alloc] initWithDelegate:self];

	NSString *username = [[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:@"values.username"];
	NSString *password = [[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:@"values.password"];
	
	if([username length] == 0 || [password length] == 0) {
        NSLog(@"You forgot to specify your username/password!");
		[preferences makeKeyAndOrderFront:self];
		return;
	}
	
    [twitterEngine setUsername:username password:password];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTweetFilterPredicate) name:@"ReloadTweetsFilter" object:nil];
	
	[self update:self];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[twitterEngine release];

	[tweetSortDescriptors release];
	[tweetFilterPredicate release];
	[tweetText release];
	[requestsIDs release];
	[isConnecting release];
	[requestStatus release];
	
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
	//NSLog(@"statusesReceived:%@ forRequest:%@", statuses, identifier);

	self.requestStatus = nil;
	[requestsIDs removeObject:identifier];
	self.isConnecting = [NSNumber numberWithBool:[requestsIDs count] != 0];

	[Tweet saveTwittsFromDictionariesArray:statuses];
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


@end
