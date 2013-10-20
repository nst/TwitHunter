//
//  User.h
//  TwitHunter
//
//  Created by Nicolas Seriot on 19.04.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <AppKit/AppKit.h>

@class THTweet;

@interface THUser :  NSManagedObject  
{
}

@property (nonatomic, strong) NSNumber * uid;
@property (nonatomic, strong) NSNumber * score;
@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSString * screenName;
@property (nonatomic, strong) NSString * imageURL;
@property (nonatomic, strong) NSNumber * friendsCount;
@property (nonatomic, strong) NSNumber * followersCount;
@property (nonatomic, strong) NSSet* tweets;

+ (THUser *)getOrCreateUserWithDictionary:(NSDictionary *)d context:(NSManagedObjectContext *)context;
+ (THUser *)userWithName:(NSString *)aName context:(NSManagedObjectContext *)context;
- (NSImage *)image;

@end


//@interface User (CoreDataGeneratedAccessors)
//- (void)addTweetsObject:(Tweet *)value;
//- (void)removeTweetsObject:(Tweet *)value;
//- (void)addTweets:(NSSet *)value;
//- (void)removeTweets:(NSSet *)value;
//
//@end

