//
//  Tweet.m
//  TwitHunter
//
//  Created by Nicolas Seriot on 19.04.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import "NSManagedObject+ST.h"
#import "NSString+TH.h"
#import "THTweet.h"
#import "THUser.h"

@implementation THTweet

@dynamic text;
@dynamic uid;
@dynamic score;
@dynamic date;
@dynamic user;
@dynamic isRead;
@dynamic isFavorite;
//@dynamic containsURL;

static NSDateFormatter *createdAtDateFormatter = nil;

- (NSDateFormatter *)createdAtDateFormatter {
    
    if (createdAtDateFormatter == nil) {
        createdAtDateFormatter = [[NSDateFormatter alloc] init];
        
        NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        [createdAtDateFormatter setLocale:usLocale];
        [usLocale release];
        [createdAtDateFormatter setDateStyle:NSDateFormatterLongStyle];
        [createdAtDateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
        [createdAtDateFormatter setDateFormat: @"EEE MMM dd HH:mm:ss Z yyyy"];
    }
    
    return createdAtDateFormatter;
}

//- (NSAttributedString *)attributedString {
//
//    if(self.text == nil) return nil;
//
//    NSAttributedString *as = [[NSAttributedString alloc] initWithString:self.text];
//
//    return [as autorelease];
//}

- (NSNumber *)isFavoriteWrapper {
	return self.isFavorite;
}

- (void)setIsFavoriteWrapper:(NSNumber *)n {
	BOOL flag = [n boolValue];
	NSLog(@"-- set %d", flag);
	
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:n forKey:@"value"];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"SetFavoriteFlagForTweet" object:self userInfo:userInfo];
	
	self.isFavorite = n;
	BOOL success = [self save];
	if(!success) NSLog(@"-- can't save");
}

+ (NSArray *)tweetsWithAndPredicates:(NSArray *)predicates context:(NSManagedObjectContext *)context {
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[THTweet entityInContext:context]];
	
	NSPredicate *p = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
	[request setPredicate:p];
	
	NSError *error = nil;
	
	NSArray *tweets = [context executeFetchRequest:request error:&error];
	
	[request release];
	if(error) {
		NSLog(@"-- error:%@", error);
	}
	return tweets;
}

+ (NSUInteger)tweetsCountWithAndPredicates:(NSArray *)predicates context:(NSManagedObjectContext *)context {
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[THTweet entityInContext:context]];
	
	NSPredicate *p = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
	[request setPredicate:p];
	
	NSError *error = nil;
	
	NSUInteger count = [context countForFetchRequest:request error:&error];
	
	[request release];
	if(error) {
		NSLog(@"-- error:%@", error);
	}
	return count;
}

+ (NSUInteger)nbOfTweetsForScore:(NSNumber *)aScore andPredicates:(NSArray *)predicates context:(NSManagedObjectContext *)context {
	NSPredicate *p = [NSPredicate predicateWithFormat:@"score == %@", aScore];
	NSArray *ps = [predicates arrayByAddingObject:p];
    
	NSUInteger count = [self tweetsCountWithAndPredicates:ps context:context];
    
    NSLog(@"-- score %@ -> %ld", aScore, count);
    
    return count;
}

+ (NSArray *)tweetsContainingKeyword:(NSString *)keyword context:(NSManagedObjectContext *)context {
    
    NSAssert(keyword != nil, @"keyword should not be nil");
    
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[self entityInContext:context]];
	NSPredicate *p = [NSPredicate predicateWithFormat:@"text contains[c] %@" argumentArray:[NSArray arrayWithObject:keyword]];
	[request setPredicate:p];
	
	NSError *error = nil;
	NSArray *array = [context executeFetchRequest:request error:&error];
	if(error) {
		NSLog(@"-- error:%@", error);
	}
	[request release];
	return array;
}

