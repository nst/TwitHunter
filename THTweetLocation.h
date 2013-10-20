//
//  THTweetLocation.h
//  TwitHunter
//
//  Created by Nicolas Seriot on 10/4/12.
//  Copyright (c) 2012 seriot.ch. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface THTweetLocation : NSObject

@property (nonatomic, strong) NSString *ipAddress;

@property (nonatomic, strong) NSString *placeID;
@property (nonatomic, strong) NSString *fullName;

@property (nonatomic, strong) NSString *latitude;
@property (nonatomic, strong) NSString *longitude;

@property (nonatomic, strong) NSString *query;

@end
