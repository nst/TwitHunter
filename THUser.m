// 
//  User.m
//  TwitHunter
//
//  Created by Nicolas Seriot on 19.04.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import "THUser.h"
#import "NSManagedObject+SingleContext.h"

#import "THTweet.h"

@implementation THUser 

@dynamic uid;
@dynamic score;
@dynamic name;
@dynamic screenName;
@dynamic imageURL;
@dynamic tweets;
@dynamic friendsCount;
@dynamic followersCount;

+ (THUser *)userWithName:(NSString *)aName {
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:[self entity]];
	NSPredicate *p = [NSPredicate predicateWithFormat:@"name == %@", aName, nil];
	[request setPredicate:p];
	[request setFetchLimit:1];
	
	NSError *error = nil;
	NSArray *array = [[self moc] executeFetchRequest:request error:&error];
	return [array lastObject];
}

+ (THUser *)getOrCreateUserWithDictionary:(NSDictionary *)d {
	//NSLog(@"-- %@", d);
	
	THUser *user = [THUser userWithName:[d objectForKey:@"name"]];
	
	if(!user) {
		user = [NSEntityDescription insertNewObjectForEntityForName:@"THUser" inManagedObjectContext:[self moc]];
		user.uid = [NSNumber numberWithInt:[(NSString *)[d objectForKey:@"id"] intValue]];
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