+ (THTweet *)tweetWithUid:(NSString *)uid context:(NSManagedObjectContext *)context {
    if(uid == nil) return nil;
    
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[self entityInContext:context]];
	NSNumber *uidNumber = [NSNumber numberWithUnsignedLongLong:[uid unsignedLongLongValue]];
    
    //NSLog(@"--> %@", uidNumber);
    
	NSPredicate *p = [NSPredicate predicateWithFormat:@"uid == %@", uidNumber, nil];
	[request setPredicate:p];
	[request setFetchLimit:1];
	
	NSError *error = nil;
    
    NSLog(@"-- fetching tweet with uid: %@", uid);
    
    NSArray *array = [context executeFetchRequest:request error:&error];
	if(array == nil) {
		NSLog(@"-- error:%@", error);
	}
	[request release];
	
	return [array lastObject];
}

+ (THTweet *)tweetWithHighestUidInContext:(NSManagedObjectContext *)context {
    
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:[self entityInContext:context]];
    
    NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:@"uid" ascending:NO];
    [request setSortDescriptors:[NSArray arrayWithObject:sd]];
	[request setFetchLimit:1];
	
	NSError *error = nil;
    
    NSArray *array = [context executeFetchRequest:request error:&error];
	if(array == nil) {
		NSLog(@"-- error:%@", error);
	}
    
    return [array lastObject];
}

+ (NSArray *)tweetsWithIdGreaterOrEqualTo:(NSNumber *)anId context:(NSManagedObjectContext *)context {
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[self entityInContext:context]];
	NSPredicate *p = [NSPredicate predicateWithFormat:@"uid >= %@", anId, nil];
	[request setPredicate:p];
	
	NSError *error = nil;
	NSArray *array = [context executeFetchRequest:request error:&error];
	if(error) {
		NSLog(@"-- error:%@", error);
	}
	[request release];
	
	return [array lastObject];
}

+ (void)unfavorFavoritesBetweenMinId:(NSNumber *)unfavorMinId maxId:(NSNumber *)unfavorMaxId context:(NSManagedObjectContext *)context {
	if([unfavorMinId isGreaterThanOrEqualTo:unfavorMaxId]) {
		NSLog(@"-- can't unfavor ids, given maxId is smaller than minId");
		return;
	}
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[THTweet entityInContext:context]];
	NSPredicate *p = [NSPredicate predicateWithFormat:@"isFavorite == YES AND uid <= %@ AND uid >= %@", unfavorMaxId, unfavorMinId, nil];
	[request setPredicate:p];
	
	NSError *error = nil;
	NSArray *array = [context executeFetchRequest:request error:&error];
	if(error) {
		NSLog(@"-- error:%@", error);
	}
	[request release];
	
	for(THTweet *t in array) {
		t.isFavorite = [NSNumber numberWithBool:NO];
		NSLog(@"** unfavor %@", t.user.screenName);
	}
}

+ (BOOL)updateOrCreateTweetFromDictionary:(NSDictionary *)d context:(NSManagedObjectContext *)context {
	// TODO: keep lower and bigger uids and if request was favorites, then un-favorite the ones out of bounds..
	
	NSString *uid = [d objectForKey:@"id"];
	
	BOOL wasCreated = NO;
	THTweet *tweet = [self tweetWithUid:uid context:context];
	if(!tweet) {
		tweet = [THTweet createInContext:context];
		wasCreated = YES;
		tweet.uid = [NSNumber numberWithUnsignedLongLong:[[d objectForKey:@"id"] unsignedLongLongValue]];
        
		NSDictionary *userDictionary = [d objectForKey:@"user"];
		THUser *user = [THUser getOrCreateUserWithDictionary:userDictionary context:context];
		
		NSMutableString *s = [NSMutableString stringWithString:[d objectForKey:@"text"]];
		[s replaceOccurrencesOfString:@"&lt;" withString:@"<" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
		[s replaceOccurrencesOfString:@"&gt;" withString:@">" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [s length])];
		tweet.text = s;
		
        // if needed, use entities.urls to detect URLs
        /*
         "entities":
         {
         "hashtags":[],
         "urls":[],
         "user_mentions":[]
         }
         */
        //		BOOL doesContainURL = [tweet.text rangeOfString:@"http"].location != NSNotFound;
        //		tweet.containsURL = [NSNumber numberWithBool:doesContainURL];
        
		tweet.date = [[tweet createdAtDateFormatter] dateFromString:[d objectForKey:@"created_at"]];
		tweet.user = user;
	}
	tweet.isFavorite = [d objectForKey:@"favorited"];
    
	NSLog(@"** created %d favorite %@ %@ %@ %@", wasCreated, tweet.isFavorite, tweet.uid, tweet.user.screenName, tweet.text);
	
	return YES;
}

