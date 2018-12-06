//
//  IOSpotTableViewController.m
//  RedMap
//
//  Created by Evo Stamatov on 26/03/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#warning TODO: show loading indicator when the app is still syncing for the first time

#import "IOSpotTableViewController.h"
#import "AppDelegate.h"
#import "CategoriesDataSource.h"
#import "IOAddNewSpeciesTableViewController.h"
#import "IOCategory.h"
#import "IOCellConnection.h"
#import "IOCommonListingTVC.h"
#import "IOGeoLocation.h"
#import "IORedMapThemeManager.h"
#import "IORegionsDataSource.h"
#import "IOSightingAttributesController.h"
#import "IOSpeciesDetailViewController.h"
#import "IOSpotDataSourceDelegate.h"
#import "IOSpotTableViewCell.h"
#import "Region.h"
#import "Species.h"
#import "SpeciesDataSource.h"
#import "IOCoreDataHelper.h"

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface IOSpotTableViewController () <IOSpotDataSourceDelegate, IOCellConnection, IOGeoLocationDelegate, IOAddNewSpeciesDelegate, IOSpeciesDetailDelegate>
{
    BOOL _viewReadyToHideSearchBar;
    BOOL _changingUserDefaults;
}

@property (strong, nonatomic) Region *region;
@property (strong, nonatomic) Region *previousRegion;
@property (strong, nonatomic) IORegionsDataSource *regionsDataSource;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation IOSpotTableViewController

- (NSManagedObjectContext *)context
{
    if (_context == nil)
    {
        _context = [[IOCoreDataHelper sharedInstance] context];
    }
    return _context;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
#if TRACK
    [GoogleAnalytics sendEventWithCategory:@"checkpoint" withAction:@"viewDidLoad" withLabel:[NSString stringWithFormat:@"IOSpotTableViewController-%@", (self.dataSource ? [self.dataSource class] : @"CategoriesDataSource")] withValue:@1];
#endif
    
    if (!self.hideRegionButton)
    {
        self.regionsDataSource = [[IORegionsDataSource alloc] initWithContext:self.context];
        if (self.region == nil && ![IOSightingAttributesController shouldAutodetectRegion])
        {
            // Bypass the tableView update by directly setting the ivar, not using self.region
            _region = [self.regionsDataSource regionByNameOrSlugLookup:[IOSightingAttributesController userPreSelectedRegionName]];
        }
    }
    
    self.previousRegion = self.region;
    
    // Start off with Categories DataSource
    if (!self.dataSource)
    {
        CategoriesDataSource *ds = [[CategoriesDataSource alloc] initWithManagedObjectContext:self.context region:self.region];
        ds.delegate = self;
        self.dataSource = ds;
    }
    
    if (self.dataSource)
    {
        self.tableView.dataSource = self.dataSource;
        
        // SearchBar
        if ([self.dataSource isSearchAvailable])
        {
            self.searchDisplayController.delegate = self.dataSource;
            self.searchDisplayController.searchResultsDataSource = self.dataSource;
            //self.searchDisplayController.searchResultsDelegate = self.dataSource;
        }
        else
        {
            [self.searchBar removeFromSuperview];
            CGRect frame = CGRectMake(0.0, 0.0, self.tableView.frame.size.width, 40.0);
            self.tableView.tableHeaderView.frame = frame;
            //[self.tableView setTableHeaderView:nil];
        }
    }
    
    // Manage the navigation buttons
    self.navigationItem.rightBarButtonItems = nil;
    
    if (!self.hideHomeButton)
        self.navigationItem.leftBarButtonItem = self.goHomeButton;
    
    if (self.showAddSpeciesButton)
    {
        [self.navigationItem setRightBarButtonItem:self.addNewSpeciesButton animated:NO];
        if ([self.dataSource isKindOfClass:[CategoriesDataSource class]])
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelSelection:)];
    }
    else if (!self.hideRegionButton)
        [self.navigationItem setRightBarButtonItem:self.regionButton animated:NO];
    
    // Style the table view
    [IORedMapThemeManager styleTableView:self.tableView as:IOTableViewStyleWithBackground];
        
    _viewReadyToHideSearchBar = YES;
}

////////////////////////////////////////////////////////////////////////////////
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
#if TRACK
    [GoogleAnalytics sendView:[NSString stringWithFormat:@"Spot view - %@", [self.dataSource class]]];
