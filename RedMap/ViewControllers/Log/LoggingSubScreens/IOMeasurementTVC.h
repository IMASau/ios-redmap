//
//  IOMeasurementTVC.h
//  RedMap
//
//  Created by Evo Stamatov on 22/04/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IOCellConnection.h"

@interface IOMeasurementTVC : UITableViewController <UITextFieldDelegate>

// Public
// ======

// The delegate will receive some callbacks from the controller
@property (nonatomic, weak) id <IOCellConnection> delegate;

@property (nonatomic, copy) NSString *navigationTitle;
@property (nonatomic, copy) NSString *units;
@property (nonatomic, copy) NSString *placeholder;

@property (nonatomic, assign) CGFloat value;
@property (nonatomic, strong) id method;
@property (nonatomic, strong) NSArray *methods;

@property (nonatomic, assign) BOOL hiddenMethodsSegment;
@property (nonatomic, assign) BOOL visibleNegativeSwitch;

// Private
// =======
@property (weak, nonatomic) IBOutlet UITextField *measurementInput;
@property (weak, nonatomic) IBOutlet UISegmentedControl *methodsSegment;
@property (weak, nonatomic) IBOutlet UISwitch *negativeSwitch;
- (IBAction)switchNegative:(id)sender;

@end