+ (NSDictionary *)saveTweetsFromDictionariesArray:(NSArray *)a {
	// TODO: remove non-favorites between new favorites bounds
    
    NSManagedObjectContext *privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    privateContext.parentContext = [(id)[[NSApplication sharedApplication] delegate] managedObjectContext];
    
	__block unsigned long long lowestID = -1;
	__block unsigned long long highestID = 0;
	
    __block BOOL success = NO;
    __block NSError *error = nil;
    
	[privateContext performBlockAndWait:^{
        for(NSDictionary *d in a) {
            [THTweet updateOrCreateTweetFromDictionary:d context:privateContext];
            
            unsigned long long currentID = [[d objectForKey:@"id"] unsignedLongLongValue];
            highestID = MAX(highestID, currentID);
            lowestID = MIN(lowestID, currentID);
        }
        
        success = [privateContext save:&error];
    }];
    
    if(success == NO) {
        NSLog(@"-- save error: %@", [error localizedDescription]);
        return nil;
    }
    
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithUnsignedLongLong:lowestID], @"lowestID",
			[NSNumber numberWithUnsignedLongLong:highestID], @"higestId", nil];
}

- (NSAttributedString *)attributedString {
    NSString *statusString = self.text;
    
//    NSString *statusString = @"http://apple.com sdf @flyosity asd #hashtag dfg";
	
	NSMutableAttributedString *attributedStatusString = [[NSMutableAttributedString alloc] initWithString:statusString];
    
    
    
    
    
	// Defining our paragraph style for the tweet text. Starting with the shadow to make the text
	// appear inset against the gray background.
	NSShadow *textShadow = [[NSShadow alloc] init];
	[textShadow setShadowColor:[NSColor colorWithDeviceWhite:1 alpha:.8]];
	[textShadow setShadowBlurRadius:0];
	[textShadow setShadowOffset:NSMakeSize(0, -1)];
    
	NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[paragraphStyle setMinimumLineHeight:22];
	[paragraphStyle setMaximumLineHeight:22];
	[paragraphStyle setParagraphSpacing:0];
	[paragraphStyle setParagraphSpacingBefore:0];
	[paragraphStyle setTighteningFactorForTruncation:4];
	[paragraphStyle setAlignment:NSNaturalTextAlignment];
	[paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
	
	// Our initial set of attributes that are applied to the full string length
	NSDictionary *fullAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSColor colorWithDeviceHue:.53 saturation:.13 brightness:.26 alpha:1], NSForegroundColorAttributeName,
									textShadow, NSShadowAttributeName,
									[NSCursor arrowCursor], NSCursorAttributeName,
									[NSNumber numberWithFloat:0.0], NSKernAttributeName,
									[NSNumber numberWithInt:0], NSLigatureAttributeName,
									paragraphStyle, NSParagraphStyleAttributeName,
									[NSFont systemFontOfSize:11.0], NSFontAttributeName, nil];
	[attributedStatusString addAttributes:fullAttributes range:NSMakeRange(0, [statusString length])];
	[textShadow release];
	[paragraphStyle release];
    
	// Generate arrays of our interesting items. Links, usernames, hashtags.
	NSArray *linkMatches = [self scanStringForLinks:statusString];
	NSArray *usernameMatches = [self scanStringForUsernames:statusString];
	NSArray *hashtagMatches = [self scanStringForHashtags:statusString];
	
	// Iterate across the string matches from our regular expressions, find the range
	// of each match, add new attributes to that range
	for (NSTextCheckingResult *linkMatch in linkMatches) {
		NSRange range = [linkMatch range];
        NSString *s = [statusString substringWithRange:range];
		if( range.location != NSNotFound ) {
			// Add custom attribute of LinkMatch to indicate where our URLs are found. Could be blue
			// or any other color.
			NSDictionary *linkAttr = [[NSDictionary alloc] initWithObjectsAndKeys:
									  [NSCursor pointingHandCursor], NSCursorAttributeName,
									  [NSColor blueColor], NSForegroundColorAttributeName,
									  [NSFont boldSystemFontOfSize:14.0], NSFontAttributeName,
									  s, @"LinkMatch",
									  nil];
			[attributedStatusString addAttributes:linkAttr range:range];
			[linkAttr release];
		}
	}
	
	for (NSTextCheckingResult *usernameMatch in usernameMatches) {
		NSRange range = [usernameMatch range];
        NSString *s = [statusString substringWithRange:range];
		if( range.location != NSNotFound ) {
			// Add custom attribute of UsernameMatch to indicate where our usernames are found
			NSDictionary *linkAttr2 = [[NSDictionary alloc] initWithObjectsAndKeys:
									   [NSColor blackColor], NSForegroundColorAttributeName,
									   [NSCursor pointingHandCursor], NSCursorAttributeName,
									   [NSFont boldSystemFontOfSize:14.0], NSFontAttributeName,
									   s, @"UsernameMatch",
									   nil];
			[attributedStatusString addAttributes:linkAttr2 range:range];
			[linkAttr2 release];
		}
	}
	
	for (NSTextCheckingResult *hashtagMatch in hashtagMatches) {
		NSRange range = [hashtagMatch range];
        NSString *s = [statusString substringWithRange:range];
		if( range.location != NSNotFound ) {
			// Add custom attribute of HashtagMatch to indicate where our hashtags are found
			NSDictionary *linkAttr3 = [[NSDictionary alloc] initWithObjectsAndKeys:
                                       [NSColor grayColor], NSForegroundColorAttributeName,
                                       [NSCursor pointingHandCursor], NSCursorAttributeName,
                                       [NSFont systemFontOfSize:14.0], NSFontAttributeName,
                                       s, @"HashtagMatch",
                                       nil];
			[attributedStatusString addAttributes:linkAttr3 range:range];
			[linkAttr3 release];
		}
	}
	
    return [attributedStatusString autorelease];
    
    
    
    
    
    
    
    
    
