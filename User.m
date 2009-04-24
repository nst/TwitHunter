// 
//  User.m
//  TwitHunter
//
//  Created by Nicolas Seriot on 19.04.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import "User.h"
#import "NSManagedObject+TH.h"

#import "Tweet.h"

@implementation User 

@dynamic uid;
@dynamic score;
@dynamic name;
@dynamic screenName;
@dynamic imageURL;
@dynamic tweets;
@dynamic friendsCount;
@dynamic followersCount;

+ (User *)userWithName:(NSString *)aName {
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:[self entity]];
	NSPredicate *p = [NSPredicate predicateWithFormat:@"name == %@", aName, nil];
	[request setPredicate:p];
	[request setFetchLimit:1];
	
	NSError *error = nil;
	NSArray *array = [[self moc] executeFetchRequest:request error:&error];
	return [array lastObject];
}

+ (User *)getOrCreateUserWithDictionary:(NSDictionary *)d {
	//NSLog(@"-- %@", d);
	
	User *user = [User userWithName:[d objectForKey:@"name"]];
	
	if(!user) {
		user = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:[self moc]];
		user.uid = [d objectForKey:@"id"];
		user.name = [d objectForKey:@"name"];
	}
	
	user.screenName = [d objectForKey:@"screen_name"];
	user.imageURL = [d objectForKey:@"profile_image_url"];
	user.friendsCount = [NSNumber numberWithInt:[(NSString *)[d objectForKey:@"friends_count"] intValue]];
	user.followersCount = [NSNumber numberWithInt:[(NSString *)[d objectForKey:@"followers_count"] intValue] ];

	return user;
}

- (NSImage *)image {
	return [[[NSImage alloc] initByReferencingURL:[NSURL URLWithString:self.imageURL]] autorelease];
}

@end
