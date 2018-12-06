//
//  IOLoggingViewController.m
//  RedMap
//
//  Created by Evo Stamatov on 30/04/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOLoggingViewController.h"

#import "AppDelegate.h"
#import "IOAuth.h"
//#import "IOCategory.h"
#import "IOCollectionHandler.h"
#import "IOLoggingCellControllerKeys.h"
//#import "IOLoggingViewController-defines.h"
//#import "IOMainTabBarViewController.h"
#import "IORedMapThemeManager.h"
#import "IOSightingAttributesController.h"
//#import "IOSpotKeys.h"
#import "Sighting-typedefs.h"
#import "Sighting.h"
//#import "Species.h"
//#import "UIColor+IOColor.h"

#import "IOBaseCellController.h"
#import "IOSpeciesCellController.h"
#import "IOLocationCellController.h"
#import "IORegionCellController.h"

#import "User.h"
#import "IOCategory.h"
#import "Species.h"
#import "IOCoreDataHelper.h"

#define SET_TIME_AUTOMATICALLY 0
#define ALWAYS_MARK_REQUIRED_FIELDS 1

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface IOLoggingViewController () <IOCollectionHandlerDelegate, IOBaseCellControllerDelegate, IOSpeciesCellControllerDelegate, IOAuthControllerDelegate, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet IOCollectionHandler *collectionView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveSightingButton;
@property (weak, nonatomic) IBOutlet UIButton *resetButton;

@property (nonatomic, strong) NSMutableArray *cellConnectors;

@property (strong, nonatomic) UIBarButtonItem *advancedButton;
@property (assign) BOOL advancedMode;
@property (strong, nonatomic) NSArray *currentItems;
@property (assign, nonatomic) IOMode cellsMode;
@property (assign, nonatomic) IOMode cellsVisibilityMode;
@property (assign, nonatomic) IOMode speciesCellMode;
@property (strong, nonatomic) Sighting *loggingMO;
@property (strong, nonatomic) NSCalendar *calendar;
@property (strong, nonatomic) NSArray *currentlyVisibleSections;
@property (strong, nonatomic) NSManagedObjectID *sightingID;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation IOLoggingViewController
{
    BOOL _viewIsVisible;
    BOOL _justSetTheCategoryAndSpecies;
    BOOL _cellsModeObserverAdded;
    UIAlertView *_genericAlertView;
    UIAlertView *_loginAlertView;
    IOAuthController *_authController;
    
    NSManagedObjectContext *_context;
}


@synthesize speciesCellMode = _speciesCellMode;
@synthesize cellsVisibilityMode = _cellsVisibilityMode;

