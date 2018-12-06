//
//  IOUploadAPendingSighting.m
//  Redmap
//
//  Created by Evo Stamatov on 11/03/2014.
//  Copyright (c) 2014 Ionata. All rights reserved.
//

#import "IOUploadAPendingSighting.h"
#import "IOAuth.h"
#import "User.h"
#import "Sighting.h"
#import "IOCoreDataHelper.h"
#import "IOPhotoCollection.h"
#import "IOAlertView.h"
#import "RedMapAPIEngine.h"
#import "IOSightingAttributesController.h"
#import "Species.h"
#import "IOAudioPlayer.h"

typedef void (^PlainBlock)();

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

@interface IOUploadAPendingSighting ()
@property (nonatomic, assign) BOOL shouldScheduleAnotherUploadWhenDone;
@property (nonatomic, strong) NSOperation *remoteOperation;
@property (nonatomic, strong) IOAlertView *uploadingAlertView;
@property (nonatomic, strong) PlainBlock plainCompletionBlock;
@property (nonatomic, assign) BOOL shouldRevertStatusIfCancelled;
@end

@implementation IOUploadAPendingSighting

////////////////////////////////////////////////////////////////////////////////
- (id)initWithGlobalQueue:(NSOperationQueue *)queue forced:(BOOL)forced
{
    self = [super initWithGlobalQueue:queue forced:forced];
    if (self)
    {
        logmethod();
#if DEBUG
        DDLogWarn(@"/\\/\\/\\/\\/\\/\\/\\/\\/\\ %@: Initializing, %p", self.class, self);
#endif
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
- (void)dealloc
{
    logmethod();
#if DEBUG
    DDLogWarn(@"/\\/\\/\\/\\/\\/\\/\\/\\/\\ %@: Deallocating, %p", self.class, self);
#else
    DDLogWarn(@"%@: Deallocating", self.class);
#endif
    
    _remoteOperation = nil;
    _uploadingAlertView = nil;
    _successBlock = nil;
    self.plainCompletionBlock = nil;
}

////////////////////////////////////////////////////////////////////////////////
- (void)main
{
    logmethod();
    @autoreleasepool {
        DDLogVerbose(@"%@: Initiating a sighting upload operation", self.class);
        
        if (self.isCancelled)
            return;
        
        User *user = [[IOAuth sharedInstance] currentUser];
        
        if (self.isCancelled)
            return;
        
        if (user == nil)
        {
            DDLogInfo(@"%@: SKIPPING operation - no logged in user", self.class);
            [self finish];
            return;
        }
        else if (user.authToken == nil || user.authToken.length == 0)
        {
            DDLogError(@"%@: ERROR. Current user has no auth token", self.class);
            [self finish];
            return;
        }
        
        if (self.isCancelled)
            return;
        
        if (self.context == nil)
        {
            DDLogError(@"%@: ERROR. No context", self.class);
            [self finish];
            return;
        }
        
#if DEBUG
        {
            NSManagedObjectContext *context = self.context;
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Sighting"];
            NSPredicate *statePredicate = [NSPredicate predicateWithFormat:@"(status == %@)", @(IOSightingStatusSyncing)];
            fetchRequest.predicate = statePredicate;
            __weak __typeof(self)weakSelf = self;
            [context performBlockAndWait:^{
                NSError *fetchError = nil;
                NSArray *result = [context executeFetchRequest:fetchRequest error:&fetchError];
                if (!fetchError && result.count > 0)
                {
                    [result enumerateObjectsUsingBlock:^(Sighting *obj, NSUInteger idx, BOOL *stop) {
                        DDLogWarn(@"%@: WARNING. Found sighting (%@), that has Syncing status. Reverting it to Saved.", weakSelf.class, obj.uuid);
                        obj.status = @(IOSightingStatusSaved);
                        [IOCoreDataHelper faultObjectWithID:obj.objectID inContext:context];
                    }];
                }
            }];
        }
        
        if (self.isCancelled)
            return;
#endif
            
        NSManagedObjectID *nextSightingObjectID;
        BOOL shouldScheduleANewCheck = NO;
        
        if (self.sightingID == nil)
        {
            __strong NSManagedObjectContext *context = self.context;
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Sighting"];
            fetchRequest.fetchLimit = 2;
            
            if (self.isCancelled)
                return;
            
            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dateModified" ascending:NO];
            fetchRequest.sortDescriptors = @[sortDescriptor];
            
            if (self.isCancelled)
                return;
            
            NSPredicate *statePredicate = [NSPredicate predicateWithFormat:@"(status == %@)", @(IOSightingStatusSaved)];
            //NSPredicate *userPredicate = [NSPredicate predicateWithFormat:@"(user.userID == %@)", user.userID];
            //NSPredicate *filterPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[statePredicate, userPredicate]];
            //fetchRequest.predicate = filterPredicate;
            fetchRequest.predicate = statePredicate;
            
            if (self.isCancelled)
                return;
            
            __block NSError *fetchError = nil;
            __block NSArray *results;
            [context performBlockAndWait:^{
                results = [context executeFetchRequest:fetchRequest error:&fetchError];
            }];
            
            if (self.isCancelled)
                return;
            
            if (fetchError)
            {
                DDLogError(@"%@: ERROR fetching sightings. [%d]: %@", self.class, fetchError.code, fetchError.localizedDescription);
                [self finish];
                return;
            }
            
            if (results.count > 0)
            {
                NSManagedObject *mo;
                if (results.count > 1)
                {
                    mo = [results objectAtIndex:1];
                    nextSightingObjectID = [mo.objectID copy];
                    shouldScheduleANewCheck = YES;
                }
                
                mo = [results objectAtIndex:0];
                self.sightingID = mo.objectID;
            }
        }
        else
        {
            shouldScheduleANewCheck = YES;
        }
        
        if (self.isCancelled)
            return;
        
        if (self.sightingID)
        {
            DDLogVerbose(@"%@: Publishing a sighting.", self.class);
            
            __weak __typeof(self)weakSelf = self;
            [self publishSighting:self.sightingID completion:^{
                DDLogVerbose(@"%@: Finished processing the sighting.", weakSelf.class);
                
#if DEBUG
                DDLogError(@"Cancelled: %@, shouldScheduleANewCheck: %@, hasSuccessBlock: %@", weakSelf.isCancelled ? @"YES" : @"NO", shouldScheduleANewCheck ? @"YES" : @"NO", weakSelf.successBlock ? @"YES" : @"NO");
#endif
                
                if (!weakSelf.isCancelled && weakSelf.successBlock)
                {
                    weakSelf.successBlock(shouldScheduleANewCheck, nextSightingObjectID);
                    weakSelf.successBlock = nil;
                }
                
                [weakSelf cleanup];
                    
                DDLogVerbose(@"%@: Finished with the operation.", weakSelf.class);
                [weakSelf finish];
            }];
        }
        else
        {
            DDLogVerbose(@"%@: SKIPPING. No sightings to upload.", self.class);
            [self finish];
        }
    }
}

////////////////////////////////////////////////////////////////////////////////
- (void)cleanup
{
    logmethod();
    if (self.uploadingAlertView)
    {
        __weak __typeof(self)weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.uploadingAlertView dismissWithClickedButtonIndex:weakSelf.uploadingAlertView.cancelButtonIndex animated:NO];
            weakSelf.uploadingAlertView.delegate = nil;
            weakSelf.uploadingAlertView = nil;
        });
    }
    
    [self revertSightingIfNeeded];
}

