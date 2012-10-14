//
//  THScrolView.m
//  TwitHunter
//
//  Created by Nicolas Seriot on 10/13/12.
//  Copyright (c) 2012 seriot.ch. All rights reserved.
//

#import "THScrollView.h"

@implementation THScrollView

//- (void)awakeFromNib {
//    [super awakeFromNib];
//    
//    [self setVerticalLineScroll:0.0];
//    [self setVerticalPageScroll:0.0];
//}

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

//- (void)scrollWheel:(NSEvent *)theEvent {
//    void (*responderScroll)(id, SEL, id);
//    
//    responderScroll = (void (*)(id, SEL, id))([NSResponder
//                                               instanceMethodForSelector:@selector(scrollWheel:)]);
//    
//    responderScroll(self, @selector(scrollWheel:), theEvent);
//}

- (void)scrollWheel:(NSEvent *)theEvent
{
    [[self nextResponder] scrollWheel:theEvent];
}

@end