- (NSArray *)listingCellsArray
{
    static NSArray *listingCells;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        listingCells = @[
                       @{
                           kIOLVCVisibility: @(IOModeAdvanced|IOModeDefault),
                           kIOLVCItems:
                               @[
                                   @{
                                       kIOLVCCellID: kIOLVCRegionCellID,
                                       kIOLVCCellController: @"IORegionCellController",
                                       kIOLVCVisibility: @(IOModeAdvanced),
                                       kIOLVCRuntimeSettings: @{
                                               kIOLVCManagedObjectKey: kIOSightingPropertyRegion,
                                               kIOLVCPlistDataSource: kIOSightingCategoryRegion,
                                               },
                                       },
                                   @{
                                       kIOLVCCellID: kIOLVCSpeciesCellID,
                                       kIOLVCCellController: @"IOSpeciesCellController",
                                       kIOLVCVisibility: @(IOModeSpeciesNotSet),
                                       kIOLVCRuntimeSettings: @{
                                               kIOSpeciesInitialSpeciesCell: @YES,
                                               kIOLVCManagedObjectKeys: @{
                                                       kIOSpeciesSpeciesKey: kIOSightingPropertySpecies,
                                                       kIOSpeciesCategoryKey: kIOSightingPropertyCategory,
                                                       kIOSpeciesOtherSpeciesKey: kIOSightingPropertyOtherSpecies,
                                                       kIOSpeciesOtherSpeciesNameKey: kIOSightingPropertyOtherSpeciesName,
                                                       kIOSpeciesOtherSpeciesCommonNameKey: kIOSightingPropertyOtherSpeciesCommonName,
                                                       },
                                               },
                                   },
                                   @{
                                       kIOLVCCellID: kIOLVCSpeciesSetCellID,
                                       kIOLVCCellController: @"IOSpeciesCellController",
                                       kIOLVCVisibility: @(IOModeSpeciesSet),
                                       kIOLVCHeight: @54,
                                       kIOLVCRuntimeSettings: @{
                                               kIOSpeciesInitialSpeciesCell: @NO,
                                               kIOLVCManagedObjectKeys: @{
                                                   kIOSpeciesSpeciesKey: kIOSightingPropertySpecies,
                                                   kIOSpeciesCategoryKey: kIOSightingPropertyCategory,
                                                   kIOSpeciesOtherSpeciesKey: kIOSightingPropertyOtherSpecies,
                                                   kIOSpeciesOtherSpeciesNameKey: kIOSightingPropertyOtherSpeciesName,
                                                   kIOSpeciesOtherSpeciesCommonNameKey: kIOSightingPropertyOtherSpeciesCommonName,
                                                   },
                                               },
                                       },
                                   ],
                           },
                       
                       @{
                           kIOLVCVisibility: @(IOModeAdvanced|IOModeDefault),
                           kIOLVCItems:
                               @[
                                   @{
                                       kIOLVCCellID: kIOLVCDateCellID,
                                       kIOLVCCellController: @"IODateCellController",
                                       kIOLVCVisibility: @(IOModeAdvanced),
                                       kIOLVCRuntimeSettings: @{
                                               kIOLVCManagedObjectKey: kIOSightingPropertyDateSpotted,
                                               },
                                       },
                                   @{
                                       kIOLVCCellID: kIOLVCTimeCellID,
                                       kIOLVCCellController: @"IOTimeCellController",
                                       kIOLVCVisibility: @(IOModeAdvanced),
                                       kIOLVCRuntimeSettings: @{
                                               kIOLVCManagedObjectKeys: @{
                                                       kIOTimeDateKey: kIOSightingPropertyDateSpotted,
                                                       kIOTimeTimeKey: kIOSightingPropertyTime,
                                                       kIOTimeTimeNotSureKey: kIOSightingPropertyTimeNotSure,
                                                       },
                                               kIOLVCPlistDataSource: kIOSightingCategoryTime,
                                               },
                                       },
                                   @{
                                       kIOLVCCellID: kIOLVCLocationCellID,
                                       kIOLVCCellController: @"IOLocationCellController",
                                       kIOLVCVisibility: @(IOModeAdvanced|IOModeDefault),
                                       kIOLVCRuntimeSettings: @{
                                               kIOLVCManagedObjectKeys: @{
                                                       kIOLocationLatitudeKey: kIOSightingPropertyLocationLat,
                                                       kIOLocationLongitudeKey: kIOSightingPropertyLocationLng,
                                                       kIOLocationAccuracyKey: kIOSightingPropertyLocationAccuracy,
                                                       kIOLocationAccuracyCategoryKey: kIOSightingCategoryAccuracy,
                                                       kIOLocationStatusKey: kIOSightingPropertyLocationStatus,
                                                       kIOLocationRegionKey: kIOSightingPropertyRegion,
                                                       }
                                               },
                                       },
                                   @{
                                       kIOLVCCellID: kIOLVCActivityCellID,
                                       kIOLVCCellController: @"IOCommonListingCellController",
                                       kIOLVCVisibility: @(IOModeAdvanced|IOModeDefault),
                                       kIOLVCRuntimeSettings: @{
                                               kIOLVCSetDefaultValue: @YES,
                                               kIOLVCManagedObjectKey: kIOSightingPropertyActivity,
                                               kIOLVCPlistDataSource: kIOSightingCategoryActivity,
                                               },
                                       },
                                   ],
                           },
                       
                       @{
                           kIOLVCVisibility: @(IOModeAdvanced),
                           kIOLVCItems:
                               @[
                                   @{
                                       kIOLVCCellID: kIOLVCCountCellID,
                                       kIOLVCCellController: @"IOCommonListingCellController",
                                       kIOLVCVisibility: @(IOModeAdvanced),
                                       kIOLVCRuntimeSettings: @{
                                               kIOLVCSetDefaultValue: @YES,
                                               kIOLVCManagedObjectKey: kIOSightingPropertySpeciesCount,
                                               kIOLVCPlistDataSource: kIOSightingCategoryCount,
                                               },
                                       },
                                   @{
                                       kIOLVCCellID: kIOLVCWeightCellID,
                                       kIOLVCCellController: @"IOMeasurementCellController",
                                       kIOLVCVisibility: @(IOModeAdvanced),
                                       kIOLVCRuntimeSettings: @{
                                               kIOLVCManagedObjectKeys: @{
                                                       kIOMeasurementValueKey: kIOSightingPropertySpeciesWeight,
                                                       kIOMeasurementMethodKey: kIOSightingPropertySpeciesWeightMethod,
                                                       kIOMeasurementMethodCategoryKey: kIOSightingCategoryWeightMethod,
                                                       },
                                               kIOLVCPlistDataSource: kIOSightingCategoryCount,
                                               kIOMeasurementTitleKey: @"Weight",
                                               kIOMeasurementUnitsKey: @"kg",
                                               },
                                       },
                                   @{
                                       kIOLVCCellID: kIOLVCLengthCellID,
                                       kIOLVCCellController: @"IOMeasurementCellController",
                                       kIOLVCVisibility: @(IOModeAdvanced),
                                       kIOLVCRuntimeSettings: @{
                                               kIOLVCManagedObjectKeys: @{
                                                       kIOMeasurementValueKey: kIOSightingPropertySpeciesLength,
                                                       kIOMeasurementMethodKey: kIOSightingPropertySpeciesLengthMethod,
                                                       kIOMeasurementMethodCategoryKey: kIOSightingCategorySizeMethod,
                                                       },
                                               kIOLVCPlistDataSource: kIOSightingCategoryCount,
                                               kIOMeasurementTitleKey: @"Size",
                                               kIOMeasurementUnitsKey: @"cm",
                                               },
                                       },
                                   @{
                                       kIOLVCCellID: kIOLVCGenderCellID,
                                       kIOLVCCellController: @"IOCommonListingCellController",
                                       kIOLVCVisibility: @(IOModeAdvanced),
                                       kIOLVCRuntimeSettings: @{
                                               kIOLVCSetDefaultValue: @YES,
                                               kIOLVCManagedObjectKey: kIOSightingPropertySpeciesSex,
                                               kIOLVCPlistDataSource: kIOSightingCategoryGender,
                                               },
                                       },
                                   @{
                                       kIOLVCCellID: kIOLVCHabitatCellID,
                                       kIOLVCCellController: @"IOCommonListingCellController",
                                       kIOLVCVisibility: @(IOModeAdvanced),
                                       kIOLVCRuntimeSettings: @{
                                               kIOLVCSetDefaultValue: @YES,
                                               kIOLVCManagedObjectKey: kIOSightingPropertySpeciesHabitat,
                                               kIOLVCPlistDataSource: kIOSightingCategoryHabitat,
                                               },
                                       },
                                   ],
                           },
                       
                       @{
                           kIOLVCVisibility: @(IOModeAdvanced),
                           kIOLVCItems:
                               @[
                                   @{
                                       kIOLVCCellID: kIOLVCDepthCellID,
                                       kIOLVCCellController: @"IOMeasurementCellController",
                                       kIOLVCVisibility: @(IOModeAdvanced),
                                       kIOLVCRuntimeSettings: @{
                                               kIOLVCManagedObjectKey: kIOSightingPropertyDepth,
                                               kIOMeasurementTitleKey: @"Depth",
                                               kIOMeasurementUnitsKey: @"m",
                                               kIOLVCNavigationTitle: @"Depth in metres",
                                               kIOMeasurementPlaceholderKey: @"Depth in metres",
                                               //kIOMeasurementVisibleNegativeSwitch: @YES,
                                               },
                                       },
                                   @{
                                       kIOLVCCellID: kIOLVCWaterTemperatureCellID,
                                       kIOLVCCellController: @"IOMeasurementCellController",
                                       kIOLVCVisibility: @(IOModeAdvanced),
                                       kIOLVCRuntimeSettings: @{
                                               kIOLVCManagedObjectKey: kIOSightingPropertyWaterTemperature,
                                               kIOMeasurementTitleKey: @"Temperature",
                                               kIOMeasurementUnitsKey: @"ºC",
                                               //kIOMeasurementVisibleNegativeSwitch: @YES,
                                               },
                                       },
                                   ],
                           },
                       
                       @{
                           kIOLVCVisibility: @(IOModeAdvanced|IOModeDefault),
                           kIOLVCItems:
                               @[
                                   @{
                                       kIOLVCCellID: kIOLVCCommentCellID,
                                       kIOLVCCellController: @"IOCommentCellController",
                                       kIOLVCVisibility: @(IOModeAdvanced|IOModeDefault),
                                       kIOLVCHeight: @84,
                                       kIOLVCRuntimeSettings: @{
                                               kIOLVCManagedObjectKey: kIOSightingPropertyComment,
                                               },
                                       },
                                   ],
                           },
                       ];
    });
    return listingCells;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
    logmethod();
        _context = [[IOCoreDataHelper sharedInstance] logContext];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)viewDidLoad
{
    logmethod();
    DDLogVerbose(@"%@: View did load", self.class);
    [super viewDidLoad];
    
    [self setupTracking];
    [self setupCellVisibilityMode];
    [self setupCollectionView];
    [self setupTheme];
    [self setupResetButton];
    [self setupRefreshControl];
    
}

