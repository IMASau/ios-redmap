//
//  IOSpeciesCellController.m
//  Redmap
//
//  Created by Evo Stamatov on 16/08/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOSpeciesCellController.h"
#import "IOSpotTableViewController.h"
#import "IOSpeciesCell.h"
#import "Species.h"
#import "IOLoggingCellControllerKeys.h"
#import "AppDelegate.h"
#import "IOSpotKeys.h"

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface IOSpeciesCellController () <IOSpotTableViewControllerDelegate>
{
    NSString *_speciesKey;
    NSString *_categoryKey;
    NSString *_otherSpeciesKey;
    NSString *_otherSpeciesNameKey;
    NSString *_otherSpeciesCommonKey;
}

@property (nonatomic, weak) NSManagedObjectContext *managedObjectContext;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation IOSpeciesCellController

- (id)initWithSettings:(NSDictionary *)settings delegate:(id<IOBaseCellControllerDelegate>)delegate managedObjectContext:(NSManagedObjectContext *)context
{
    self = [super initWithSettings:settings delegate:delegate];
    if (self && self.managedObjectKeys)
    {
        _speciesKey = self.managedObjectKeys[kIOSpeciesSpeciesKey];
        _categoryKey = self.managedObjectKeys[kIOSpeciesCategoryKey];
        _otherSpeciesKey = self.managedObjectKeys[kIOSpeciesOtherSpeciesKey];
        _otherSpeciesNameKey = self.managedObjectKeys[kIOSpeciesOtherSpeciesNameKey];
        _otherSpeciesCommonKey = self.managedObjectKeys[kIOSpeciesOtherSpeciesCommonNameKey];
        _managedObjectContext = context;
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
- (void)didSelectTableViewCell:(IOBaseCell *)cell
{
#if TRACK
    [GoogleAnalytics sendEventWithCategory:@"uiAction" withAction:@"cellSelect" withLabel:self.settings[@"managedObjectKeys"][@"species"] withValue:@1];
#endif
    
    if (![self.delegate respondsToSelector:@selector(instantiateViewControllerWithIdentifier:)])
    {
        DDLogVerbose(@"%@: You should implement [instantiateViewControllerWithIdentifier:] in your delegate.", self.class);
        return;
    }
    
    IOSpotTableViewController *vc = [self.delegate instantiateViewControllerWithIdentifier:@"SpottersSBID"];
    vc.hideHomeButton = YES;
    //vc.hideRegionButton = YES;
    vc.context = self.managedObjectContext;
    vc.showAddSpeciesButton = YES;
    vc.delegate = self;
    
    if ([self.delegate respondsToSelector:@selector(setHidesBottomBarWhenPushed:)])
        [self.delegate setHidesBottomBarWhenPushed:YES];
    
    if ([self.delegate respondsToSelector:@selector(pushViewController:animated:)])
        [self.delegate pushViewController:vc animated:YES];
}

////////////////////////////////////////////////////////////////////////////////
- (void)updateCell:(IOSpeciesCell *)cell
{
    if (![cell isKindOfClass:[IOSpeciesCell class]])
        return;
    
    id speciesObj = [self.delegate getManagedObjectDataForKey:_speciesKey];
    
    if (speciesObj != nil)
    {
        Species *species = (Species *)speciesObj;
        
        cell.title.text = species.commonName;
        cell.subTitle.text = species.speciesName;
        
        // load the image
        
        if (species.pictureUrl && ![species.pictureUrl isEqualToString:@""])
        {
            __weak UIActivityIndicatorView *ai = cell.activityIndicator;
            __weak UIImageView *i = cell.image;
            
            ai.hidesWhenStopped = YES;
            [ai startAnimating];
            
            [ApplicationDelegate.imageEngine loadImageFromURL:species.pictureUrl successBlock:^(UIImage *image) {
                [ai stopAnimating];
                i.backgroundColor = nil;
                i.image = image;
                i.hidden = NO;
            } errorBlock:^(NSError *error, NSInteger statusCode) {
                [ai stopAnimating];
                DDLogError(@"%@: ERROR while loading image for species. StatusCode: %d. [%d]: %@", self.class, statusCode, error.code, error.localizedDescription);
            }];
        }
        else
        {
            cell.activityIndicator.hidden = YES;
            
            cell.image.image = nil;
            cell.image.hidden = YES;
        }
    }
    else if ([[self.delegate getManagedObjectDataForKey:_otherSpeciesKey] boolValue] == YES)
    {
        NSString *otherSpeciesName = [self.delegate getManagedObjectDataForKey:_otherSpeciesNameKey];
        NSString *otherSpeciesCommonName = [self.delegate getManagedObjectDataForKey:_otherSpeciesCommonKey];
        if (!otherSpeciesCommonName || [otherSpeciesCommonName isEqualToString:@""])
            cell.title.text = otherSpeciesName;
        else
        {
            cell.title.text = otherSpeciesCommonName;
            cell.subTitle.text = otherSpeciesName;
        }
        
        cell.activityIndicator.hidden = YES;
        
        cell.image.image = nil;
        cell.image.hidden = YES;
    }
}

////////////////////////////////////////////////////////////////////////////////
- (void)willDisplayTableViewCell:(IOBaseCell *)cell
{
    if (self.managedObjectKeys)
        [self updateCell:(IOSpeciesCell *)cell];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - IOSpotTableViewControllerDelegate Protocol

- (void)spotTableViewController:(UIViewController *)viewController category:(IOCategory *)category species:(Species *)species
{
    [self.delegate setManagedObjectDataWithKeyValueDictionary:@{
                                                 _categoryKey: category,
                                                  _speciesKey: species,
                                             _otherSpeciesKey: @NO,
                                         _otherSpeciesNameKey: [NSNull null],
                                       _otherSpeciesCommonKey: [NSNull null],
     }];
    
    [self.delegate enableSpeciesMode];
}

////////////////////////////////////////////////////////////////////////////////
- (void)spotTableViewController:(UIViewController *)viewController commonName:(NSString *)commonName latinName:(NSString *)latinName
{
    [self.delegate setManagedObjectDataWithKeyValueDictionary:@{
                                                 _categoryKey: [NSNull null],
                                                  _speciesKey: [NSNull null],
                                             _otherSpeciesKey: @YES,
                                         _otherSpeciesNameKey: latinName,
                                       _otherSpeciesCommonKey: commonName,
     }];
    
    [self.delegate enableSpeciesMode];
}

////////////////////////////////////////////////////////////////////////////////
- (void)spotTableViewControllerDidCancel:(UIViewController *)viewController
{
    if ([self.delegate respondsToSelector:@selector(setHidesBottomBarWhenPushed:)])
        [self.delegate setHidesBottomBarWhenPushed:NO];
}

@end
