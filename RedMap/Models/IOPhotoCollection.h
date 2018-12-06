//
//  IOPhotoCollection.h
//  RedMap
//
//  Created by Evo Stamatov on 30/04/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IOPhoto : NSObject

+ (NSURL *)saveImage:(UIImage *)image forUUID:(NSString *)UUID withIndex:(NSInteger)index error:(NSError **)error;
+ (UIImage *)getImageForUUID:(NSString *)UUID withIndex:(NSInteger)index;
+ (UIImage *)getImageForUUID:(NSString *)UUID withIndex:(NSInteger)index forSize:(CGSize)size;
+ (BOOL)removeImageForUUID:(NSString *)UUID withIndex:(NSInteger)index error:(NSError **)error;
+ (BOOL)removeDirectoryForUUID:(NSString *)UUID error:(NSError **)error;

@end


@interface IOPhotoCollection : NSObject

@property (readonly) NSArray *photos;
@property (nonatomic, copy) NSString *uuid;

- (NSUInteger)count;

- (id)initWithUUID:(NSString *)UUID;                                            // designited initializer

- (BOOL)addPhotoObject:(UIImage *)image;
- (BOOL)removePhotoObjectAtIndex:(NSInteger)index;

- (UIImage *)photoAtIndex:(NSUInteger)index;
- (UIImage *)photoAtIndex:(NSUInteger)index forSize:(CGSize)size;
- (NSURL *)photoURLAtIndex:(NSInteger)index;

// the following two methods work on a background thread and call the callback on the main thread
- (void)reSetTheUUID:(NSString *)UUID retainingPhotos:(BOOL)retainPreviousPhotos withCallback:(void (^)(NSError *error))callback;
- (void)reSetTheUUID:(NSString *)UUID withCallback:(void (^)(NSError *error))callback; // calls above method and assumes retainingPhotos:NO

@end