////////////////////////////////////////////////////////////////////////////////
- (void)didReceiveMemoryWarning
{
    logmethod();
    DDLogVerbose(@"%@: Did recieve memory warning", self.class);
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

////////////////////////////////////////////////////////////////////////////////
- (void)dealloc
{
    logmethod();
    DDLogWarn(@"%@: Deallocating", self.class);
    
    if (_cellsModeObserverAdded)
        [self removeObserver:self forKeyPath:@"cellsMode"];
}

////////////////////////////////////////////////////////////////////////////////
- (void)viewWillAppear:(BOOL)animated
{
    logmethod();
    DDLogVerbose(@"%@: View will appear", self.class);
    [super viewWillAppear:animated];
    
#if TRACK
    [GoogleAnalytics sendView:@"Log view"];
#endif

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    self.hidesBottomBarWhenPushed = NO;
    
    _viewIsVisible = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    logmethod();
    _viewIsVisible = YES;
    
    if (_justSetTheCategoryAndSpecies)
    {
        //self.speciesCellMode = IOModeSpeciesSet;
        [self updateCellConnectors];
        //[self resetCellControllerForCellID:kIOLVCSpeciesSetCellID];
        [self.tableView reloadData];
        _justSetTheCategoryAndSpecies = NO;
    }
    
#if ALWAYS_MARK_REQUIRED_FIELDS
    [self markRequiredFieldsEvenIfNotDirty:YES];
#endif
    
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    logmethod();
    [super viewWillDisappear:animated];
    _viewIsVisible = NO;
}

- (void)viewDidDisappear:(BOOL)animated
{
    logmethod();
    DDLogVerbose(@"%@: View did disappear", self.class);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [IOCoreDataHelper saveContextHierarchy:_context];
    
    [super viewDidDisappear:animated];
}

- (void)applicationDidEnterBackground
{
    logmethod();
    DDLogVerbose(@"%@: Application did enter background", self.class);
    
    [IOCoreDataHelper saveContextHierarchy:_context];
    
    if (_genericAlertView)
    {
        [_genericAlertView dismissWithClickedButtonIndex:_genericAlertView.cancelButtonIndex animated:NO];
        _genericAlertView.delegate = nil;
        _genericAlertView = nil;
    }
    
    if (_authController)
    {
        [self dismissViewControllerAnimated:NO completion:nil];
        _authController.delegate = nil;
        _authController = nil;
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Getters and Setters

- (NSCalendar *)calendar
{
    if (_calendar == nil)
        _calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    return _calendar;
}

////////////////////////////////////////////////////////////////////////////////
- (void)setCellsMode:(IOMode)cellsMode
{
    if (cellsMode != _cellsMode)
    {
        [self willChangeValueForKey:@"cellsMode"];
        
        _cellsMode = cellsMode;
        self.currentlyVisibleSections = nil;
        /*
        IOLog(@"New cells mode: %d", _cellsMode);
        IOLog(@"IOModeDefault:  %@", ((_cellsMode & IOModeDefault) != NO) ? @"Y": @"N");
        IOLog(@"IOModeAdvanced: %@", ((_cellsMode & IOModeAdvanced) != NO) ? @"Y": @"N");
        IOLog(@"IOModeSpeciesNotSet: %@", ((_cellsMode & IOModeSpeciesNotSet) != NO) ? @"Y": @"N");
        IOLog(@"IOModeSpeciesSet:    %@", ((_cellsMode & IOModeSpeciesSet) != NO) ? @"Y": @"N");
         */
        
        [self didChangeValueForKey:@"cellsMode"];
        
        if (_viewIsVisible)
            [self.tableView reloadData];
    }
}

////////////////////////////////////////////////////////////////////////////////
- (IOMode)cellsVisibilityMode
{
    if (_cellsVisibilityMode != IOModeDefault && _cellsVisibilityMode != IOModeAdvanced)
        _cellsVisibilityMode = DEFAULT_MODE;
    
    return _cellsVisibilityMode;
}

////////////////////////////////////////////////////////////////////////////////
- (IOMode)speciesCellMode
{
    if (_speciesCellMode != IOModeSpeciesNotSet && _speciesCellMode != IOModeSpeciesSet)
        _speciesCellMode = IOModeSpeciesNotSet;
    
    return _speciesCellMode;
}

////////////////////////////////////////////////////////////////////////////////
- (void)setSpeciesCellMode:(IOMode)speciesCellMode
{
    if (speciesCellMode != _speciesCellMode)
    {
        [self willChangeValueForKey:@"speciesCellMode"];
        
        _speciesCellMode = speciesCellMode;
        
        self.cellsMode = self.cellsVisibilityMode | _speciesCellMode;
        
        [self didChangeValueForKey:@"speciesCellMode"];
        
        //IOLog(@"New species mode: %d", _speciesCellMode);
    }
}

////////////////////////////////////////////////////////////////////////////////
- (void)setCellsVisibilityMode:(IOMode)cellsVisibilityMode
{
    if (cellsVisibilityMode != _cellsVisibilityMode)
    {
        [self willChangeValueForKey:@"cellsVisibilityMode"];
        
        _cellsVisibilityMode = cellsVisibilityMode;
        
        self.cellsMode = _cellsVisibilityMode | self.speciesCellMode;
        
        [self didChangeValueForKey:@"cellsVisibilityMode"];
        
        //IOLog(@"New cells mode: %d", _cellsVisibilityMode);
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Observers

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"cellsMode"])
    {
        //IOLog(@"OBSERVED CHANGE IN CURRENT MODE");
        [self updateCellConnectors];
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark IOSpeciesCellControllerDelegate

- (BOOL)enableSpeciesMode
{
    if ((self.loggingMO.species && self.loggingMO.category) || [self.loggingMO.otherSpecies boolValue] == YES)
    {
        _justSetTheCategoryAndSpecies = YES;
        self.speciesCellMode = IOModeSpeciesSet;
        return YES;
    }
    
    return NO;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Mode aware filtering

- (NSArray *)filterArray:(NSArray *)array forVisibilityMode:(NSInteger)mode
{
    NSMutableArray *filteredArray = [NSMutableArray array];
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj objectForKey:kIOLVCVisibility])
        {
            NSInteger itemVisibilityMode = (NSInteger)[[obj objectForKey:kIOLVCVisibility] integerValue];
            if ((itemVisibilityMode & mode) == NO)
                return;
        }
        
        NSArray *visibleItems = [NSArray array];
        if ([obj objectForKey:kIOLVCItems])
        {
            NSArray *items = [obj objectForKey:kIOLVCItems];
            visibleItems = [self filterArray:items forVisibilityMode:mode];
            if (visibleItems.count == 0)
                return;
        }
        else
        {
            [filteredArray addObject:obj];
            return;
        }
        
        [filteredArray addObject:visibleItems];
    }];
    
    return [filteredArray copy];
}

////////////////////////////////////////////////////////////////////////////////
- (NSArray *)currentlyVisibleSections
{
    if (_currentlyVisibleSections == nil)
        _currentlyVisibleSections = [self filterArray:[self listingCellsArray] forVisibilityMode:self.cellsMode];
    return _currentlyVisibleSections;
}

////////////////////////////////////////////////////////////////////////////////
- (NSArray *)cellObjectsForSection:(NSInteger)section
{
    return (NSArray *)[self.currentlyVisibleSections objectAtIndex:section];
}

////////////////////////////////////////////////////////////////////////////////
- (NSDictionary *)cellObjectForIndexPath:(NSIndexPath *)indexPath
{
    NSArray *visibleRows = [self cellObjectsForSection:indexPath.section];
    if (visibleRows.count > 0)
        return visibleRows[indexPath.row];
    
    return nil;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - UITableViewDataSource Protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self currentlyVisibleSections] count];
}