#endif
    
    if (!self.hideRegionButton && self.region == nil)
    {
        IOGeoLocation *geo = [IOGeoLocation sharedInstance];
        geo.delegate = self;
        [geo updateIfNeeded];
    }
    
    if (_viewReadyToHideSearchBar && self.dataSource && [self.dataSource isSearchAvailable])
    {
        //[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
        CGFloat height = self.searchDisplayController.searchBar.frame.size.height;
        //IOLog(@"TableView SearchBar Height: %f", height);
        [self.tableView setContentOffset:CGPointMake(0, height) animated:NO];
        _viewReadyToHideSearchBar = NO;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onDefaultsChanged:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
}

////////////////////////////////////////////////////////////////////////////////
- (void)viewWillDisappear:(BOOL)animated
{
    [IOGeoLocation sharedInstance].delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUserDefaultsDidChangeNotification object:nil];
    [super viewWillDisappear:animated];
}

////////////////////////////////////////////////////////////////////////////////
- (void)didReceiveMemoryWarning
{
    [self.dataSource didRecieveMemoryWarning];
    
    [super didReceiveMemoryWarning];
}

////////////////////////////////////////////////////////////////////////////////
- (void)setRegion:(Region *)region
{
    _region = region;
    
    if (!self.hideRegionButton)
    {
        _changingUserDefaults = YES;
        [[NSUserDefaults standardUserDefaults] setObject:region.desc forKey:kIOUserDefaultsRegionKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        _changingUserDefaults = NO;
        
        [self updateDataSourceAndTableViewIfNeeded];
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - TableView delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.dataSource respondsToSelector:@selector(heightForRowAtIndexPath:)])
        return [self.dataSource heightForRowAtIndexPath:indexPath];
    
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

////////////////////////////////////////////////////////////////////////////////
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id object = [self.dataSource objectAtIndexPath:indexPath];
    
    if ([self.dataSource isKindOfClass:[CategoriesDataSource class]])
    {
        IOSpotTableViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"SpottersSBID"];
        IOCategory *categoryObj = (IOCategory *)object;
        
        SpeciesDataSource *ds = [[SpeciesDataSource alloc] initWithManagedObjectContext:self.context category:categoryObj region:self.region];
        ds.delegate = vc;
        
        vc.dataSource = ds;
        vc.hideHomeButton = YES;
        vc.hideRegionButton = YES;
        vc.delegate = self.delegate;
        if (self.showAddSpeciesButton)
            vc.showAddSpeciesButton = YES;

        vc.navigationItem.title = categoryObj.desc;
        
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if ([self.dataSource isKindOfClass:[SpeciesDataSource class]])
    {
        SpeciesDetailViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"SpeciesDetailSBID"];
        Species *speciesObj = (Species *)object;
        
        vc.navigationItem.title = speciesObj.commonName;
        vc.delegate = self;
        
        SpeciesDataSource *speciesDS = (SpeciesDataSource *)self.dataSource;
        vc.speciesDetails = speciesObj;
        vc.categoryDetails = speciesDS.speciesCategory;

        [self.navigationController pushViewController:vc animated:YES];
    }
}

////////////////////////////////////////////////////////////////////////////////
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [IORedMapThemeManager tableView:tableView dataSource:tableView.dataSource heightForHeaderInSection:section];
}

////////////////////////////////////////////////////////////////////////////////
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [IORedMapThemeManager tableView:tableView dataSource:tableView.dataSource viewForHeaderInSection:section];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if ([self.dataSource respondsToSelector:@selector(scrollViewWillBeginDragging)])
        [self.dataSource scrollViewWillBeginDragging];
}

////////////////////////////////////////////////////////////////////////////////
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if ([self.dataSource respondsToSelector:@selector(scrollViewDidEndDraggingAndWillDecelerate:)])
        [self.dataSource scrollViewDidEndDraggingAndWillDecelerate:decelerate];
}

////////////////////////////////////////////////////////////////////////////////
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ([self.dataSource respondsToSelector:@selector(scrollViewDidEndDecelerating)])
        [self.dataSource scrollViewDidEndDecelerating];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - IOSpotDataSourceDelegate

