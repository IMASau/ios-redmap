//
//  Photo.m
//  RedMap
//
//  Created by Evo Stamatov on 30/04/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOPhotoCollection.h"

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

@implementation IOPhoto

// Public

+ (UIImage *)getImageForUUID:(NSString *)UUID withIndex:(NSInteger)index
{
    logmethod();
    // TODO: generate images for different sizes and cache them to disk
    NSURL *filePath = [self photoPathForUUID:UUID withIndex:index];

    if (filePath)
        return [UIImage imageWithData:[NSData dataWithContentsOfURL:filePath]];

    return nil;
}



+ (UIImage *)getImageForUUID:(NSString *)UUID withIndex:(NSInteger)index forSize:(CGSize)size
{
    logmethod();
    UIImage *image = [self getImageForUUID:UUID withIndex:index];
    
    CGRect frame = (CGRect){CGPointZero, size};
    CGFloat sx = frame.size.width / image.size.width;
    CGFloat sy = frame.size.height / image.size.height;
    CGFloat s = fminf(sx, sy);
    frame.size.width = image.size.width * s;
    frame.size.height = image.size.height * s;
    
    static dispatch_once_t onceToken;
    static CGFloat screenScale = 1.0;
    dispatch_once(&onceToken, ^{
        screenScale = [[UIScreen mainScreen] scale];
    });
    
    if (image.size.width / screenScale > frame.size.width || image.size.height / screenScale > frame.size.height)
    {
        UIGraphicsBeginImageContextWithOptions(frame.size, YES, 0.0);
        [image drawInRect:frame];
        UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return resizedImage;
    }
    
    return image;
}



+ (NSURL *)saveImage:(UIImage *)image forUUID:(NSString *)UUID withIndex:(NSInteger)index error:(NSError **)error
{
    logmethod();
    NSError *dirError = nil;
    if ([self createDirectoryForUUID:UUID error:&dirError] == NO)
    {
        if (error != NULL)
            *error = dirError;
        return nil;
    }
    
    NSURL *filePath = [self photoPathForUUID:UUID withIndex:index];

    if (filePath)
    {
        NSData *data = UIImageJPEGRepresentation(image, 1);
        if ([data writeToURL:filePath atomically:YES] == YES)
            return filePath;
        
        if (error != NULL)
            *error = [NSError errorWithDomain:@"saveImage" code:200 userInfo:@{NSLocalizedFailureReasonErrorKey: @"Could not save the photo."}];
        return NO;
    }
    
    if (error != NULL)
        *error = [NSError errorWithDomain:@"saveImage" code:100 userInfo:@{NSLocalizedFailureReasonErrorKey: @"Could not get access to the directory."}];
    return NO;
}



+ (BOOL)removeImageForUUID:(NSString *)UUID withIndex:(NSInteger)index error:(NSError **)error
{
    logmethod();
    NSURL *filePath = [self photoPathForUUID:UUID withIndex:index];
    
    if (filePath)
    {
        NSError *fileError;
        if ([[NSFileManager defaultManager] removeItemAtURL:filePath error:&fileError] == NO)
        {
            if (error != NULL)
                *error = fileError;
            return NO;
        }
        else
            return YES;
    }
    
    if (error != NULL)
        *error = [NSError errorWithDomain:@"removeImage" code:100 userInfo:@{NSLocalizedFailureReasonErrorKey: @"Could not get access to the directory."}];
    return NO;
}



// Private

