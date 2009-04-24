//
//  User.h
//  TwitHunter
//
//  Created by Nicolas Seriot on 19.04.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Tweet;

@interface User :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * uid;
@property (nonatomic, retain) NSNumber * score;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * screenName;
@property (nonatomic, retain) NSString * imageURL;
@property (nonatomic, retain) NSNumber * friendsCount;
@property (nonatomic, retain) NSNumber * followersCount;
@property (nonatomic, retain) NSSet* tweets;

+ (User *)getOrCreateUserWithDictionary:(NSDictionary *)d;
+ (User *)userWithName:(NSString *)aName;
- (NSImage *)image;

@end


//@interface User (CoreDataGeneratedAccessors)
//- (void)addTweetsObject:(Tweet *)value;
//- (void)removeTweetsObject:(Tweet *)value;
//- (void)addTweets:(NSSet *)value;
//- (void)removeTweets:(NSSet *)value;
//
//@end

