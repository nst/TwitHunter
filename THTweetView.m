//
//  THTweetView.m
//  TwitHunter
//
//  Created by Nicolas Seriot on 10/15/12.
//  Copyright (c) 2012 seriot.ch. All rights reserved.
//

#import "THTweetView.h"

@implementation THTweetView

//- (id)initWithFrame:(NSRect)frameRect {
//    self = [super initWithFrame:frameRect];
//    NSLog(@"-- initWithFrame");
//    return self;
//}

- (void)drawRect:(NSRect)dirtyRect {
    if (self.selected) {
        [[NSColor orangeColor] set];
        NSRectFill(dirtyRect);
    }
}

- (void)setSelected:(BOOL)flag {
    if (_selected == flag) {
        return;
    }
    
    _selected = flag;
    [self setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent *)theEvent {

	NSLog(@"-- mouse down: %@", theEvent);
    
	[super mouseDown:theEvent];
    
    //[_delegate tweetViewWasClicked:self];
}

@end
