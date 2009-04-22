//
//  TwitHunter_AppDelegate.h
//  TwitHunter
//
//  Created by Nicolas Seriot on 19.04.09.
//  Copyright Sen:te 2009 . All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TwitHunter_AppDelegate : NSObject 
{
    IBOutlet NSWindow *window;
    
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *)managedObjectContext;

- (IBAction)saveAction:sender;

@end
