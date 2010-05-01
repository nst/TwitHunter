//
//  MGTwitterEngine+TH.m
//  TwitHunter
//
//  Created by Nicolas Seriot on 5/1/10.
//  Copyright 2010 seriot.ch. All rights reserved.
//

#import "MGTwitterEngine+TH.h"


@implementation MGTwitterEngine (TH)

- (NSArray *)getHomeTimeline:(NSUInteger)nbTweets {
	NSUInteger count = 20;
	
	NSUInteger pages = (nbTweets % count) ? (nbTweets / count) : (nbTweets / count) + 1;
	
	NSMutableArray *a = [NSMutableArray array];
	for(NSUInteger i = 0; i <= pages; i++) {
		NSString *requestID = [self getHomeTimelineSinceID:0 startingAtPage:i count:count];
		[a addObject:requestID];
	}
	return a;
}

@end