////////////////////////////////////////////////////////////////////////////////
- (void)cancel
{
    logmethod();
    [self.remoteOperation cancel];
    self.remoteOperation = nil;
    
    if (self.isExecuting)
        DDLogVerbose(@"%@: Operation cancelled", self.class);
    
    [self cleanup];
    
    [super cancel];
}

////////////////////////////////////////////////////////////////////////////////
- (void)revertSightingIfNeeded
{
    logmethod();
    if (self.shouldRevertStatusIfCancelled)
    {
        DDLogWarn(@"%@: Reverting sighting status to saved", self.class);
        
        __strong NSManagedObjectContext *context = self.context;
        __weak __typeof(self)weakSelf = self;
        
        [context performBlockAndWait:^{
            Sighting *sighting = (Sighting *)[context objectWithID:weakSelf.sightingID];
            sighting.status = @(IOSightingStatusSaved);
            [IOCoreDataHelper faultObjectWithID:weakSelf.sightingID inContext:context];
        }];
    }
}

////////////////////////////////////////////////////////////////////////////////
- (void)publishSighting:(NSManagedObjectID *)sightingID completion:(PlainBlock)completion
{
    logmethod();
    NSAssert(sightingID, @"sightingID");
    NSAssert(completion, @"completion");
    
    __strong NSManagedObjectContext *context = self.context;
    Sighting *sighting = (Sighting *)[context objectWithID:sightingID];
    
    if ([sighting.status integerValue] == IOSightingStatusSaved)
    {
        sighting.status = @(IOSightingStatusSyncing);
        
        if (sighting.user == nil)
        {
            DDLogVerbose(@"%@: Missing sighting user. Setting to the current one.", self.class);
            User *currentUser = [[IOAuth sharedInstance] currentUser];
            User *user = (User *)[context objectWithID:currentUser.objectID];
            sighting.user = user;
            [IOCoreDataHelper faultObjectWithID:user.objectID inContext:context];
        }
        
        [IOCoreDataHelper faultObjectWithID:sighting.objectID inContext:context];
        
        self.shouldRevertStatusIfCancelled = YES;
        
        [self fetchSightinPhotoAndUpload:sighting completion:[completion copy]];
    }
    else
    {
        switch ([sighting.status integerValue]) {
            case IOSightingStatusSyncing:
                DDLogVerbose(@"%@: SKIPPED. The sighting is beign synced.", self.class);
                break;
                
            case IOSightingStatusSynced:
                DDLogVerbose(@"%@: SKIPPED. The sighting is already synced.", self.class);
                break;
                
            case IOSightingStatusDraft:
                DDLogVerbose(@"%@: SKIPPED. The sighting is still a draft.", self.class);
                break;
                
            default:
                DDLogError(@"%@: ERROR. Unknown sighting status.", self.class);
                break;
        }
        
        [IOCoreDataHelper faultObjectWithID:sighting.objectID inContext:context];
        completion();
    }
}