////////////////////////////////////////////////////////////////////////////////
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self cellObjectsForSection:section] count];
}

////////////////////////////////////////////////////////////////////////////////
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *cellObject = [self cellObjectForIndexPath:indexPath];
    NSString *cellIdentifier = [cellObject valueForKey:kIOLVCCellID];

    IOBaseCell *cell = (IOBaseCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    id <IOCellControllerConnection> cellController = [self cellControllerForCellID:cellIdentifier];
    [cellController configureTableViewCell:cell];
    
    return cell;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - UITableViewDelegate Protocol

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    IOBaseCell *cell = (IOBaseCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    
    id <IOCellControllerConnection> cellController = [self cellControllerForCellID:[cell reuseIdentifier]];
    if ([cellController respondsToSelector:@selector(didSelectTableViewCell:)])
        [cellController didSelectTableViewCell:cell];
}

////////////////////////////////////////////////////////////////////////////////
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *cellData = [self cellObjectsForSection:indexPath.section][indexPath.row];
    CGFloat cellHeight = [[cellData objectForKey:@"height"] floatValue];
    if (cellHeight > 0.001)
        return cellHeight;
    
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

////////////////////////////////////////////////////////////////////////////////
- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)aCell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    IOBaseCell *cell = (IOBaseCell *)aCell;
    
    id <IOCellControllerConnection> cellController = [self cellControllerForCellID:[cell reuseIdentifier]];
    if ([cellController respondsToSelector:@selector(didEndDisplayingTableViewCell:)])
        [cellController didEndDisplayingTableViewCell:cell];
}

////////////////////////////////////////////////////////////////////////////////
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)aCell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    IOBaseCell *cell = (IOBaseCell *)aCell;
    
    id <IOCellControllerConnection> cellController = [self cellControllerForCellID:[cell reuseIdentifier]];
    if ([cellController respondsToSelector:@selector(willDisplayTableViewCell:)])
        [cellController willDisplayTableViewCell:cell];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    logmethod();
    //self.hidesBottomBarWhenPushed = YES;

    if ([sender isKindOfClass:[IOBaseCell class]])
    {
        IOBaseCell *cell = (IOBaseCell *)sender;
        id <IOCellControllerConnection> cellController = [self cellControllerForCellID:[cell reuseIdentifier]];
        if (cellController)
            [cellController prepareForSegue:segue sender:sender];
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark Unwind actions

- (IBAction)done:(UIStoryboardSegue *)segue
{
    logmethod();
    self.hidesBottomBarWhenPushed = NO;
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

////////////////////////////////////////////////////////////////////////////////
- (IBAction)cancel:(UIStoryboardSegue *)segue
{
    logmethod();
    self.hidesBottomBarWhenPushed = NO;
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

////////////////////////////////////////////////////////////////////////////////
- (IBAction)goToLoggingRoot:(UIStoryboardSegue *)segue
{
    logmethod();
    // TODO: coming back from the Species sub-view doesn't bring back the bottom tab bar
    self.hidesBottomBarWhenPushed = NO;
    
    //IOLog(@"Called goToLoggingRoot: unwind action");
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - IOBaseCellController delegate

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    logmethod();
    [self.navigationController pushViewController:viewController animated:animated];
}

////////////////////////////////////////////////////////////////////////////////
- (id)instantiateViewControllerWithIdentifier:(NSString *)identifier
{
    logmethod();
    return [self.storyboard instantiateViewControllerWithIdentifier:identifier];
}

////////////////////////////////////////////////////////////////////////////////
- (id)getManagedObjectDataForKey:(NSString *)key
{
    id value = [self.loggingMO valueForKey:key];
    //IOLog(@"<<< loggedMO.%@: %@", key, value);
    return value;
}

////////////////////////////////////////////////////////////////////////////////
- (void)setManagedObjectDataWithKeyValueDictionary:(NSDictionary *)dictionary
{
    logmethod();
    __weak __typeof(self)weakSelf = self;
    NSMutableDictionary *oldValues = [NSMutableDictionary dictionary];
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        id oldValue = [weakSelf.loggingMO valueForKey:key];
        if (oldValue == nil)
            oldValue = [NSNull null];
        [oldValues setObject:oldValue forKey:key];
    }];
    
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        //IOLog(@">>> loggedMO.%@ = %@", key, obj);
        
        if ([obj isKindOfClass:[NSNull class]])
            [weakSelf.loggingMO setValue:nil forKey:key];
        else
            [weakSelf.loggingMO setValue:obj forKey:key];
    }];
    
    NSError *validationError = nil;
    if (![self.loggingMO validateForUpdate:&validationError])
    {
        DDLogError(@"%@: ERROR validating sighting update. Reverting.", self.class);
#if DEBUG
        DDLogError(@"%@", validationError);
#endif
        [oldValues enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if ([obj isKindOfClass:[NSNull class]])
                [weakSelf.loggingMO setValue:nil forKey:key];
            else
                [weakSelf.loggingMO setValue:obj forKey:key];
        }];
        
        NSString *title = NSLocalizedStringWithDefaultValue(@"redmap.log.error.invalid-value.title", nil, [NSBundle mainBundle], @"Invalid value", @"Alert view title when the user enters an invalid value for a sighting");
        NSString *message = NSLocalizedStringWithDefaultValue(@"redmap.log.error.invalid-value.message", nil, [NSBundle mainBundle], @"The entered value is invalid. Reverted to the previous one.", @"Alert view message");
        NSString *cancelButtonTitle = NSLocalizedStringWithDefaultValue(@"redmap.log.error.invalid-value.cancelTitle", nil, [NSBundle mainBundle], @"Ok", @"Alert view cancel button title");
        _genericAlertView = [[UIAlertView alloc] initWithTitle:title
                                                       message:message
                                                      delegate:self
                                             cancelButtonTitle:cancelButtonTitle
                                             otherButtonTitles:nil];
        [_genericAlertView show];
    }
    
    self.loggingMO.dateModified = [NSDate date];
    [IOCoreDataHelper faultObjectWithID:weakSelf.loggingMO.objectID inContext:_context];
    
    [self markRequiredFieldsEvenIfNotDirty:NO];
}

