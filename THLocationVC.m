//
//  THLocationVC.m
//  TwitHunter
//
//  Created by Nicolas Seriot on 10/9/12.
//  Copyright (c) 2012 seriot.ch. All rights reserved.
//

#import "THLocationVC.h"
#import "THTweetLocation.h"
#import "STTwitter.h"
#import "STJSONIP.h"

@interface THLocationVC ()

@end

@implementation THLocationVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)awakeFromNib {
    [STJSONIP getExternalIPAddressWithSuccessBlock:^(NSString *ipAddress) {
        _tweetLocation.ipAddress = ipAddress;
    } errorBlock:^(NSError *error) {
        NSLog(@"-- %@", [error localizedDescription]);
    }];
}

- (IBAction)ok:(id)sender {
    NSLog(@"-- ok");
    
    NSString *selectedPlaceID = [[_twitterPlacesController selectedObjects] lastObject];
    
    // 46.5199617
    // 6.6335971
    
    _tweetLocation.placeID = [selectedPlaceID valueForKey:@"id"];
    _tweetLocation.fullName = [selectedPlaceID valueForKey:@"full_name"];
    
    [_locationDelegate locationVC:self didChooseLocation:_tweetLocation];
}

- (IBAction)cancel:(id)sender {
    NSLog(@"-- cancel");
    
    [_locationDelegate locationVCDidCancel:self];
}

- (IBAction)lookupIPAddress:(id)sender {
    
    [_twitter getGeoSearchWithIPAddress:_tweetLocation.ipAddress successBlock:^(NSArray *places) {
        
        self.twitterPlaces = places;
        
        NSLog(@"-- places: %@", places);
        
        //        self.locationDescription = [firstPlace valueForKey:@"full_name"];
        
    } errorBlock:^(NSError *error) {
        NSLog(@"-- %@", [error localizedDescription]);
    }];
}

- (IBAction)lookupCoordinates:(id)sender {
    
    [_twitter getGeoSearchWithLatitude:_tweetLocation.latitude longitude:_tweetLocation.longitude successBlock:^(NSArray *places) {
    
        self.twitterPlaces = places;
        
        NSLog(@"-- places: %@", places);
        
        //        self.locationDescription = [firstPlace valueForKey:@"full_name"];
        
    } errorBlock:^(NSError *error) {
        NSLog(@"-- %@", [error localizedDescription]);
    }];
}

- (IBAction)lookupQuery:(id)sender {
    
    [_twitter getGeoSearchWithQuery:_tweetLocation.query successBlock:^(NSArray *places) {
        
        self.twitterPlaces = places;
        
        NSLog(@"-- places: %@", places);
        
        //        self.locationDescription = [firstPlace valueForKey:@"full_name"];
        
    } errorBlock:^(NSError *error) {
        NSLog(@"-- %@", [error localizedDescription]);
    }];
}

@end