////////////////////////////////////////////////////////////////////////////////
- (void)fetchSightinPhotoAndUpload:(Sighting *)sighting completion:(PlainBlock)completion
{
    logmethod();
    NSAssert(sighting, @"sighting");
    NSAssert(completion, @"completion");
    
    DDLogVerbose(@"%@: Fetching the sighting photo", self.class);
    
    if (self.isCancelled)
        return;
    
    __weak __typeof(self)weakSelf = self;
    IOPhotoCollection *photos = [[IOPhotoCollection alloc] init];
    [photos reSetTheUUID:sighting.uuid withCallback:^(NSError *error) {
        if (error)
        {
            DDLogError(@"%@: ERROR loading photos for sighting. [%d]: %@", weakSelf.class, error.code, error.localizedDescription);
#if DEBUG
            DDLogError(@"%@: Sighting UUID: %@", weakSelf.class, sighting.uuid);
#endif
            completion();
            return;
        }
        
        if (photos.count < 1)
        {
            DDLogInfo(@"%@: SKIPPING. No photos found for sighting", weakSelf.class);
            completion();
            return;
        }
        
        if (weakSelf.isCancelled)
            return;
        
        NSURL *photoURL = [photos photoURLAtIndex:0];
        NSAssert(photoURL, @"photoURL");
        
        [weakSelf uploadASighting:(Sighting *)sighting withPhotoAtURL:photoURL completion:[completion copy]];
    }];
}

