//
//  THTweetLocation.h
//  TwitHunter
//
//  Created by Nicolas Seriot on 10/4/12.
//  Copyright (c) 2012 seriot.ch. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface THTweetLocation : NSObject

@property (nonatomic, retain) NSString *ipAddress;

@property (nonatomic, retain) NSString *placeID;
@property (nonatomic, retain) NSString *fullName;

@property (nonatomic, retain) NSString *latitude;
@property (nonatomic, retain) NSString *longitude;

@property (nonatomic, retain) NSString *query;

@end
