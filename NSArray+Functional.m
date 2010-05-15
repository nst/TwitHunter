//
//  NSArray+Functional.m
//  TwitHunter
//
//  Created by Nicolas Seriot on 5/15/10.
//  Copyright 2010 seriot.ch. All rights reserved.
//

#import "NSArray+Functional.h"


@implementation NSArray (Functional)

// from http://parmanoir.com/8_ways_to_use_Blocks_in_Snow_Leopard
- (NSArray*)filter:(BOOL(^)(id elt))filterBlock {
	// Create a new array
	id filteredArray = [NSMutableArray array];
	// Collect elements matching the block condition
	for (id elt in self)
		if (filterBlock(elt)) [filteredArray addObject:elt];
	return	filteredArray;
}

@end