////////////////////////////////////////////////////////////////////////////////
- (void)uploadASighting:(Sighting *)sighting withPhotoAtURL:(NSURL *)photoURL completion:(PlainBlock)completion
{
    logmethod();
    NSAssert(sighting, @"sighting");
    NSAssert(photoURL, @"photoURL");
    NSAssert(completion, @"completion");
    
    DDLogVerbose(@"%@: Uploading the sighting", self.class);
    
#if DEBUG
    DDLogVerbose(@"%@: Sighting UUID: %@", self.class, sighting.uuid);
#endif
    
    if (self.isCancelled)
        return;
    
    if (!RMAPI.isReachable)
    {
        DDLogError(@"%@: ERROR. No internet connection to submit the sighting", self.class);
        
        if (self.showsUploadingProgress)
        {
            NSString *title = NSLocalizedString(@"Oopsie", @"");
            NSString *message = NSLocalizedString(@"There is no connection to the internet. The sighting was saved locally and will be re-tried at a later time", @"");
            
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                                message:message
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"Dismiss", @"")
                                                      otherButtonTitles:nil];
                [alert show];
            });
        }
        
        completion();
        return;
    }
    
    Species *species = (Species *)sighting.species;
    
    __weak __typeof(self)weakSelf = self;
    if (self.showsUploadingProgress)
    {
        self.uploadingAlertView = [IOAlertView alertViewWithProgressBarAndTitle:@"Sending the sighting"];
        dispatch_async(dispatch_get_main_queue(), ^{
            //[_uploadingAlertView setProgress:0.f animated:NO];
            [weakSelf.uploadingAlertView show];
        });
    }
    
    __block NSDictionary *speciesDict = nil;
    if (species)
    {
        __strong NSManagedObjectContext *context = self.context;
        [context performBlockAndWait:^{
            speciesDict = @{ kIOSightingEntryIDKey: species.id };
            [IOCoreDataHelper faultObjectWithID:species.objectID inContext:context];
        }];
    }
    
    NSString *authToken = [[[IOAuth sharedInstance] currentUser] authToken];
    
    self.remoteOperation = [RMAPI sendASightingUsingAuthToken:authToken
                                   accuracy:sighting.locationAccuracy
                                   activity:sighting.activity
                                      count:sighting.speciesCount
                                      depth:[sighting.depth integerValue]
                                    habitat:sighting.speciesHabitat
                                   latitude:[sighting.locationLat doubleValue]
                                  longitude:[sighting.locationLng doubleValue]
                                      notes:nil
                      otherSpeciesLatinName:sighting.otherSpeciesName
                     otherSpeciesCommonName:sighting.otherSpeciesCommonName
                               photoCaption:sighting.comment
                                   photoURL:photoURL
                                        sex:sighting.speciesSex
                               sightingDate:sighting.dateSpotted
                                       size:[sighting.speciesLength integerValue]
                                 sizeMethod:sighting.speciesLengthMethod
                                    species:speciesDict
                                       time:sighting.time
                           waterTemperature:[sighting.waterTemperature integerValue]
                                     weight:[sighting.speciesWeight floatValue]
                               weightMethod:sighting.speciesWeightMethod
                           onUploadProgress:^(double progress)
          {
              DDLogInfo(@"%@: Uploaded progress: %f", weakSelf.class, progress);
              
              if (weakSelf.showsUploadingProgress)
              {
                  dispatch_async(dispatch_get_main_queue(), ^{
                      double tweakedProgress = (progress * 0.98f);
                      [weakSelf.uploadingAlertView setProgress:tweakedProgress animated:YES];
                  });
              }
          }
                            completionBlock:^(NSDictionary *sightingObj, NSError *error)
          {
#if DEBUG
              {
                  __weak __typeof(weakSelf.uploadingAlertView)weakUploadingAlertView = weakSelf.uploadingAlertView;
                  __weak __typeof(weakSelf.plainCompletionBlock)weakCompletionBlock = weakSelf.plainCompletionBlock;
                  //__weak __typeof(_avSound)weakAVSound = weakSelf.avSound;
                  double delayInSeconds = 3.0;
                  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                      DDLogWarn(@"Nil check? %@ (1001) [%@]", weakSelf == nil ? @"YES" : @"NO", @"IOUploadAPendingSightin");
                      //DDLogWarn(@"Nil check? %@ (1002) [%@]", weakAVSound == nil ? @"YES" : @"NO", @"AVSound");
                      DDLogWarn(@"Nil check? %@ (1003) [%@]", weakUploadingAlertView == nil ? @"YES" : @"NO", @"UploadingAlertView");
                      DDLogWarn(@"Nil check? %@ (1004) [%@]", weakCompletionBlock == nil ? @"YES" : @"NO", @"CompletionBlock");
                  });
              }
