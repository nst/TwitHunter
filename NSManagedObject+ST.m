//
//  NSManagedObject+iLog.m
//  iLog
//
//  Created by Nicolas Seriot on 22.03.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import "NSManagedObject+ST.h"
#import <AppKit/AppKit.h>

@implementation NSManagedObject (ST)

+ (NSEntityDescription *)entityInContext:(NSManagedObjectContext *)context {
    return [NSEntityDescription entityForName:NSStringFromClass(self) inManagedObjectContext:context];
}

+ (id)createInContext:(NSManagedObjectContext *)context {
	NSEntityDescription *entityDecription = [self entityInContext:context];
	NSString *name = [entityDecription name];
	return [NSEntityDescription insertNewObjectForEntityForName:name inManagedObjectContext:context] ;
}

- (BOOL)save {
	return [[self managedObjectContext] save:nil];
}

- (void)deleteObject {
	[[self managedObjectContext] deleteObject:self];
}

+ (void)deleteAllObjectsInContext:(NSManagedObjectContext *)context {
    NSFetchRequest *fr = [[NSFetchRequest alloc] init];
    [fr setEntity:[self entityInContext:context]];
    [fr setIncludesPropertyValues:NO]; // only fetch the managedObjectID
    
    NSError *error = nil;
    NSArray *allObjects = [context executeFetchRequest:fr error:&error];

    if(allObjects == nil) {
        NSLog(@"-- error: %@", [error localizedDescription]);
    }
    
    for (NSManagedObject *mo in allObjects) {
        [context deleteObject:mo];
    }
}

//+ (id)create {
//	NSEntityDescription *entityDecription = [self entity];
//	NSString *name = [entityDecription name];
//	return [NSEntityDescription insertNewObjectForEntityForName:name inManagedObjectContext:[self moc]] ;
//}
//
//+ (NSManagedObjectContext *)moc {
//	return [(id)[[NSApplication sharedApplication] delegate] managedObjectContext];
//}
//
//- (NSManagedObjectContext *)moc {
//	return [[self class] moc];
//}
//
//+ (NSManagedObjectModel *)mom {
//	return [(id)[[NSApplication sharedApplication] delegate] managedObjectModel];
//}
//
//+ (NSEntityDescription *)entity {
//	return [[[self mom] entitiesByName] objectForKey:NSStringFromClass([self class])];
//}
//
//+ (NSFetchRequest *)allFetchRequest {
//	NSFetchRequest *fr = [[NSFetchRequest alloc] init];
//	[fr setEntity:[self entity]];
//	return [fr autorelease];
//}
//
//+ (NSArray *)allObjects {
//	return [[self moc] executeFetchRequest:[self allFetchRequest] error:nil];
//}
//
//+ (NSUInteger)allObjectsCount {
//	return [[self moc] countForFetchRequest:[self allFetchRequest] error:nil];
//}
//
//+ (BOOL)save {
//	return [[self moc] save:nil];	
//}

@end