//	[_tweetTextTextView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
//	[_tweetTextTextView setBackgroundColor:[NSColor clearColor]];
//	[_tweetTextTextView setTextContainerInset:NSZeroSize];
//	[[_tweetTextTextView textStorage] setAttributedString:attributedStatusString];
//	[_tweetTextTextView setEditable:NO];
//	[_tweetTextTextView setSelectable:YES];
//    
//    [attributedStatusString release];
}

#pragma mark -
#pragma mark String parsing

// These regular expressions aren't the greatest. There are much better ones out there to parse URLs, @usernames
// and hashtags out of tweets. Getting the escaping just right is a pain in the ass, so be forewarned.

- (NSArray *)scanStringForLinks:(NSString *)string {
    //return @[@"YouTube"];
	return [string componentsMatchedByRegex:@"\\b(([\\w-]+://?|www[.])[^\\s()<>]+(?:\\([\\w\\d]+\\)|([^[:punct:]\\s]|/)))"];
}

- (NSArray *)scanStringForUsernames:(NSString *)string {
	return [string componentsMatchedByRegex:@"@{1}([-A-Za-z0-9_]{2,})"];
}

- (NSArray *)scanStringForHashtags:(NSString *)string {
	return [string componentsMatchedByRegex:@"[\\s]{1,}#{1}([^\\s]{2,})"];
}

@end


