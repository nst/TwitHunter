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

@end
