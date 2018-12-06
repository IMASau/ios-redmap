//
//  IODateVC.h
//  RedMap
//
//  Created by Evo Stamatov on 23/04/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IOCellConnection.h"

@interface IODateVC : UIViewController

// Public
// ======

// The delegate will receive some callbacks from the controller
@property (nonatomic, weak) id <IOCellConnection> delegate;

// Sets the desired date for the datepicker
@property (weak, nonatomic) NSDate *date;

// Sets the minimum date for the datepicker
@property (weak, nonatomic) NSDate *minimumDate;

// Sets the maximum date for the datepicker
@property (weak, nonatomic) NSDate *maximumDate;



// Private
// =======

@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;

@end
