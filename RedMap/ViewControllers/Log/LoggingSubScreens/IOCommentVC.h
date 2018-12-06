//
//  IOCommentVC.h
//  RedMap
//
//  Created by Evo Stamatov on 6/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IOCellConnection.h"

@interface IOCommentVC : UIViewController

// Public
// ======

// The delegate will receive some callbacks from the controller
@property (nonatomic, weak) id <IOCellConnection> delegate;

// Pre-set the text
@property (nonatomic, copy) NSString *text;



// Private
// =======

@property (weak, nonatomic) IBOutlet UITextView *commentText;

@end