////////////////////////////////////////////////////////////////////////////////
- (void)setManagedObjectDataForKey:(NSString *)key withObject:(id)object
{
    if (object == nil)
        [self setManagedObjectDataWithKeyValueDictionary:@{key: [NSNull null]}];
    else
        [self setManagedObjectDataWithKeyValueDictionary:@{key: object}];
}

////////////////////////////////////////////////////////////////////////////////
- (NSArray *)failedValidationFieldsCellIdentifiers
{
    logmethod();
    NSMutableArray *failedValidationFields = [NSMutableArray arrayWithCapacity:6];
    
    // Photo
    if ([self.loggingMO.photosCount integerValue] <= 0)
        [failedValidationFields addObject:kIOLVCPhotoCollection];

    // Region
    if (self.loggingMO.region == nil)
        [failedValidationFields addObject:kIOLVCRegionCellID];
    
    // Category & Species
    if (self.loggingMO.species == nil && [self.loggingMO.otherSpecies boolValue] == NO)
    {
        [failedValidationFields addObject:kIOLVCSpeciesCellID];
        [failedValidationFields addObject:kIOLVCSpeciesSetCellID];
    }
    
    // Date
    if (self.loggingMO.dateSpotted == nil)
        [failedValidationFields addObject:kIOLVCDateCellID];
    
    // Time
    if (self.loggingMO.time == nil)
        [failedValidationFields addObject:kIOLVCTimeCellID];
    
    // Location
    if ([self.loggingMO.locationStatus integerValue] == IOSightingLocationStatusNotSet)
        [failedValidationFields addObject:kIOLVCLocationCellID];
    
    // Activity
    if (self.loggingMO.activity == nil)
        [failedValidationFields addObject:kIOLVCActivityCellID];
    
    // Count
    if (self.loggingMO.speciesCount == nil)
        [failedValidationFields addObject:kIOLVCCountCellID];
    
    /*
    // Weight & Weight Method
    if (self.loggingMO.speciesWeight == nil || self.loggingMO.speciesWeightMethod == nil)
        [failedValidationFields addObject:kIOLVCWeightCellID];
    
    // Size & Size Method
    if (self.loggingMO.speciesLength == nil || self.loggingMO.speciesLengthMethod == nil)
        [failedValidationFields addObject:kIOLVCLengthCellID];
     */
    
    // Sex
    if (self.loggingMO.speciesSex == nil)
        [failedValidationFields addObject:kIOLVCGenderCellID];
    
    /*
    // Habitat
    if (self.loggingMO.speciesHabitat == nil)
        [failedValidationFields addObject:kIOLVCHabitatCellID];
     */
    
    return (NSArray *)failedValidationFields;
}



#pragma mark - Setup Managed Object Context

- (Sighting *)loggingMO
{
    if (_loggingMO == nil)
    {
    logmethod();
#warning NOTE TO SELF - use IOSightingsController
        
        NSString *entityName = @"Sighting";
        
        NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:_context];
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:entity];
        [fetchRequest setFetchBatchSize:20];
        
        // Sorting
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dateModified" ascending:YES];
        NSArray *sortDescriptors = @[sortDescriptor];
        [fetchRequest setSortDescriptors:sortDescriptors];
        
        // Select only Drafts
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(status == %@)", @(IOSightingStatusDraft)]];
        //[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(status == %@)", @(IOSightingStatusSaved)]];

        NSError *error = nil;
        NSArray *result = [_context executeFetchRequest:fetchRequest error:&error];
        
        NSDate *now = [NSDate date];
        
        if (!error && [result count] > 0)
        {
            _loggingMO = [result lastObject];
            _loggingMO.dateModified = now;
            //DDLogError(@"%@", _loggingMO.status);
            
            if ((_loggingMO.species && _loggingMO.category) || [_loggingMO.otherSpecies boolValue])
                self.speciesCellMode = IOModeSpeciesSet;
            else
                self.speciesCellMode = IOModeSpeciesNotSet;
            
            self.navigationItem.title = NSLocalizedString(@"Unsaved Sighting", @"NavigationViewController title. When a saved sighting is loaded from the DB");
        }
        else
        {
            _loggingMO = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:_context];
            _loggingMO.status = @(IOSightingStatusDraft);
            _loggingMO.user = nil;
            
            _loggingMO.uuid = [[NSUUID UUID] UUIDString];
            //IOLog(@"UUID is %@", _loggingMO.uuid);
            
            NSDateComponents *dateComponents = [self.calendar components:
                                                NSYearCalendarUnit|
                                                NSMonthCalendarUnit|
                                                NSDayCalendarUnit|
                                                NSHourCalendarUnit|
                                                NSMinuteCalendarUnit
                                                                fromDate:now];
            
            // Get current time, but null out the minutes and seconds
            if (dateComponents.minute >= 30)
                dateComponents.hour += 1;
            dateComponents.minute = 0;
            
            IOSightingAttributesController *sa = [IOSightingAttributesController sharedInstance];
            
            _loggingMO.dateSpotted = [self.calendar dateFromComponents:dateComponents];
            _loggingMO.dateCreated = now;
            _loggingMO.dateModified = now;
#if SET_TIME_AUTOMATICALLY
            _loggingMO.time = [[IOSightingAttributesController sharedInstance] timeEntryFromValue:@([dateComponents hour])];
            _loggingMO.timeNotSure = @NO;
#else
            _loggingMO.time = [sa defaultTime];
            _loggingMO.timeNotSure = @([_loggingMO.time isEqual:[sa timeEntryFromValue:@(-1)]]);
