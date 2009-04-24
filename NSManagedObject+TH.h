//
//  NSManagedObject+iLog.h
//  iLog
//
//  Created by Nicolas Seriot on 22.03.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface NSManagedObject (UniqueContext)

+ (NSManagedObjectContext *)moc;
- (NSManagedObjectContext *)moc;
+ (NSManagedObjectModel *)mom;
+ (NSEntityDescription *)entity;
+ (NSFetchRequest *)allFetchRequest;
+ (NSArray *)allObjects;
+ (NSUInteger)allObjectsCount;

- (BOOL)save;
- (BOOL)deleteObject;

@end
