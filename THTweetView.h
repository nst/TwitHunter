//
//  THTweetView.h
//  TwitHunter
//
//  Created by Nicolas Seriot on 10/13/12.
//  Copyright (c) 2012 seriot.ch. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class THTextView;

@interface THTweetView : NSView

@property (nonatomic, retain) IBOutlet THTextView *tweetTextView;

//- (void)setStatus:(NSString *)s;

@end
