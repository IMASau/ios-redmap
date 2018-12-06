//
//  IOSpotTableViewController.h
//  RedMap
//
//  Created by Evo Stamatov on 26/03/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IOSpotDataSource.h"
#import "IOHomeTableViewControllerProtocol.h"

@protocol IOSpotTableViewControllerDelegate;

////////////////////////////////////////////////////////////////////////////////
@interface IOSpotTableViewController : UITableViewController

// This dataSource is assigned as the TableView dataSource at ViewDidLoad
@property (strong, nonatomic) NSObject <UITableViewDataSource, IOSpotDataSource, UISearchDisplayDelegate> *dataSource;

@property (assign, nonatomic) BOOL hideHomeButton;
@property (assign, nonatomic) BOOL hideRegionButton;                            // opposite of showAddSpeciesButton
@property (assign, nonatomic) BOOL showAddSpeciesButton;                        // opposite of hideRegionButton

@property (strong, nonatomic) IBOutlet UIBarButtonItem *regionButton;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *goHomeButton;
- (IBAction)goHome:(id)sender;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *addNewSpeciesButton;

@property (nonatomic, weak) id<IOSpotTableViewControllerDelegate> delegate;
@property (nonatomic, weak) id<IOHomeTableViewControllerProtocol> homeViewController;

@property (nonatomic, strong) NSManagedObjectContext *context;

@end

////////////////////////////////////////////////////////////////////////////////
@class IOCategory;
@class Species;

@protocol IOSpotTableViewControllerDelegate <NSObject>

@optional
- (void)spotTableViewController:(UIViewController *)viewController category:(IOCategory *)category species:(Species *)species;
- (void)spotTableViewController:(UIViewController *)viewController commonName:(NSString *)commonName latinName:(NSString *)latinName;
- (void)spotTableViewControllerDidCancel:(UIViewController *)viewController;

@end