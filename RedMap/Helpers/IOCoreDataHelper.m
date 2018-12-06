//
//  IOCoreDataHelper.m
//  Redmap
//
//  Created by Evo Stamatov on 5/03/2014.
//  Copyright (c) 2014 Ionata. All rights reserved.
//

#import "IOCoreDataHelper.h"
#import "NSFileManager+IOFileManager.h"

#if ENABLE_PONYDEBUGGER
#import <PonyDebugger/PonyDebugger.h>
#endif

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;


@interface IOCoreDataHelper ()

@property (readwrite, strong, nonatomic) NSManagedObjectContext *parentContext;
@property (readwrite, strong, nonatomic) NSManagedObjectContext *context;
@property (readwrite, strong, nonatomic) NSManagedObjectContext *importContext;
@property (readwrite, strong, nonatomic) NSManagedObjectContext *logContext;

@property (readwrite, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readwrite, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end



@implementation IOCoreDataHelper
{
    NSPersistentStore *_store;
}

+ (IOCoreDataHelper *)sharedInstance
{
    static IOCoreDataHelper *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [IOCoreDataHelper new];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];

    if (self) {
#if ENABLE_PONYDEBUGGER
        
        PDDebugger *debugger = [PDDebugger defaultInstance];
        
        // Enable Network debugging, and automatically track network traffic that comes through any classes that implement either NSURLConnectionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate or NSURLSessionDataDelegate methods.
//        [debugger enableNetworkTrafficDebugging];
//        [debugger forwardAllNetworkTraffic];
        
        // Enable Core Data debugging, and broadcast the main managed object context.
        [debugger enableCoreDataDebugging];
        [debugger addManagedObjectContext:self.context withName:@"PonyDebugger RedMap MOC"];
        
        // Enable View Hierarchy debugging. This will swizzle UIView methods to monitor changes in the hierarchy
        // Choose a few UIView key paths to display as attributes of the dom nodes
//        [debugger enableViewHierarchyDebugging];
//        [debugger setDisplayedViewAttributeKeyPaths:@[@"frame", @"hidden", @"alpha", @"opaque", @"accessibilityLabel", @"text"]];
        
        // Connect to a specific host
        [debugger connectToURL:[NSURL URLWithString:@"ws://10.66.77.119:9000/device"]];
        // Or auto connect via bonjour discovery
        //[debugger autoConnect];
        // Or to a specific ponyd bonjour service
        //[debugger autoConnectToBonjourServiceNamed:@"MY PONY"];
        
        // Enable remote logging to the DevTools Console via PDLog()/PDLogObjects().
        [debugger enableRemoteLogging];
        
#endif
    }

    return self;
}

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the parent store context for the application.
- (NSManagedObjectContext *)context
{
    if (_context == nil)
    {
        NSManagedObjectContext *parentContext = [self parentContext];
        if (parentContext != nil) {
            _context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
            [_context setParentContext:parentContext];
            [_context setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
        }
    }
    
    return _context;
}

// Returns the log managed object context for the application.
// If the logContext doesn't already exist, it is created and bound to the context for the application.
- (NSManagedObjectContext *)logContext
{
    if (_logContext == nil)
    {
        NSManagedObjectContext *parentContext = [self context];
        if (parentContext != nil) {
            _logContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
            [_logContext performBlockAndWait:^{
                [_logContext setParentContext:parentContext];
                [_logContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
                //[_logContext setUndoManager:nil]; // the default on iOS
            }];
        }
    }
    
    return _logContext;
}

// Returns the import managed object context for the application.
// If the importContext doesn't already exist, it is created and bound to the context for the application.
- (NSManagedObjectContext *)importContext
{
    if (_importContext == nil)
    {
        NSManagedObjectContext *parentContext = [self context];
        if (parentContext != nil) {
            _importContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
            [_importContext performBlockAndWait:^{
                [_importContext setParentContext:parentContext];
                [_importContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
                [_importContext setUndoManager:nil]; // the default on iOS
            }];
        }
    }
    
    return _importContext;
}

// Returns the parent managed object context for the application.
// It is residing inside a Private queue, thus all calls to it should be wrapped inside performBlock(AndWait): blocks
// If the parentContext doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)parentContext
{
    if (_parentContext == nil)
    {
        NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
        if (coordinator != nil) {
            _parentContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            [_parentContext performBlockAndWait:^{
                [_parentContext setPersistentStoreCoordinator:coordinator];
                [_parentContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
            }];
        }
    }
    
    return _parentContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel == nil)
    {
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"RedMapModel" withExtension:@"momd"];
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    }
    
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator == nil)
    {
        NSURL *storeURL = [self persistentStoreCoordinatorFileURL];
        NSLog(@">>>>>>>>>> %@", storeURL);
        
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
        
        NSDictionary *options = @{
                                  NSMigratePersistentStoresAutomaticallyOption: @YES,
                                  NSInferMappingModelAutomaticallyOption: @YES,
                                  //NSSQLitePragmasOption: @{ @"journal_mode": @"DELETE" }, // Uncomment to disable WAL journal mode
                                  };
        
        NSError *error = nil;
        _store = [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                           configuration:nil
                                                                     URL:storeURL
                                                                 options:options
                                                                   error:&error];
        
        if (!_store)
        {
            DDLogError(@"%@: FAILED to add persistent store [%d] %@, UserInfo: %@", self.class, error.code, error.localizedDescription, error.userInfo);
            [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
        }
        else
        {
            DDLogVerbose(@"%@: Added persistent store", self.class);
        }
    }
    
    return _persistentStoreCoordinator;
}

/*
- (void)saveContext
{
    NSManagedObjectContext *context = self.context;
    [context performBlock:^{
        if ([context hasChanges])
        {
            NSError *error = nil;
            if (![context save:&error])
            {
                DDLogError(@"%@: ERROR: Unresolved Core Data error [%d]: %@, UserInfo: %@", self.class, error.code, error.localizedDescription, error.userInfo);
            }
        }
    }];
}
 */

- (void)saveContext
{
    logmethod();
    DDLogVerbose(@"%@: Save context", self.class);
    
    if ([_context hasChanges])
    {
        NSError *error = nil;
        if ([_context save:&error])
        {
            DDLogInfo(@"%@: SAVED changes to parent context", self.class);
        }
        else
        {
            DDLogError(@"%@: FAILED to save context[%d]: %@", self.class, error.code, error.localizedDescription);
            [IOCoreDataHelper showValidationError:error];
        }
    }
    else
    {
        DDLogVerbose(@"%@: SKIPPED context save, as there are no changes!", self.class);
    }
}

- (void)backgroundSaveContext
{
    logmethod();
    DDLogVerbose(@"%@: Background save context", self.class);
    
    // First, save the child context in the foreground (fast, all in memory)
    [self saveContext];
    
    // Then, save the parent context.
    [_parentContext performBlock:^{
        if ([_parentContext hasChanges])
        {
            NSError *error = nil;
            if ([_parentContext save:&error])
            {
                DDLogVerbose(@"%@: SAVED changes to persistent store", self.class);
            }
            else
            {
                DDLogError(@"%@: FAILED to save parent context[%d]: %@", self.class, error.code, error.localizedDescription);
                [IOCoreDataHelper showValidationError:error];
            }
        }
        else
        {
            DDLogVerbose(@"%@: SKIPPED parent context save, as there are no changes!", self.class);
        }
    }];
}

+ (void)showValidationError:(NSError *)anError {
    
    if (anError && [anError.domain isEqualToString:@"NSCocoaErrorDomain"])
    {
        NSArray *errors = nil;  // holds all errors
        NSString *txt = @""; // the error message text of the alert
        
        // Populate array with error(s)
        if (anError.code == NSValidationMultipleErrorsError)
            errors = [anError.userInfo objectForKey:NSDetailedErrorsKey];
        else
            errors = [NSArray arrayWithObject:anError];
        
        // Display the error(s)
        if (errors && errors.count > 0)
        {
            // Build error message text based on errors
            for (NSError *error in errors)
            {
                NSString *entity = [[[error.userInfo objectForKey:@"NSValidationErrorObject"] entity] name];
                
                NSString *property = [error.userInfo objectForKey:@"NSValidationErrorKey"];
                
                switch (error.code) {
                    case NSValidationRelationshipDeniedDeleteError:
                        txt = [txt stringByAppendingFormat:@"%@ delete was denied because there are associated %@\n(Error Code %li)\n\n", entity, property, (long)error.code];
                        break;
                    case NSValidationRelationshipLacksMinimumCountError:
                        txt = [txt stringByAppendingFormat:@"The '%@' relationship count is too small (Code %li).", property, (long)error.code];
                        break;
                    case NSValidationRelationshipExceedsMaximumCountError:
                        txt = [txt stringByAppendingFormat:@"The '%@' relationship count is too large (Code %li).", property, (long)error.code];
                        break;
                    case NSValidationMissingMandatoryPropertyError:
                        txt = [txt stringByAppendingFormat:@"The '%@' property is missing (Code %li).", property, (long)error.code];
                        break;
                    case NSValidationNumberTooSmallError:
                        txt = [txt stringByAppendingFormat:@"The '%@' number is too small (Code %li).", property, (long)error.code];
                        break;
                    case NSValidationNumberTooLargeError:
                        txt = [txt stringByAppendingFormat:@"The '%@' number is too large (Code %li).", property, (long)error.code];
                        break;
                    case NSValidationDateTooSoonError:
                        txt = [txt stringByAppendingFormat:@"The '%@' date is too soon (Code %li).", property, (long)error.code];
                        break;
                    case NSValidationDateTooLateError:
                        txt = [txt stringByAppendingFormat:@"The '%@' date is too late (Code %li).", property, (long)error.code];
                        break;
                    case NSValidationInvalidDateError:
                        txt = [txt stringByAppendingFormat:@"The '%@' date is invalid (Code %li).", property, (long)error.code];
                        break;
                    case NSValidationStringTooLongError:
                        txt = [txt stringByAppendingFormat:@"The '%@' text is too long (Code %li).", property, (long)error.code];
                        break;
                    case NSValidationStringTooShortError:
                        txt = [txt stringByAppendingFormat:@"The '%@' text is too short (Code %li).", property, (long)error.code];
                        break;
                    case NSValidationStringPatternMatchingError:
                        txt = [txt stringByAppendingFormat:@"The '%@' text doesn't match the specified pattern (Code %li).", property, (long)error.code];
                        break;
                    case NSManagedObjectValidationError:
                        txt = [txt stringByAppendingFormat:@"Generated validation error (Code %li).", (long)error.code];
                        break;
                        
                    default:
                        txt = [txt stringByAppendingFormat:@"Unhandled error code %li in showValidationError method.", (long)error.code];
                        break;
                }
            }
            
            // log and display an error message
            DDLogError(@"%@: ERROR. %@", self.class, txt);
            //DDLogError(@"xcdoc://ios/documentation/Cocoa/Reference/CoreDataFramework/Miscellaneous/CoreData_Constants/Reference/reference.html");
            
            NSString *message;
            if (iOS_7_OR_LATER())
                message = NSLocalizedString(@"Please, double-tap the home button and close this application by swiping the application screenshot upwards", @"iOS7+ specific message");
            else
                message = NSLocalizedString(@"Please, double-tap the home button, then press-and-hold this application's icon until a minus sign appears, then press it to quit the app.", @"iOS6 specific message");
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Database Validation Error", @"")
                                                                message:message
                                                               delegate:nil
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:nil];
            [alertView show];
        }
    }
}

- (NSURL *)persistentStoreCoordinatorFileURL
{
    static NSURL *sqliteFileURL;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSFileManager *fm = [NSFileManager defaultManager];
        
        NSString *sqliteFileName = @"Redmap.sqlite";
        sqliteFileURL = [[fm URLForApplicationBundleDirectory] URLByAppendingPathComponent:sqliteFileName];
        
        // On error revert back to /Library/ which should always be reachable
        if (!sqliteFileURL)
        {
            NSURL *libDirURL = [[fm URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
            sqliteFileURL = [libDirURL URLByAppendingPathComponent:sqliteFileName];
        }
    });
    
    return sqliteFileURL;
}

- (void)resetContext:(NSManagedObjectContext*)moc {
    logmethod();
    [moc performBlockAndWait:^{
        [moc reset];
    }];
}

- (BOOL)reloadStore
{
    logmethod();
    BOOL success = NO;
    
    if (!_store)
    {
        DDLogVerbose(@"%@: No need to reload store, since it doen's exist yet", self.class);
        return YES;
    }
    
    [self resetContext:_importContext];
    [self resetContext:_logContext];
    [self resetContext:_context];
    [self resetContext:_parentContext];
    
    [_importContext lock];
    [_logContext lock];
    [_context lock];
    [_parentContext lock];
    for (NSPersistentStore *store in self.persistentStoreCoordinator.persistentStores)
    {
        NSError *error = nil;
        if (![self.persistentStoreCoordinator removePersistentStore:store error:&error])
        {
            DDLogError(@"%@: ERROR removing persistent store[%d]: %@", self.class, error.code, error.localizedDescription);
        }
    }
    [_importContext unlock];
    [_logContext unlock];
    [_context unlock];
    [_parentContext unlock];
    
    _importContext = nil;
    _logContext = nil;
    _context = nil;
    _parentContext = nil;
    
    _persistentStoreCoordinator = nil;
    _managedObjectModel = nil;
    _store = nil;
    
    // touching the import context will simply re-create all lazy properties :)
    [self importContext];
    
    // TODO: send a notification something changed :)
    
    if (_store)
        success = YES;
    
    return success;
}

+ (void)faultObjectWithID:(NSManagedObjectID*)objectID inContext:(NSManagedObjectContext*)context
{
    if (!objectID || !context)
        return;
    
    [context performBlockAndWait:^{
        
        NSManagedObject *object = [context objectWithID:objectID];
        
        if (object.hasChanges) {
            NSError *error = nil;
            if (![context save:&error])
                DDLogError(@"IOCoreDataHelper: ERROR saving context. [%d]: %@", error.code, error.localizedDescription);
        }
        
        if (!object.isFault)
        {
            DDLogVerbose(@"IOCoreDataHelper: Faulting object in context.");
            [context refreshObject:object mergeChanges:NO];
        }
        else
            DDLogVerbose(@"IOCoreDataHelper: Skipped faulting an object that is already a fault");
        
        // Repeat the process if the context has a parent
        if (context.parentContext)
            [self faultObjectWithID:objectID inContext:context.parentContext];
    }];
}

+ (void)saveContextHierarchy:(NSManagedObjectContext *)managedObjectContext
{
    logmethod();
    [managedObjectContext performBlockAndWait:^{
        if ([managedObjectContext hasChanges])
        {
            [managedObjectContext processPendingChanges];
            
            NSError *error = nil;
            if (![managedObjectContext save:&error])
            {
                DDLogError(@"IOCoreDataHelper: ERROR saving in context. [%d]: %@", error.code, error.localizedDescription);
            }
            else
            {
                DDLogVerbose(@"IOCoreDataHelper: Saved in context (hierarchy level)");
            }
            
            // Save parent context
            if (managedObjectContext.parentContext)
                [self saveContextHierarchy:managedObjectContext.parentContext];
        }
    }];
}

@end
