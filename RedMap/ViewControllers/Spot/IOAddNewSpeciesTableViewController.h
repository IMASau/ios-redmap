//
//  IOAddNewSpeciesTableViewController.h
//  Redmap
//
//  Created by Evo Stamatov on 13/08/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <UIKit/UIKit.h>

@class IOCategory;
@protocol IOAddNewSpeciesDelegate;

@interface IOAddNewSpeciesTableViewController : UITableViewController

@property (nonatomic, strong) IOCategory *category;
@property (nonatomic, copy) NSString *latinName;
@property (nonatomic, copy) NSString *commonName;
@property (nonatomic, weak) id<IOAddNewSpeciesDelegate> delegate;

@end


@protocol IOAddNewSpeciesDelegate <NSObject>
- (void)addNewSpeciesViewControllerDidCancel:(IOAddNewSpeciesTableViewController *)viewController;
- (void)addNewSpeciesViewController:(IOAddNewSpeciesTableViewController *)viewController commonName:(NSString *)commonName latinName:(NSString *)latinName;
@end