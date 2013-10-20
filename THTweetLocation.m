//
//  THTweetLocation.m
//  TwitHunter
//
//  Created by Nicolas Seriot on 10/4/12.
//  Copyright (c) 2012 seriot.ch. All rights reserved.
//

#import "THTweetLocation.h"

@implementation THTweetLocation

- (id)copyWithZone:(NSZone *)zone {
    THTweetLocation *tl = [[THTweetLocation alloc] init];
    
    tl.ipAddress = [_ipAddress copy];
    tl.placeID = [_placeID copy];
    tl.latitude = [_latitude copy];
    tl.longitude = [_longitude copy];
    tl.fullName = [_fullName copy];
    tl.query = [_query copy];
    
    return tl;
}

- (NSString *)description {
    if(_placeID) {
        return _fullName;
    } else if(_latitude && _longitude) {
        return [NSString stringWithFormat:@"%@, %@", _latitude, _longitude];
    }
    
    return @"";
}

@end
