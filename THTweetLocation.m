//
//  THTweetLocation.m
//  TwitHunter
//
//  Created by Nicolas Seriot on 10/4/12.
//  Copyright (c) 2012 seriot.ch. All rights reserved.
//

#import "THTweetLocation.h"

@implementation THTweetLocation

- (void)dealloc {
    [_ip release];
    [_placeID release];
    [_latitude release];
    [_longitude release];

    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone {
    THTweetLocation *tl = [[THTweetLocation alloc] init];
    
    tl.ip = [[_ip copy] autorelease];
    tl.placeID = [[_placeID copy] autorelease];
    tl.latitude = [[_latitude copy] autorelease];
    tl.longitude = [[_longitude copy] autorelease];
    
    return tl;
}

@end
