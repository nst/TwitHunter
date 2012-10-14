//
//  THCollectionView.m
//  TwitHunter
//
//  Created by Nicolas Seriot on 10/13/12.
//  Copyright (c) 2012 seriot.ch. All rights reserved.
//

#import "THCollectionView.h"
#import "THTweetCollectionViewItem.h"
#import "THTweet.h"
#import "THTweetView.h"

@implementation THCollectionView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

//- (void)drawRect:(NSRect)dirtyRect
//{
//    // Drawing code here.
//}

- (void)awakeFromNib {
    [super awakeFromNib];
	[self setMinItemSize:NSMakeSize(0.0, 50)];
	[self setMaxItemSize:NSMakeSize(0.0, 50)];
}
//
//// get the view for a tweet
//- (NSCollectionViewItem *)newItemForRepresentedObject:(THTweet *)tweet {
//    
////	if([track isFault]) {
////		track.uti; // fetch the track
////	}
//	NSAssert([tweet isFault] == NO, @"error: tweet is fault");
//	
//	THTweetCollectionViewItem *item = (THTweetCollectionViewItem *)[super newItemForRepresentedObject:tweet];
//
//    THTweetView *tweetView = (THTweetView *)[item view];
//        
//    [tweetView setStatus:@"asd"]; // tweet.text
//    
////    [item setText:@"fghfg"];
//    
//    //NSLog(@"-- %@", tweet.text);
//    
////    [item.tweetTextTextView setEditable:YES];
////    [item.tweetTextTextView setAutomaticLinkDetectionEnabled:YES];
////    [item.tweetTextTextView setString:tweet.text];
////    [item.tweetTextTextView setEditable:NO];
//    
////	[item setRepresentedObject:track];
////    
////    SLTrackView *trackView = (SLTrackView *)[item view];
////    
////    track.trackView = trackView;
//    //    trackView.track = track;
//    
//    //    trackView.mdItems = track.queryResults;
//    //    trackView.query = track.query;
//    //
//    //	[[item view] setValue:track.queryResults forKey:@"controller"];
//    //	[[item view] setValue:track.query forKey:@"query"];
//    //
//    //	track.collectionView = self;
//    //	track.mainView = [item view];
//	
//	return item;
//}

@end
