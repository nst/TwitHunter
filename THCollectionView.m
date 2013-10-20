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

@interface THCollectionView ()
@property (nonatomic, strong) NSIndexSet *formerSelectionIndexSet;
@end

@implementation THCollectionView

- (NSCollectionViewItem *)newItemForRepresentedObject:(id)object {
        
    NSCollectionViewItem *item = [super newItemForRepresentedObject:object];
//    NSView *view = [item view];
//    
//    [view bind:@"title"
//      toObject:object
//   withKeyPath:@"title"
//       options:nil];
//    
//    [view bind:@"option"
//      toObject:object
//   withKeyPath:@"option"
//       options:nil];
    
    return item;
}

- (void)setSelectionIndexes:(NSIndexSet *)indexes {
    [super setSelectionIndexes:indexes];
    
    [_formerSelectionIndexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        NSCollectionViewItem *item = [self itemAtIndex:idx];
        THTweetView *view = (THTweetView *)[item view];
        [view setSelected:NO];
    }];
    
    self.formerSelectionIndexSet = indexes;
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        NSCollectionViewItem *item = [self itemAtIndex:idx];
        THTweetView *view = (THTweetView *)[item view];
        [view setSelected:YES];
    }];
}

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