#endif
            
            _loggingMO.speciesSex = [sa defaultGender];
            _loggingMO.activity = [sa defaultActivity];
            _loggingMO.speciesCount = [sa defaultCount];
            _loggingMO.speciesHabitat = [sa defaultHabitat];
            
            _loggingMO.locationStatus = @(IOSightingLocationStatusNotSet);
            
            self.speciesCellMode = IOModeSpeciesNotSet;
            
            self.navigationItem.title = NSLocalizedString(@"New Sighting", @"NavigationViewController title. When a new sighting is created");
        }
    }
    return _loggingMO;
}



#pragma mark - IOCollectionHandlerDelegate delegate

- (UITabBar *)theTabBar
{
    return self.tabBarController.tabBar;
}



#pragma mark - IBActions

- (IBAction)saveSighting:(id)sender
{
    logmethod();
    DDLogVerbose(@"%@: Saving a sighting", self.class);
    
    if ([[self failedValidationFieldsCellIdentifiers] count] > 0)
    {
        DDLogError(@"%@: ERROR validating the sighting", self.class);
        NSString *title = NSLocalizedString(@"Some fields are not set", @"UIAlertView title when user hasn't set all required fields, but clicked Save");
        NSString *message = NSLocalizedString(@"Please, fill in or set the marked fields", @"UIAlertView message when user hasn't set all required fields, but clicked Save");
        _genericAlertView = [[UIAlertView alloc] initWithTitle:title
                                                       message:message
                                                      delegate:nil
                                             cancelButtonTitle:NSLocalizedString(@"Dismiss", @"")
                                             otherButtonTitles:nil];
        [_genericAlertView show];
        [self markRequiredFieldsAndScrollToTop:YES];
        return;
    }
    
    NSError *validationError = nil;
    if (![IOAuth validateSightingForSubmission:self.loggingMO error:&validationError])
    {
        DDLogError(@"%@: ERROR validating the sighting for remote submission", self.class);
        NSString *title = NSLocalizedString(@"Some fields have errors:", @"UIAlertView title when user has still some validation errors, but clicked Save");
        NSArray *errors = validationError.userInfo[IOSightingValidationErrorUserInfoLocalizedErrorsKey];
        NSString *message = [errors componentsJoinedByString:@"\n"];
        _genericAlertView = [[UIAlertView alloc] initWithTitle:title
                                                       message:message
                                                      delegate:nil
                                             cancelButtonTitle:NSLocalizedString(@"Dismiss", @"")
                                             otherButtonTitles:nil];
        [_genericAlertView show];
        return;
    }
    
    DDLogVerbose(@"%@: Checking the location", self.class);
    IOLocationCellController *locationCellController = (IOLocationCellController *)[self cellControllerForCellID:kIOLVCLocationCellID];
    if (![locationCellController acquiredLocationChecked])
    {
        DDLogVerbose(@"%@: The location hasn't been double checked", self.class);
        NSString *title = NSLocalizedString(@"Attention", @"UIAlertView title when user hasn't checked his acquired location field, but clicked Save");
        NSString *message = NSLocalizedString(@"Please, double check the location!", @"UIAlertView message when user hasn't checked his location field, but clicked Save");
        _genericAlertView = [[UIAlertView alloc] initWithTitle:title
                                                       message:message
                                                      delegate:nil
                                             cancelButtonTitle:NSLocalizedString(@"Dismiss", @"")
                                              otherButtonTitles:nil];
        [_genericAlertView show];
        return;
    }
    
#if TESTING_SAVE_AND_MAPPING
    if ([self.delegate respondsToSelector:@selector(loggingViewController:publishedSightingWithID:)])
        [self.delegate loggingViewController:self publishedSightingWithID:self.loggingMO.objectID];
    return;
#endif
    
    __weak UIBarButtonItem *saveButton = self.saveSightingButton;
    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    saveButton.enabled = NO;
    saveButton.customView = activityIndicatorView;
    [activityIndicatorView startAnimating];
    
    self.loggingMO.status = @(IOSightingStatusSaved);
    
    if ([[IOAuth sharedInstance] hasCurrentUser] && [[IOAuth sharedInstance] isCurrentUserAuthenticated])
    {
        User *user = [[IOAuth sharedInstance] currentUser];
        self.loggingMO.user = (User *)[_context objectWithID:user.objectID];
    }
    
    self.sightingID = [self.loggingMO.objectID copy];
    [IOCoreDataHelper faultObjectWithID:self.loggingMO.objectID inContext:_context];
    
    saveButton.customView = nil;
    saveButton.enabled = YES;
    
    [self resetFormAndRetainImportedPhotos:YES];
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
    
    if (![[IOAuth sharedInstance] hasCurrentUser])
    {
        NSString *title = NSLocalizedString(@"Attention", @"");
        NSString *message = NSLocalizedString(@"Your sighting is saved locally, but until you log-in or create a user account, the sighting won't be sent to Redmap for review. Would you like to log in?", @"");
        _loginAlertView = [[UIAlertView alloc] initWithTitle:title
                                                       message:message
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"No", @"")
                                             otherButtonTitles:NSLocalizedString(@"Yes", @""), nil];
        [_loginAlertView show];
    }
    else
    {
        [[IOAuth sharedInstance] publishSighting:self.sightingID];
        [self.delegate loggingViewController:self publishedSightingWithID:self.sightingID];
        self.sightingID = nil;
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    logmethod();
    if (alertView == _genericAlertView)
    {
        _genericAlertView.delegate = nil;
        _genericAlertView = nil;
    }
    else if (alertView == _loginAlertView)
    {
        _loginAlertView.delegate = nil;
        _loginAlertView = nil;
        
        if (buttonIndex != alertView.cancelButtonIndex)
        {
            _authController = [IOAuthController authController];
            _authController.userData = @"log";
            _authController.responseDelegate = self;
            [self presentViewController:_authController animated:YES completion:NULL];
        }
    }
}


- (IBAction)resetSighting:(id)sender
{
    logmethod();
    [_context deleteObject:self.loggingMO];
    [IOCoreDataHelper faultObjectWithID:self.loggingMO.objectID inContext:_context];
    
    [self resetFormAndRetainImportedPhotos:NO];
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
}



