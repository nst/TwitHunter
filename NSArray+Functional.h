//
//  NSArray+Functional.h
//  TwitHunter
//
//  Created by Nicolas Seriot on 5/15/10.
//  Copyright 2010 seriot.ch. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSArray (Functional)

- (NSArray*)filter:(BOOL(^)(id elt))filterBlock;

@end
