//
//  IOPersonalPhotosViewController.m
//  RedMap
//
//  Created by Evo Stamatov on 17/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOPersonalPhotosViewController.h"
#import "IOSightingCollectionCell.h"
#import "Sighting.h"
#import "IOPhotoWrapperViewController.h"

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface IOPersonalPhotosViewController () <UICollectionViewDelegate, UICollectionViewDataSource>
{
    NSBlockOperation *_blockOperation;
    BOOL _shouldReloadCollectionView;
}

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation IOPersonalPhotosViewController

- (void)dealloc
{
    logmethod();
    DDLogWarn(@"%@: Deallocating", self.class);
    
    _blockOperation = nil;
}

- (void)viewDidLoad
{
    logmethod();
    [super viewDidLoad];
    
#if TRACK
    [GoogleAnalytics sendEventWithCategory:@"checkpoint" withAction:@"viewDidLoad" withLabel:@"IOPersonalPhotosViewController" withValue:@1];
#endif
    
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sightingPhotoUpdated:) name:@"sightingPhotoUpdated" object:nil];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    logmethod();
    // a nasty hack
    if (iOS_7_OR_LATER())
        return UIEdgeInsetsMake(64.f, 0, 70.f, 0);
    else
        return UIEdgeInsetsMake(0, 0, 70.f, 0);
}

////////////////////////////////////////////////////////////////////////////////
- (void)didReceiveMemoryWarning
{
    logmethod();
    [super didReceiveMemoryWarning];
}

////////////////////////////////////////////////////////////////////////////////
- (void)viewWillAppear:(BOOL)animated
{
    logmethod();
    [super viewWillAppear:animated];
    [self.collectionView reloadData];
    
#if TRACK
    [GoogleAnalytics sendView:@"Personal - Photos"];
#endif
}

////////////////////////////////////////////////////////////////////////////////
- (void)viewWillDisappear:(BOOL)animated
{
    logmethod();
    [super viewWillDisappear:animated];
    
    self.parentViewController.hidesBottomBarWhenPushed = NO;
}

////////////////////////////////////////////////////////////////////////////////
- (void)viewDidDisappear:(BOOL)animated
{
    logmethod();
    //[_blockOperation cancel];
    [super viewDidDisappear:animated];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Collection view delegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    logmethod();
    return self.fetchedResultsController.sections.count;
}

////////////////////////////////////////////////////////////////////////////////
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    logmethod();
    id <NSFetchedResultsSectionInfo> sectionInfo = self.fetchedResultsController.sections[section];
    return [sectionInfo numberOfObjects];
}

////////////////////////////////////////////////////////////////////////////////
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    logmethod();
    Sighting *sighting = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    static NSString *cellIdentifier = @"SightingCell";
    IOSightingCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    [cell setSightingID:sighting.objectID inContext:self.fetchedResultsController.managedObjectContext];
    
    return cell;
}

////////////////////////////////////////////////////////////////////////////////
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath;
{
    logmethod();
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    logmethod();
    IOSightingCollectionCell *cell = (IOSightingCollectionCell *)sender;
    IOPhotoWrapperViewController *vc = (IOPhotoWrapperViewController *)[segue destinationViewController];
    vc.sightingUUID = cell.sightingUUID;
    
    self.parentViewController.hidesBottomBarWhenPushed = YES;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - IOPersonalFetchDelegate Protocol

/*
- (void)fetchedResultsWillChange
{
    _blockOperation = [NSBlockOperation new];
    _shouldReloadCollectionView = NO;
}

////////////////////////////////////////////////////////////////////////////////
- (void)fetchedResultsInsertedObject:(id)anObject newIndexPath:(NSIndexPath *)newIndexPath
{
    if ([self.collectionView numberOfSections] > 0)
    {
        if ([self.collectionView numberOfItemsInSection:newIndexPath.section] == 0)
            _shouldReloadCollectionView = YES;
        else
        {
            __weak UICollectionView *collectionView = self.collectionView;
            if (newIndexPath == nil)
            {
                DDLogWarn(@"%@: ERROR", self.class);
            }
                
            NSArray *newIndexPaths = @[[newIndexPath copy]];
            [_blockOperation addExecutionBlock:^{
                [collectionView insertItemsAtIndexPaths:newIndexPaths];
            }];
        }
    }
    else
        _shouldReloadCollectionView = YES;
}

////////////////////////////////////////////////////////////////////////////////
- (void)fetchedResultsDeletedObject:(id)anObject atIndexPath:(NSIndexPath *)atIndexPath
{
    if ([self.collectionView numberOfItemsInSection:atIndexPath.section] == 1)
        _shouldReloadCollectionView = YES;
    else
    {
        __weak UICollectionView *collectionView = self.collectionView;
        NSArray *atIndexPaths = @[[atIndexPath copy]];
        [_blockOperation addExecutionBlock:^{
            [collectionView deleteItemsAtIndexPaths:atIndexPaths];
        }];
    }
}

////////////////////////////////////////////////////////////////////////////////
- (void)fetchedResultsUpdatedObject:(id)anObject atIndexPath:(NSIndexPath *)atIndexPath
{
    __weak UICollectionView *collectionView = self.collectionView;
    [_blockOperation addExecutionBlock:^{
        [collectionView reloadItemsAtIndexPaths:@[atIndexPath]];
    }];
}

////////////////////////////////////////////////////////////////////////////////
- (void)fetchedResultsMovedObject:(id)anObject fromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    __weak UICollectionView *collectionView = self.collectionView;
    [_blockOperation addExecutionBlock:^{
        [collectionView moveItemAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
    }];
}

 */
////////////////////////////////////////////////////////////////////////////////
- (void)fetchedResultsDidChange
{
    logmethod();
    [self.collectionView reloadData];
    /*
    if (_shouldReloadCollectionView)
        [self.collectionView reloadData];
    else
        [self.collectionView performBatchUpdates:^{
            [_blockOperation start];
        } completion:NULL];
     */
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - IOPersonalViewControllerProtocol

/*
 - (void)viewDidBecomeTopmost
{
    IOLog(@"TOPMOST");
}
 */

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Notifications

/*
- (void)sightingPhotoUpdated:(NSNotification *)aNotification
{
    NSString *sightingUUID = (NSString *)[aNotification.userInfo objectForKey:@"sightingUUID"];
    [[self.collectionView visibleCells] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        IOSightingCollectionCell *cell = (IOSightingCollectionCell *)obj;
        if ([cell.sightingUUID isEqualToString:sightingUUID])
        {
            
        }
    }];
}
 */

@end