+ (NSURL *)directoryNameForUUID:(NSString *)UUID
{
    logmethod();
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *documentsDirectory = [[fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *libraryDirectory = [[fm URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
    
    NSURL *documentsUUIDURL = [documentsDirectory URLByAppendingPathComponent:UUID isDirectory:YES];
    //return documentsUUIDURL;
    
    NSURL *sightingsDirURL = [libraryDirectory URLByAppendingPathComponent:@"Sightings" isDirectory:YES];
    NSURL *libraryUUIDURL = [sightingsDirURL URLByAppendingPathComponent:UUID isDirectory:YES];
    
#warning Remove this check at some future version
    // Check if there are photos in the old (Documents) location and move them to the library
    if ([documentsUUIDURL checkResourceIsReachableAndReturnError:nil] == YES)
    {
        DDLogInfo(@"%@: Found Photos dir in Documents. Moving it to Library.", self.class);
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [fm createDirectoryAtURL:sightingsDirURL withIntermediateDirectories:YES attributes:nil error:nil];
        });
    
        if (![fm moveItemAtURL:documentsUUIDURL toURL:libraryUUIDURL error:nil])
            return documentsUUIDURL;
    }
    
    return libraryUUIDURL;
}



+ (NSURL *)directoryForUUID:(NSString *)UUID error:(NSError **)error
{
    logmethod();
    NSURL *uuidDir = [self directoryNameForUUID:UUID];
    
    NSError *dirError = nil;
    if ([uuidDir checkResourceIsReachableAndReturnError:&dirError] == NO)
    {
        if (error != NULL)
            *error = dirError;
        return nil;
    }
    
    return uuidDir;
}



+ (BOOL)createDirectoryForUUID:(NSString *)UUID error:(NSError **)error
{
    logmethod();
    NSURL *directoryURL = [self directoryNameForUUID:UUID];
    
    if (directoryURL)
    {
        NSError *dirError = nil;
        if ([[NSFileManager defaultManager] createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:&dirError] == NO)
        {
            if (error != NULL)
                *error = dirError;
            return NO;
        }
        else
            return YES;
    }
    
    return NO;
}



+ (BOOL)removeDirectoryForUUID:(NSString *)UUID error:(NSError **)error
{
    logmethod();
    NSError *dirError = nil;
    NSURL *directoryURL = [self directoryForUUID:UUID error:&dirError];
    
    if (directoryURL)
    {
        NSError *removeError = nil;
        
        if ([[NSFileManager defaultManager] removeItemAtURL:directoryURL error:&removeError] == NO)
        {
            if (error != NULL)
                *error = removeError;
            return NO;
        }
        else
            return YES;
    }
    
    if (error != NULL)
        *error = dirError;
    return NO;
}



+ (NSURL *)photoPathForUUID:(NSString *)UUID withIndex:(NSInteger)index
{
    logmethod();
    NSURL *uuidDir = [self directoryForUUID:UUID error:NULL];
    
    if (uuidDir)
        return [uuidDir URLByAppendingPathComponent:[NSString stringWithFormat:@"Photo-%d.jpg", index]];
    
    return nil;
}

@end






@interface IOPhotoCollection ()

@property (assign) NSUInteger counter;
//@property (nonatomic, assign, readwrite) NSInteger allPhotosSize;

@end


@implementation IOPhotoCollection

- (id)initWithUUID:(NSString *)UUID
{
    self = [super init];
    if (self)
    {
        logmethod();
        _photos = [NSArray array];
        _counter = 0;
        _uuid = UUID;
        //_allPhotosSize = -1;
    }
    return self;
}



- (id)init
{
    self = [self initWithUUID:nil];
    if (self)
    {
        logmethod();
    }
    return self;
}



- (void)setUuid:(NSString *)UUID
{
    logmethod();
    [self reSetTheUUID:UUID retainingPhotos:NO withCallback:nil];
}



- (void)reSetTheUUID:(NSString *)UUID retainingPhotos:(BOOL)retainPreviousPhotos withCallback:(void (^)(NSError *error))callback
{
    logmethod();
    if (!retainPreviousPhotos && _uuid && ![_uuid isEqualToString:UUID])
        [IOPhoto removeDirectoryForUUID:_uuid error:nil];
    
    _uuid = UUID;
    _photos = [NSArray array];
    _counter = 0;
    [self lookupForPhotosWithCallback:callback];
}



- (void)reSetTheUUID:(NSString *)UUID withCallback:(void (^)(NSError *error))callback
{
    logmethod();
    [self reSetTheUUID:UUID retainingPhotos:NO withCallback:callback];
}



- (BOOL)addPhotoObject:(UIImage *)image
{
    logmethod();
    NSURL *filePath = [IOPhoto saveImage:image forUUID:self.uuid withIndex:++self.counter error:NULL];
    
    if (filePath)
    {
        /*
        NSError *attributesError = nil;
        NSUInteger fileSize = 0;
        NSDictionary *atts = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath.path error:&attributesError];
        if (atts)
            fileSize = [@(atts.fileSize) unsignedIntegerValue];
        else
            DDLogError(@"%@: Error getting file attributes", self.class);
         */
        
        NSMutableArray *photos = [self.photos mutableCopy];
        [photos addObject:@{
            @"url": filePath,
            @"index": @(self.counter),
            //@"size": @(fileSize)
         }];
        _photos = (NSArray *)photos;
        return YES;
    }
    
    return NO;
}



- (BOOL)removePhotoObjectAtIndex:(NSInteger)index
{
    logmethod();
    NSDictionary *photoDict = self.photos[index];
    if ([IOPhoto removeImageForUUID:self.uuid withIndex:[photoDict[@"index"] integerValue] error:NULL])
    {
        NSMutableArray *photos = [self.photos mutableCopy];
        [photos removeObjectAtIndex:index];
        _photos = (NSArray *)photos;
        
        if ([photos count] == 0)
            [IOPhoto removeDirectoryForUUID:self.uuid error:nil];
        
        return YES;
    }

    return NO;
}



- (NSUInteger)count
{
    logmethod();
    return self.photos.count;
}



- (UIImage *)photoAtIndex:(NSUInteger)index
{
    logmethod();
    NSDictionary *photoDict = self.photos[index];
    return [IOPhoto getImageForUUID:self.uuid withIndex:[photoDict[@"index"] integerValue]];
}



- (UIImage *)photoAtIndex:(NSUInteger)index forSize:(CGSize)size
{
    logmethod();
    NSDictionary *photoDict = self.photos[index];
    return [IOPhoto getImageForUUID:self.uuid withIndex:[photoDict[@"index"] integerValue] forSize:size];
}



- (NSURL *)photoURLAtIndex:(NSInteger)index
{
    logmethod();
    NSDictionary *photoDict = self.photos[index];
    return [IOPhoto photoPathForUUID:self.uuid withIndex:[photoDict[@"index"] integerValue]];
}



/*
- (NSUInteger)photoSizeAtIndex:(NSInteger)index
{
    NSDictionary *photoDict = self.photos[index];
    return [photoDict[@"size"] unsignedIntegerValue];
}
 */



- (void)lookupForPhotosWithCallback:(void (^)(NSError *error))callback
{
    logmethod();
    NSError *dirError = nil;
    NSURL *dir = [IOPhoto directoryForUUID:self.uuid error:&dirError];
    if (!dir)
    {
        callback(dirError);
        return;
    }
    
    //self.allPhotosSize = -1;
    __weak IOPhotoCollection *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSDirectoryEnumerator *dirEnumerator = [[NSFileManager defaultManager] enumeratorAtURL:dir
                                                                    includingPropertiesForKeys:@[NSURLIsReadableKey, NSURLIsRegularFileKey]
                                                                                       options:NSDirectoryEnumerationSkipsSubdirectoryDescendants|NSDirectoryEnumerationSkipsHiddenFiles
                                                                                  errorHandler:nil];
        NSMutableArray *theArray = [NSMutableArray array];
        static NSString *jpgExtension = @"jpg";
        static NSString *photoPrefix = @"Photo-";
        
        for (NSURL *theURL in dirEnumerator)
        {
            NSNumber *isReadable;
            [theURL getResourceValue:&isReadable forKey:NSURLIsReadableKey error:NULL];
            
            NSNumber *isRegularFile;
            [theURL getResourceValue:&isRegularFile forKey:NSURLIsRegularFileKey error:NULL];
            
            // TODO: this is a bit over-complicated. Optimize it or re-do it!
            // Still, since it is in a dispatch_async call on a BACKGROUND queue it should be fine :)
            
            NSString *fileName = [[theURL path] lastPathComponent];
            NSString *name = [fileName stringByDeletingPathExtension];
            BOOL isJpegFileName = [[fileName pathExtension] caseInsensitiveCompare:jpgExtension] == NSOrderedSame;
            
            BOOL validFileName = [name hasPrefix:photoPrefix] && isJpegFileName;
            NSString *stringIndex;
            int theIndex;
            if (validFileName)
            {
                stringIndex = [name stringByReplacingOccurrencesOfString:photoPrefix withString:@""];
                NSScanner *sc = [NSScanner scannerWithString:stringIndex];
                if ([sc scanFloat:NULL] && [sc isAtEnd])
                    theIndex = [stringIndex intValue];
            }
            
            if ([isReadable boolValue] == YES && [isRegularFile boolValue] == YES && validFileName && index > 0)
            {
                /*
                NSError *attributesError = nil;
                NSUInteger fileSize = 0;
                NSDictionary *atts = [[NSFileManager defaultManager] attributesOfItemAtPath:theURL.path error:&attributesError];
                if (atts)
                {
                    weakSelf.allPhotosSize += atts.fileSize;
                    fileSize = [@(atts.fileSize) unsignedIntegerValue];
                }
                else
                    DDLogError(@"%@: Error getting file attributes", weakSelf.class);
                 */
                
                [theArray addObject:@{
                    @"url": theURL,
                    @"index": @(theIndex),
                    //@"size": @(fileSize)
                 }];
                weakSelf.counter = MAX(theIndex, weakSelf.counter);
            }
            else
            {
                DDLogInfo(@"%@: Deleting unsupported file at: %@", weakSelf.class, [theURL path]);
                
                NSError *fileError;
                if ([[NSFileManager defaultManager] removeItemAtURL:theURL error:&fileError] == NO)
                    DDLogWarn(@"%@: FAILED deleting file", weakSelf.class);
            }
            
        }
        
        __strong IOPhotoCollection *strongSelf = weakSelf;
        
        if ([theArray count] > 0 && strongSelf)
            strongSelf->_photos = (NSArray *)theArray;
        
        strongSelf = nil;
        
        if (callback)
            dispatch_async(dispatch_get_main_queue(), ^{
                // Maybe put some errors in the callback for isReadable/Deleted files and so on
                callback(nil);
            });
    });
}

@end