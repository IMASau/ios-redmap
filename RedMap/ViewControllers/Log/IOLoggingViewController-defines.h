//
//  IOLoggingViewController-defines.h
//  Redmap
//
//  Created by Evo Stamatov on 16/08/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#ifndef Redmap_IOLoggingViewController_defines_h
#define Redmap_IOLoggingViewController_defines_h

typedef NS_ENUM(NSInteger, IOMode) {
    IOModeDefault = (0x1 << 0),
    IOModeAdvanced = (0x1 << 1),
    IOModeSpeciesNotSet = (0x1 << 2),
    IOModeSpeciesSet = (0x1 << 3)
};

#define DEFAULT_MODE IOModeAdvanced // either IOModeDefault of IOModeAdvanced

#define kIOLVCRuntimeSettings   @"runTimeSettings"
//#define kIOLVCCached            @"cached"
#define kIOLVCCellID            @"cellID"
#define kIOLVCCellController    @"cellController"
#define kIOLVCVisibility        @"visibility"
#define kIOLVCItems             @"items"
#define kIOLVCManagedObjectKey  @"managedObjectKey"
#define kIOLVCManagedObjectKeys @"managedObjectKeys"
#define kIOLVCPlistDataSource   @"plistDataSource"
#define kIOLVCHeight            @"height"
#define kIOLVCConnectionInfo    @"connectionInfoDictionary"
#define kIOLVCNavigationTitle   @"navigationTitle"
#define kIOLVCSetDefaultValue   @"setDefaultValue"
#define kIOLVCAssignManagedObjectContextKey @"managedObjectContext"

#define kIOLVCRegionCellID           @"IORegionCellID"
#define kIOLVCSpeciesCellID          @"IOSpeciesCellID"
#define kIOLVCSpeciesSetCellID       @"IOSpeciesSetCellID"
#define kIOLVCDateCellID             @"IODateCellID"
#define kIOLVCTimeCellID             @"IOTimeCellID"
#define kIOLVCLocationCellID         @"IOLocationCellID"
#define kIOLVCActivityCellID         @"IOActivityCellID"
#define kIOLVCCountCellID            @"IOCountCellID"
#define kIOLVCWeightCellID           @"IOWeightCellID"
#define kIOLVCLengthCellID           @"IOLengthCellID"
#define kIOLVCGenderCellID           @"IOGenderCellID"
#define kIOLVCHabitatCellID          @"IOHabitatCellID"
#define kIOLVCDepthCellID            @"IODepthCellID"
#define kIOLVCWaterTemperatureCellID @"IOWaterTemperatureCellID"
#define kIOLVCCommentCellID          @"IOCommentCellID"

#define kIOLVCPhotoCollection        @"IOCollectionHandler"

#define kIOLVCCommonListingCellController @"IOCommonListingCellController"
#define kIOLVCRegionCellController        @"IORegionCellController"
#define kIOLVCSpeciesCellController       @"IOSpeciesCellController"
#define kIOLVCDateCellController          @"IODateCellController"
#define kIOLVCTimeCellController          @"IOTimeCellController"
#define kIOLVCLocationCellController      @"IOLocationCellController"
#define kIOLVCMeasurementCellController   @"IOMeasurementCellController"
#define kIOLVCCommentCellController       @"IOCommentCellController"

#endif