- (IBAction)goHomeAction:(id)sender
{
    logmethod();
#if TRACK
    [GoogleAnalytics sendEventWithCategory:@"uiAction" withAction:@"buttonPress" withLabel:@"goHome" withValue:@1];
#endif
    
    [self.homeViewController goHome];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Custom methods

- (void)setupTracking
{
#if TRACK
    [GoogleAnalytics sendEventWithCategory:@"checkpoint" withAction:@"viewDidLoad" withLabel:@"IOLoggingViewController" withValue:@1];
#endif
}

////////////////////////////////////////////////////////////////////////////////
- (void)setupCellVisibilityMode
{
    // Setup the cell visibility mode
    /*
    int defaultMode = [[NSUserDefaults standardUserDefaults] integerForKey:kIOUserDefaultsModeKey];
    if (defaultMode == 0)
        defaultMode = DEFAULT_MODE;
     */
    
    self.cellsVisibilityMode = DEFAULT_MODE;
    
#if ALLOW_ADVANCED_MODE
    [self setupAdvancedNavigationButton];
    [self updateAdvancedModeButton];
#endif
}

////////////////////////////////////////////////////////////////////////////////
- (void)setupCollectionView
{
    logmethod();
    // Setup the collectionView delegate
    self.collectionView.controllerDelegate = self;
    self.collectionView.UUID = self.loggingMO.uuid;
}

////////////////////////////////////////////////////////////////////////////////
- (void)setupTheme
{
    [IORedMapThemeManager styleResetButton:self.resetButton];
}

////////////////////////////////////////////////////////////////////////////////
- (void)setupResetButton
{
#if !SHOW_RESET_BUTTON
    // Remove the reset button
    self.tableView.tableFooterView = nil;
#else
    UIBarButtonItem *resetButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(resetSighting:)];

    NSMutableArray *rightBarButtonItems;
    if (self.navigationItem.rightBarButtonItems)
        rightBarButtonItems = [self.navigationItem.rightBarButtonItems mutableCopy];
    else
        rightBarButtonItems = [NSMutableArray array];

    [rightBarButtonItems addObject:resetButton];
    self.navigationItem.rightBarButtonItems = (NSArray *)rightBarButtonItems;
#endif
}