- (UITableViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier
{
    return [self.tableView dequeueReusableCellWithIdentifier:identifier];
}

////////////////////////////////////////////////////////////////////////////////
- (UITableView *)aTableView:(BOOL)shouldTargetSearchBarTableView
{
    return shouldTargetSearchBarTableView ? self.searchDisplayController.searchResultsTableView : self.tableView;
}

////////////////////////////////////////////////////////////////////////////////
- (void)reloadData
{
    [self.tableView reloadData];
}

////////////////////////////////////////////////////////////////////////////////
- (void)beginUpdates:(BOOL)shouldTargetSearchBarTableView
{
    [[self aTableView:shouldTargetSearchBarTableView] beginUpdates];
}

////////////////////////////////////////////////////////////////////////////////
- (void)endUpdates:(BOOL)shouldTargetSearchBarTableView
{
    [[self aTableView:shouldTargetSearchBarTableView] endUpdates];
}

////////////////////////////////////////////////////////////////////////////////
// Section manipulation
- (void)insertSection:(NSUInteger)sectionIndex andShouldTargetSearchBarTableView:(BOOL)shouldTargetSearchBarTableView
{
    [[self aTableView:shouldTargetSearchBarTableView] insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
}

////////////////////////////////////////////////////////////////////////////////
- (void)deleteSection:(NSUInteger)sectionIndex andShouldTargetSearchBarTableView:(BOOL)shouldTargetSearchBarTableView
{
    [[self aTableView:shouldTargetSearchBarTableView] deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
}

////////////////////////////////////////////////////////////////////////////////
// Row manipulation
- (void)insertRowAtIndexPath:(NSIndexPath *)indexPath andShouldTargetSearchBarTableView:(BOOL)shouldTargetSearchBarTableView
{
    [[self aTableView:shouldTargetSearchBarTableView] insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

////////////////////////////////////////////////////////////////////////////////
- (void)deleteRowAtIndexPath:(NSIndexPath *)indexPath andShouldTargetSearchBarTableView:(BOOL)shouldTargetSearchBarTableView
{
    [[self aTableView:shouldTargetSearchBarTableView] insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

////////////////////////////////////////////////////////////////////////////////
- (void)updateRowAtIndexPath:(NSIndexPath *)indexPath andShouldTargetSearchBarTableView:(BOOL)shouldTargetSearchBarTableView
{
    DDLogVerbose(@"%@: [%@] Update row at indexpath %d:%d", self.class, [self.dataSource class], indexPath.section, indexPath.row);
}

////////////////////////////////////////////////////////////////////////////////
// Error handling
- (void)errorFetchingResults:(NSError *)error
{
    DDLogError(@"%@: ERROR fetching [%d]: %@", self.class, error.code, error.localizedDescription);
}

////////////////////////////////////////////////////////////////////////////////
- (void)errorFetchingRemoteObjects:(NSError *)error statusCode:(NSInteger)statusCode
{
    DDLogError(@"%@: ERROR fetching remote objects. StatusCode: %d. [%d]: %@", self.class, statusCode, error.code, error.localizedDescription);
    
    if (error.code != -1004) // Could not connect to the server
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error alert title when unable to fetch new data from the remote server")
                                                        message:NSLocalizedString(error.localizedDescription, @"Error alert message")
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", @"Error alert dismiss button title")
                                              otherButtonTitles:nil];
        [alert show];
    }
}

////////////////////////////////////////////////////////////////////////////////
- (BOOL)isMainTableView:(UITableView *)tableView;
{
    return tableView == self.tableView;
}

////////////////////////////////////////////////////////////////////////////////
- (NSString *)searchBarText
{
    return self.searchDisplayController.searchBar.text;
}

////////////////////////////////////////////////////////////////////////////////
- (NSInteger)searchBarScopeIndex
{
    return self.searchDisplayController.searchBar.selectedScopeButtonIndex;
}

//- (void)requestSearchControllerState:
//- (void)setSearchControllerState:

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue destinationViewController] isKindOfClass:[IOCommonListingTVC class]])
    {
#if TRACK
        [GoogleAnalytics sendEventWithCategory:@"uiAction" withAction:@"buttonPress" withLabel:@"regionButton" withValue:@1];
#endif
        
        self.hidesBottomBarWhenPushed = YES;
        IOCommonListingTVC *vc = (IOCommonListingTVC *)[segue destinationViewController];
        vc.delegate = self;
        vc.selectedValue = self.region;
        vc.dataSource = self.regionsDataSource;
        vc.navigationTitle = @"Filter by Region";
    }
    else if ([[segue destinationViewController] isKindOfClass:[IOAddNewSpeciesTableViewController class]])
    {
        IOAddNewSpeciesTableViewController *vc = (IOAddNewSpeciesTableViewController *)[segue destinationViewController];
        vc.delegate = self;
        
        if ([self.dataSource isKindOfClass:[SpeciesDataSource class]])
        {
            SpeciesDataSource *ds = (SpeciesDataSource *)self.dataSource;
            vc.category = ds.speciesCategory;
        }
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark Unwind segue

- (IBAction)done:(UIStoryboardSegue *)segue
{
    self.hidesBottomBarWhenPushed = NO;
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

////////////////////////////////////////////////////////////////////////////////
- (IBAction)cancel:(UIStoryboardSegue *)segue
{
    self.hidesBottomBarWhenPushed = NO;
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - IOCellConnection delegate

- (void)acceptedSelection:(NSDictionary *)object
{
    self.region = [self.regionsDataSource regionByNameOrSlugLookup:object.title];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - IBActions

- (IBAction)goHome:(id)sender
{
#if TRACK
    [GoogleAnalytics sendEventWithCategory:@"uiAction" withAction:@"buttonPress" withLabel:@"goHome" withValue:@1];
#endif
    
    [self.homeViewController goHome];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - IOGeoLocationDelegate Protocol

- (void)geoLocationAcquired:(IOGeoLocation *)geoLocation region:(NSString *)regionName
{
    //IOLog(@"Region: %@ (from regionName: %@)", self.region, regionName);
    self.region = [self.regionsDataSource regionByNameOrSlugLookup:regionName];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Custom methods

- (void)updateDataSourceAndTableViewIfNeeded
{
    if (self.region && self.previousRegion && [self.region.desc isEqual:self.previousRegion.desc])
        return;
    
    if (self.region == nil && self.previousRegion == nil)
        return;
    
    self.previousRegion = self.region;
   
    if ([self.dataSource isKindOfClass:[CategoriesDataSource class]])
        self.dataSource = [[CategoriesDataSource alloc] initWithManagedObjectContext:self.context region:self.region];
    else
    {
        SpeciesDataSource *ds = (SpeciesDataSource *)self.dataSource;
        self.dataSource = [[SpeciesDataSource alloc] initWithManagedObjectContext:self.context category:ds.speciesCategory region:self.region];
    }
    
    self.tableView.dataSource = self.dataSource;
    [self.tableView reloadData];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSNotification selector

- (void)onDefaultsChanged:(NSNotification *)aNotification
{
    if (_changingUserDefaults)
        return;
    
    NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
    NSString *regionName = [standardDefaults stringForKey:kIOUserDefaultsRegionKey];
    if (![regionName isEqualToString:kIOUserDefaultsRegionAutodetect])
        self.region = [self.regionsDataSource regionByNameOrSlugLookup:regionName];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Selectors

- (void)cancelSelection:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(spotTableViewControllerDidCancel:)])
        [self.delegate spotTableViewControllerDidCancel:self];
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - IOAddNewSpeciesDelegate Protocol

- (void)addNewSpeciesViewController:(IOAddNewSpeciesTableViewController *)viewController commonName:(NSString *)commonName latinName:(NSString *)latinName
{
    if ([self.delegate respondsToSelector:@selector(spotTableViewController:commonName:latinName:)])
        [self.delegate spotTableViewController:self commonName:commonName latinName:latinName];
}

////////////////////////////////////////////////////////////////////////////////
- (void)addNewSpeciesViewControllerDidCancel:(IOAddNewSpeciesTableViewController *)viewController
{
    // No need to notify the delegate, since the view goes back to the categories/species view
    /*
    if ([self.delegate respondsToSelector:@selector(spotTableViewControllerDidCancel:)])
        [self.delegate spotTableViewControllerDidCancel:self];
    */
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - IOSpeciesDetailDelegate Protocol

- (void)speciesDetailViewController:(SpeciesDetailViewController *)viewController category:(IOCategory *)category species:(Species *)species
{
    if ([self.delegate respondsToSelector:@selector(spotTableViewController:category:species:)])
        [self.delegate spotTableViewController:self category:category species:species];
}

@end
