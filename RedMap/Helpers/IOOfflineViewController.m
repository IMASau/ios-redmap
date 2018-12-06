//
//  IOOfflineViewController.m
//  RedMap
//
//  Created by Evo Stamatov on 24/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOOfflineViewController.h"


#define kOfflineViewHeight 37.0
#define kOfflineViewAnimationDuration 0.30

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

@interface IOOfflineViewController ()

@property (weak, nonatomic) IBOutlet UIButton *offlineLabel;

@property (weak, nonatomic) UITableView *tableView;
@property (assign, nonatomic) BOOL animate;

@property (assign, nonatomic) BOOL shown;

@end


@implementation IOOfflineViewController

- (void)viewDidLoad
{
    logmethod();
    [super viewDidLoad];
    
    // Remove the background
    self.view.backgroundColor = [UIColor clearColor];
    
    // Set the button's background
    UIEdgeInsets inset = UIEdgeInsetsMake(12.5, 11.0, 12.5, 23.0);
    UIEdgeInsets contentInset = UIEdgeInsetsMake(0, 21.0, 0, 33.0);
    UIImage *resizableImage = [[UIImage imageNamed:@"offline-note-bg"] resizableImageWithCapInsets:inset resizingMode:UIImageResizingModeStretch];
    
    [self.offlineLabel setBackgroundImage:resizableImage forState:UIControlStateNormal];
    [self.offlineLabel setContentEdgeInsets:contentInset];
    [self.offlineLabel setUserInteractionEnabled:NO];
}



- (void)didReceiveMemoryWarning
{
    logmethod();
    [super didReceiveMemoryWarning];
}



- (void)dealloc
{
    logmethod();
    _animate = NO;
    [self detach];
}



#pragma mark - Custom methods

#pragma mark Public

- (void)attachToTableView:(UITableView *)tableView animated:(BOOL)animate
{
    logmethod();
    // check if it was attached to a tableView previously
    if (self.tableView)
        [self detachAnimated:NO];
    
    self.tableView = tableView;
    self.animate = animate;
    
    [self attach];
}



- (void)detachAnimated:(BOOL)animate
{
    logmethod();
    self.animate = animate;
    
    [self detach];
}



#pragma mark Class methods

+ (IOOfflineViewController *)sharedController
{
    static IOOfflineViewController *offlineVC;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        offlineVC = [[self alloc] initWithNibName:@"IOOfflineView" bundle:nil];
    });
    
    return offlineVC;
}



#pragma mark Private

- (void)attach
{
    logmethod();
    if (self.shown)
        return;
    
    self.shown = YES;
    
    __weak UIView *offlineView = self.view;
    __block CGRect offlineFrame = self.tableView.frame;
    
    if (self.animate)
        offlineFrame.size.height = 0.0;
    else
        offlineFrame.size.height = kOfflineViewHeight;
    
    offlineView.frame = offlineFrame;
    self.tableView.tableHeaderView = offlineView;
    
    if (self.animate)
    {
        [self.tableView beginUpdates];
        
        __weak IOOfflineViewController *weakSelf = self;
        [UIView animateWithDuration:kOfflineViewAnimationDuration animations:^{
            offlineFrame.size.height = kOfflineViewHeight;
            offlineView.frame = offlineFrame;
            weakSelf.tableView.tableHeaderView = offlineView;
            [weakSelf.tableView endUpdates];
        } completion:NULL];
    }
}



- (void)detach
{
    logmethod();
    if (!self.shown)
        return;
    
    self.shown = NO;
    
    __weak UIView *offlineView = self.view;
    __block CGRect offlineFrame = self.tableView.frame;
    
    if (self.animate)
    {
        [self.tableView beginUpdates];
        
        __weak IOOfflineViewController *weakSelf = self;
        [UIView animateWithDuration:kOfflineViewAnimationDuration animations:^{
            offlineFrame.size.height = 0.0;
            offlineView.frame = offlineFrame;
            weakSelf.tableView.tableHeaderView = offlineView;
            [weakSelf.tableView endUpdates];
        } completion:^(BOOL finished) {
            weakSelf.tableView.tableHeaderView = nil;
            weakSelf.tableView = nil;
        }];
    }
    else
    {
        self.tableView.tableHeaderView = nil;
        self.tableView = nil;
    }
}

@end
