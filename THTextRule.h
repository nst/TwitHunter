//
//  TextRule.h
//  TwitHunter
//
//  Created by Nicolas Seriot on 21.04.09.
//  Copyright 2009 Sen:te. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface THTextRule :  NSManagedObject  
{
}

@property (nonatomic, strong) NSNumber * score;
@property (nonatomic, strong) NSString * keyword;

@end



