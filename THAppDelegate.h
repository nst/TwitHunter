//
//  TwitHunter_AppDelegate.h
//  TwitHunter
//
//  Created by Nicolas Seriot on 19.04.09.
//  Copyright Sen:te 2009 . All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface THAppDelegate : NSObject
{
    NSWindow *window;
    
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
}

@property (nonatomic, retain) IBOutlet NSWindow *window;

@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

- (IBAction)saveAction:sender;

@end