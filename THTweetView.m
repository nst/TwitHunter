//
//  THTweetView.m
//  TwitHunter
//
//  Created by Nicolas Seriot on 10/13/12.
//  Copyright (c) 2012 seriot.ch. All rights reserved.
//

#import "THTweetView.h"
#import "THTextView.h"

@implementation THTweetView

//- (void)setStatus:(NSString *)s {
//    NSLog(@"-- %@", _tweetTextView);
//    
//    NSMutableAttributedString *attributedStatusString = [[NSMutableAttributedString alloc] initWithString:s];
//	[[_tweetTextView textStorage] setAttributedString:attributedStatusString];
//    [attributedStatusString release];
//}

- (void)dealloc {
    [_tweetTextView release];
    [super dealloc];
}

//- (id)initWithFrame:(NSRect)frame
//{
//    self = [super initWithFrame:frame];
//    if (self) {
//        // Initialization code here.
//    }
//    
//    return self;
//}
//
//- (void)drawRect:(NSRect)dirtyRect
//{
//    // Drawing code here.
//}

@end
