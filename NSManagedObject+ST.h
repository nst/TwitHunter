//
//  NSManagedObject+iLog.h
//  iLog
//
//  Created by Nicolas Seriot on 22.03.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface NSManagedObject (ST)

+ (NSEntityDescription *)entityInContext:(NSManagedObjectContext *)context;
+ (id)createInContext:(NSManagedObjectContext *)context;

- (BOOL)save;
- (void)deleteObject;

@end
