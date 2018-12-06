//
//  IOUploadAPendingSighting.h
//  Redmap
//
//  Created by Evo Stamatov on 11/03/2014.
//  Copyright (c) 2014 Ionata. All rights reserved.
//

#import "IOConcurrentOperation.h"

typedef void (^SuccessBlock)(BOOL shouldScheduleANewCheck, NSManagedObjectID *nextSightingObjectID);


@interface IOUploadAPendingSighting : IOConcurrentOperation

@property (nonatomic, weak) NSManagedObjectContext *context;
@property (nonatomic, copy) NSManagedObjectID *sightingID;
@property (nonatomic, assign) BOOL showsUploadingProgress;
@property (nonatomic, strong) SuccessBlock successBlock;

@end
