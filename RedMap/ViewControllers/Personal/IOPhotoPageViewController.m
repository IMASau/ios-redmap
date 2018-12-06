//
//  IOPhotoPageViewController.m
//  RedMap
//
//  Created by Evo Stamatov on 28/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOPhotoPageViewController.h"
#import "IOPhotoViewController.h"
#import "Sighting.h"
#import "IOPhotoCollection.h"
#import "AppDelegate.h"

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

@interface IOPhotoPageViewController () <UIPageViewControllerDelegate, UIPageViewControllerDataSource>

@property (nonatomic, assign) NSInteger index;
@property (nonatomic, strong) IOPhotoCollection *photos;

@end


@implementation IOPhotoPageViewController

- (void)viewDidLoad
{
    logmethod();
    [super viewDidLoad];
    
    self.delegate = self;
    self.dataSource = self;
    
    if (self.sightingUUID)
        [self loadPhotoCollectionForSightingUUID:self.sightingUUID];
}



- (void)didReceiveMemoryWarning
{
    logmethod();
    [super didReceiveMemoryWarning];
}



#pragma mark - UIPageViewController delegate

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    logmethod();
    IOPhotoViewController *vc = (IOPhotoViewController *)viewController;
    return [self preparePhotoViewAtIndex:vc.index + 1];
}



- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    logmethod();
    IOPhotoViewController *vc = (IOPhotoViewController *)viewController;
    return [self preparePhotoViewAtIndex:vc.index - 1];
}



/*
- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers
{
    
}
 */



#pragma mark - Custom methods

- (IOPhotoViewController *)preparePhotoViewAtIndex:(NSInteger)index
{
    logmethod();
    //IOLog(@"Index: %d", index);
    if (index < 0 || index > [self.photos count] - 1)
        return nil;
    
    self.index = index;
        
    UIImage *image = [self.photos photoAtIndex:index];
    IOPhotoViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"PhotoViewSBID"];
    vc.index = index;
    vc.image = image;
    return vc;
}



- (void)loadPhotoCollectionForSightingUUID:(NSString *)uuid
{
    logmethod();
    self.photos = [[IOPhotoCollection alloc] init];
    __weak IOPhotoPageViewController *weakSelf = self;
    
    [self.photos reSetTheUUID:uuid withCallback:^(NSError *error) {
        if (weakSelf.photos.count > 0)
        {
            IOPhotoViewController *vc = [weakSelf preparePhotoViewAtIndex:0];
            [weakSelf setViewControllers:@[vc] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];
        }
    }];
}

@end