////////////////////////////////////////////////////////////////////////////////
- (void)setupRefreshControl
{
    // Setup the refresh control
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    NSString *refreshControlText;
#if SET_TIME_AUTOMATICALLY
    refreshControlText = @"Pull to set current date and time";
#else
    refreshControlText = @"Pull to set current date";
#endif
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:refreshControlText];
    [refreshControl addTarget:self action:@selector(updateCellData:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark Cell connectors

- (NSMutableArray *)cellConnectors
{
    logmethod();
    if (_cellConnectors == nil)
    {
        _cellConnectors = [[NSMutableArray alloc] init];
        
        [self updateCellConnectors];
        
        static dispatch_once_t onceToken;
        __weak IOLoggingViewController *weakSelf = self;
        dispatch_once(&onceToken, ^{
            _cellsModeObserverAdded = YES;
            [weakSelf addObserver:weakSelf forKeyPath:@"cellsMode" options:0 context:nil];
        });
    }
    return _cellConnectors;
}

////////////////////////////////////////////////////////////////////////////////
- (void)updateCellConnectors
{
    logmethod();
    NSArray *cellIDs = [self.cellConnectors valueForKey:kIOLVCCellID];
    NSSet *cellIDsSet = [NSSet setWithArray:cellIDs];
    
    NSArray *sections = [self currentlyVisibleSections];
    for (int i = 0; i < [sections count]; i++)
    {
        for (NSDictionary *item in sections[i])
        {
            NSString *cellID = [item objectForKey:kIOLVCCellID];
            
            // Skip if the cellID is in the cellConnectors set
            if ([cellIDsSet member:cellID])
                continue;
            
            NSString *controllerName = (NSString *)[item objectForKey:kIOLVCCellController];
            NSDictionary *runtimeSettings = (NSDictionary *)[item objectForKey:kIOLVCRuntimeSettings];
#ifdef DEBUG
            if (controllerName == nil)
                controllerName = @"IOBaseCellController";
#endif
            id cellClass = [NSClassFromString(controllerName) alloc];
            id <IOCellControllerConnection> cellController;
            if ([cellClass respondsToSelector:@selector(initWithSettings:delegate:managedObjectContext:)])
                cellController = [cellClass initWithSettings:runtimeSettings delegate:self managedObjectContext:_context];
            else
                cellController = [cellClass initWithSettings:runtimeSettings delegate:self];
            
            [self.cellConnectors addObject:@{
                 kIOLVCCellID: cellID,
                 kIOLVCConnectionInfo: item,
                 kIOLVCCellController: cellController,
             }];
        }
    }
}

- (void)resetCellControllerForCellID:(NSString *)cellID
{
    logmethod();
    NSArray *cellIDs = [self.cellConnectors valueForKey:kIOLVCCellID];
    NSUInteger index = [cellIDs indexOfObject:cellID];
    
    if (index == NSNotFound)
        return;
    else
    {
        NSDictionary *oldConnector = [self.cellConnectors objectAtIndex:index];
        NSDictionary *item = [oldConnector objectForKey:kIOLVCConnectionInfo];
        
        NSString *controllerName = (NSString *)[item objectForKey:kIOLVCCellController];
        NSDictionary *runtimeSettings = (NSDictionary *)[item objectForKey:kIOLVCRuntimeSettings];
#ifdef DEBUG
        if (controllerName == nil)
            controllerName = @"IOBaseCellController";
#endif
        id cellClass = [NSClassFromString(controllerName) alloc];
        id <IOCellControllerConnection> cellController;
        if ([cellClass respondsToSelector:@selector(initWithSettings:delegate:managedObjectContext:)])
            cellController = [cellClass initWithSettings:runtimeSettings delegate:self managedObjectContext:_context];
        else
            cellController = [cellClass initWithSettings:runtimeSettings delegate:self];
        
        NSDictionary *newConnector = @{
                                       kIOLVCCellID: cellID,
                                       kIOLVCConnectionInfo: item,
                                       kIOLVCCellController: cellController,
                                       };
        
        [self.cellConnectors replaceObjectAtIndex:index withObject:newConnector];
    }
}

////////////////////////////////////////////////////////////////////////////////
- (id <IOCellControllerConnection>)cellControllerForCellID:(NSString *)cellID
{
    id <IOCellControllerConnection> cellController;
    
    NSArray *cellIDs = [self.cellConnectors valueForKey:kIOLVCCellID];
    NSUInteger index = [cellIDs indexOfObject:cellID];
    
    if (index == NSNotFound)
        return nil;
    
    cellController = [[self.cellConnectors objectAtIndex:index] objectForKey:kIOLVCCellController];
    
    return cellController;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark Cell Modes

#if ALLOW_ADVANCED_MODE
- (void)setupAdvancedNavigationButton
{
    self.advancedButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ellipsis"]
                                                           style:UIBarButtonItemStyleBordered
                                                          target:self
                                                          action:@selector(toggleMode:)];

    NSMutableArray *rightBarButtonItems;
    if (self.navigationItem.rightBarButtonItems)
        rightBarButtonItems = [self.navigationItem.rightBarButtonItems mutableCopy];
    else
        rightBarButtonItems = [NSMutableArray array];

    [rightBarButtonItems addObject:self.advancedButton];
    self.navigationItem.rightBarButtonItems = (NSArray *)rightBarButtonItems;
}

////////////////////////////////////////////////////////////////////////////////
- (void)toggleMode:(id)sender
{
    IOMode newMode = self.cellsVisibilityMode == IOModeDefault ? IOModeAdvanced : IOModeDefault;
    
    /*
    [[NSUserDefaults standardUserDefaults] setInteger:newDefaultMode forKey:kIOUserDefaultsModeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
     */
    
    self.cellsVisibilityMode = newMode;
}

////////////////////////////////////////////////////////////////////////////////
- (void)updateAdvancedModeButton
{
    if ((self.cellsMode & IOModeAdvanced) != NO)
        self.advancedButton.tintColor = [UIColor colorWithRed:0.196
                                                        green:0.3098
                                                         blue:0.52
                                                        alpha:1.0];
    else if ((self.cellsMode & IOModeDefault) != NO)
        self.advancedButton.tintColor = nil;
}
#endif

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark Form field helpers

- (void)resetFormAndRetainImportedPhotos:(BOOL)retainPhotos
{
    logmethod();
    self.loggingMO = nil;
    
    self.cellConnectors = nil;
    
    if (retainPhotos)
        self.collectionView.retainPhotos = YES;
    self.collectionView.UUID = self.loggingMO.uuid;
    
    self.speciesCellMode = IOModeSpeciesNotSet;

    [self markRequiredFieldsEvenIfNotDirty:NO];
    [self.tableView reloadData];
}

////////////////////////////////////////////////////////////////////////////////
- (void)markRequiredFieldsEvenIfNotDirty:(BOOL)markEvenIfNotDirty
{
    logmethod();
    if (!_viewIsVisible)
        return;
    
    //self.cellsToMark = [self requiredFieldsCellsIdentifiers];
    NSArray *failedValidationFields = [self failedValidationFieldsCellIdentifiers];
    [self.cellConnectors enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *cellConnector = (NSDictionary *)obj;
        NSString *cellID = [cellConnector objectForKey:kIOLVCCellID];
        id <IOCellControllerConnection> cellController = [cellConnector objectForKey:kIOLVCCellController];
        
        if ([failedValidationFields indexOfObject:cellID] != NSNotFound)
        {
            if (markEvenIfNotDirty || [cellController isDirty])
                [cellController markTableViewCell:nil];
        }
        else
        {
            [cellController unmarkTableViewCell:nil];
            
            if ([cellID isEqualToString:kIOLVCLocationCellID])
            {
                IOLocationCellController *locationCellController = (IOLocationCellController *)cellController;
                [locationCellController markTableViewCell:nil asUnChecked:![locationCellController acquiredLocationChecked] animated:YES];
            }
        }
    }];
    
    if ([failedValidationFields indexOfObject:kIOLVCPhotoCollection] != NSNotFound)
    {
        if (markEvenIfNotDirty || [self.collectionView isDirty])
            [self.collectionView mark];
    }
    else
        [self.collectionView unmark];
}

////////////////////////////////////////////////////////////////////////////////
- (void)markRequiredFieldsAndScrollToTop:(BOOL)scrollToTop
{
    logmethod();
    [self markRequiredFieldsEvenIfNotDirty:YES];
    
    if (scrollToTop)
        [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public methods

- (void)setCategory:(IOCategory *)category andSpecies:(Species *)species
{
    logmethod();
    IOCategory *categoryInLogContext = (IOCategory *)[_context objectWithID:category.objectID];
    Species *speciesInLogContext = (Species *)[_context objectWithID:species.objectID];
    
    [self setManagedObjectDataWithKeyValueDictionary:@{
                                                       kIOSightingPropertyCategory: categoryInLogContext,
                                                       kIOSightingPropertySpecies: speciesInLogContext,
                                                       
                                                       kIOSightingPropertyOtherSpecies: @NO,
                                                       kIOSightingPropertyOtherSpeciesName: [NSNull null],
                                                       kIOSightingPropertyOtherSpeciesCommonName: [NSNull null],
                                                       }];

#warning NOTE TO SELF - this method is usually called before viewDidLoad ;), so enableSpeciesMode doesn't achieve its purpose
    [self enableSpeciesMode];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIRefreshConrol action selector

- (void)updateCellData:(UIRefreshControl *)refreshControl
{
    logmethod();
    [refreshControl endRefreshing];
    
    NSDate *now = [NSDate date];
    NSDateComponents *dateComponents = [self.calendar components:
                                        NSYearCalendarUnit|
                                        NSMonthCalendarUnit|
                                        NSDayCalendarUnit|
                                        NSHourCalendarUnit|
                                        NSMinuteCalendarUnit
                                                   fromDate:now];
    
    // Get current time, but null out the minutes and seconds
    if (dateComponents.minute >= 30)
        dateComponents.hour += 1;
    dateComponents.minute = 0;
    
    self.loggingMO.dateSpotted = [self.calendar dateFromComponents:dateComponents];
    self.loggingMO.dateModified = now;
#if SET_TIME_AUTOMATICALLY
    self.loggingMO.time = [[IOSightingAttributesController sharedInstance] timeEntryFromValue:@([dateComponents hour])];
#endif
    self.loggingMO.timeNotSure = @NO;
    [self.tableView reloadData];
    
    // Highlight the date cell
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:1];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
#if SET_TIME_AUTOMATICALLY
    // Highlight the time cell
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:1];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
#endif
}

#pragma mark - IOAuthControllerDelegate
- (void)authControllerDidSucceed:(IOAuthController *)authController
{
    logmethod();
    [self dismissViewControllerAnimated:YES completion:nil];
    _authController.delegate = nil;
    _authController = nil;
    
    [[IOAuth sharedInstance] publishSighting:self.sightingID];
    [self.delegate loggingViewController:self publishedSightingWithID:self.sightingID];
    self.sightingID = nil;
}

- (void)authControllerDidFail:(IOAuthController *)authController error:(NSError *)error
{
    logmethod();
    if ([error.domain isEqualToString:IOAuthControllerDomain]) // no internet connection
    {
        [self dismissViewControllerAnimated:YES completion:nil];
        _authController.delegate = nil;
        _authController = nil;
    }
}

- (void)authControllerDidCancel:(IOAuthController *)authController
{
    logmethod();
    [self dismissViewControllerAnimated:YES completion:nil];
    _authController.delegate = nil;
    _authController = nil;
}

@end
