//
//  IOCommonListingTVC.h
//  RedMap
//
//  Created by Evo Stamatov on 19/04/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IOCellConnection.h"
#import "IOCommonListingDataSource.h"

@interface IOCommonListingTVC : UITableViewController

// Public
// ======

// The delegate will receive some callbacks from the controller
@property (nonatomic, weak) id <IOCellConnection> delegate;

// Set this to decide which listing to load from LoggingData.plist
@property (nonatomic, copy) NSString *listingKey;

// To set a predefined selection, assign the selectedValue to specific string
@property (nonatomic, retain) id selectedValue;

// Or set a predefined selection by assigning the selectedTitle
// selectedValue takes precedence, though
@property (nonatomic, copy) NSString *selectedTitle;
// an alternative that will look up the value and the first occurance will be selected
@property (nonatomic, copy) NSString *selectedTitleContains;

// Holds the current selection for the done: unwind segue
@property (nonatomic, strong) NSDictionary *selection;

// Set a specific navigationItem title. Defaults to the listing's Key
@property (nonatomic, copy) NSString *navigationTitle;



// Private
// =======

// You can set only ONE of the below if you wish to alter the source data
// dataSource takes precedence in case you set both
// By default the source data is loaded by calling IOSightingAttributesController:entriesForCategory by using the listingKey above
// but you can set any one dimensional NSArray

// Holds the loaded plist array dictionary
@property (nonatomic, retain) NSArray *listingContent;

// Holds the dataSource object. The internal tableView DOES NOT use this as its own dataSource,
// but calls IOCommmonListingDataSource methods to achieve similar results
@property (nonatomic, strong) NSObject <UITableViewDataSource, IOCommonListingDataSource> *dataSource;

@end
