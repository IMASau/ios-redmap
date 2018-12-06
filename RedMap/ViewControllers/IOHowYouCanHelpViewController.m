//
//  IOHowYouCanHelpViewController.m
//  RedMap
//
//  Created by Evo Stamatov on 4/07/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOHowYouCanHelpViewController.h"
//#import "IOMainTabBarViewController.h"


@interface IOHowYouCanHelpViewController ()

@end


@implementation IOHowYouCanHelpViewController

- (void)viewDidLoad
{
    self.htmlFile = @"helping.html"; // set before calling super's viewDidLoad
    [super viewDidLoad];
    
#if TRACK
    [GoogleAnalytics sendEventWithCategory:@"checkpoint" withAction:@"viewDidLoad" withLabel:@"IOHowYouCanHelpViewController" withValue:@1];
#endif
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}



#if TRACK
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [GoogleAnalytics sendView:@"How can you help"];
}
#endif



#pragma mark - Table view delegate

/*
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (cell.tag) {
        case IOHowYouCanHelpCellsFacebook:
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:PAGE_FACEBOOK]];
            break;
            
        case IOHowYouCanHelpCellsSpot:
            {
                IOMainTabBarViewController *vc = (IOMainTabBarViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"MainTabBarViewControllerSBID"];
                [vc setSelectedIndex:SIGHTING_TAB_INDEX];
                vc.caller = self;
                
                self.hideNavBarWhenDisappearing = YES;
                
                [self.navigationController pushViewController:vc animated:YES];
            }
            break;
            
        case IOHowYouCanHelpCellsLog:
            {
                IOMainTabBarViewController *vc = (IOMainTabBarViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"MainTabBarViewControllerSBID"];
                [vc setSelectedIndex:LOGGING_TAB_INDEX];
                vc.caller = self;
                
                self.hideNavBarWhenDisappearing = YES;
                
                [self.navigationController pushViewController:vc animated:YES];
            }
            break;
            
        case IOHowYouCanHelpCellsResources:
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:PAGE_RESOURCES]];
            break;
            
        case IOHowYouCanHelpCellsNewsletter:
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:PAGE_NEWSLETTER]];
            break;
            
        case IOHowYouCanHelpCellsContactUs:
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:PAGE_CONTACTUS]];
            break;
            
            
        default:
            break;
    }
}
 */



- (void)popTheTopmostController
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