#endif
              DDLogInfo(@"%@: %@", weakSelf.class, sightingObj ? @"SUCCESS uploading." : @"FAILURE uploading.");
              
              weakSelf.shouldRevertStatusIfCancelled = NO;
              
              NSString *title = nil;
              NSString *message = nil;
              
              if (!sightingObj || [sightingObj[@"id"] isKindOfClass:[NSNull class]])
              {
                  DDLogError(@"%@: ERROR uploading a sighting. Malformed response? [%d]: %@", weakSelf.class, error.code, error.localizedDescription);
                  
                  sighting.status = @(IOSightingStatusSaved);
                  
                  if (weakSelf.showsUploadingProgress)
                  {
                      title = NSLocalizedString(@"Oopsie", @"");
                      message = NSLocalizedString(@"There was an error submitting your sighting. We'll try again in a little while.", @"");
                  }
              }
              else
              {
                  sighting.status = @(IOSightingStatusSynced);
                  sighting.sightingID = sightingObj[@"id"];
                  
                  if (weakSelf.showsUploadingProgress)
                  {
                      title = NSLocalizedString(@"Thank you", @"");
                      message = NSLocalizedString(@"Your sighting was successfully submitted to Redmap for review.", @"");
                  }
                  
                  [IOAudioPlayer playSuccess];
              }
              
              [IOCoreDataHelper faultObjectWithID:sighting.objectID inContext:weakSelf.context];
              
              if (weakSelf.showsUploadingProgress)
              {
                  dispatch_async(dispatch_get_main_queue(), ^{
                      //[weakSelf.uploadingAlertView setProgress:1.0f animated:NO];
                      [weakSelf.uploadingAlertView dismissWithClickedButtonIndex:weakSelf.uploadingAlertView.cancelButtonIndex animated:NO];
                      weakSelf.uploadingAlertView.delegate = nil;
                      weakSelf.uploadingAlertView = nil;
                      
                      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                                      message:message
                                                                     delegate:nil
                                                            cancelButtonTitle:NSLocalizedString(@"Dismiss", @"")
                                                            otherButtonTitles:nil];
                      [alert show];
                  });
              }
              
              completion();
      
#if DEBUG
    DDLogWarn(@"== END OF CALLBACK =====================================================>");
#endif
          }];
    
#if DEBUG
    DDLogWarn(@"-- END OF OPERATION ---------------------------------------------------->");
#endif
}

////////////////////////////////////////////////////////////////////////////////
- (void)callCompletionBlock
{
    logmethod();
    NSAssert(self.plainCompletionBlock, @"self.plainCompletionBlock");
    
#if DEBUG
    DDLogWarn(@"== COMPLETION CALLBACK =====================================================>");
#endif
    
    self.plainCompletionBlock();
    self.plainCompletionBlock = nil;
}

////////////////////////////////////////////////////////////////////////////////

@end
