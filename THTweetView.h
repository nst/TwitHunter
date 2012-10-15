//
//  THTweetView.h
//  TwitHunter
//
//  Created by Nicolas Seriot on 10/15/12.
//  Copyright (c) 2012 seriot.ch. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class THTweetView;

@protocol THTweetViewProtocol
- (void)tweetViewWasClicked:(THTweetView *)tweetView;
@end

@interface THTweetView : NSView

@property (nonatomic, assign) id <THTweetViewProtocol> delegate;

@property (nonatomic) BOOL selected;

@end
