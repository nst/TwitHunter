//
//  NSManagedObject+iLog.m
//  iLog
//
//  Created by Nicolas Seriot on 22.03.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import "NSManagedObject+TH.h"


@implementation NSManagedObject (UniqueContext)

+ (id)create {
	NSEntityDescription *entityDecription = [self entity];
	NSString *name = [entityDecription name];
	return [NSEntityDescription insertNewObjectForEntityForName:name inManagedObjectContext:[self moc]] ;
}

+ (NSManagedObjectContext *)moc {
	return [(id)[[NSApplication sharedApplication] delegate] managedObjectContext];
}

- (NSManagedObjectContext *)moc {
	return [[self class] moc];
}

+ (NSManagedObjectModel *)mom {
	return [(id)[[NSApplication sharedApplication] delegate] managedObjectModel];
}

+ (NSEntityDescription *)entity {
	return [[[self mom] entitiesByName] objectForKey:NSStringFromClass([self class])];
}

+ (NSFetchRequest *)allFetchRequest {
	NSFetchRequest *fr = [[NSFetchRequest alloc] init];
	[fr setEntity:[self entity]];
	return [fr autorelease];
}

+ (NSArray *)allObjects {
	return [[self moc] executeFetchRequest:[self allFetchRequest] error:nil];
}

+ (NSUInteger)allObjectsCount {
	return [[self moc] countForFetchRequest:[self allFetchRequest] error:nil];
}

+ (BOOL)save {
	return [[self moc] save:nil];	
}

- (BOOL)save {
	return [[self moc] save:nil];	
}

- (void)deleteObject {
	[[self moc] deleteObject:self];
}

@end
