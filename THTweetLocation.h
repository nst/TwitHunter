//
//  THTweetLocation.h
//  TwitHunter
//
//  Created by Nicolas Seriot on 10/4/12.
//  Copyright (c) 2012 seriot.ch. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface THTweetLocation : NSObject

@property (nonatomic, retain) NSString *ip;
@property (nonatomic, retain) NSString *placeID;
@property (nonatomic, retain) NSString *latitude;
@property (nonatomic, retain) NSString *longitude;

@end