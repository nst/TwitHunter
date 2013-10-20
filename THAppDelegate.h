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

@property (nonatomic, strong) IBOutlet NSWindow *window;

@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;

- (IBAction)saveAction:sender;

@end