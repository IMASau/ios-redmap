//
//  IOCollectionHandler.m
//  RedMap
//
//  Created by Evo Stamatov on 6/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOCollectionHandler.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreLocation/CoreLocation.h>
#import "IOPhotoCollection.h"
#import "UIColor+IOColor.h"

#define MAXIMUM_PHOTOS 1

typedef void (^VoidBlock)();

@interface IOCollectionHandler () <UICollectionViewDelegate, UICollectionViewDataSource, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) IOPhotoCollection *photos;
@property (assign) BOOL canAddMorePhotos;

@property (nonatomic, strong) UIActionSheet *importActionSheet;
@property (nonatomic, strong) UIActionSheet *deleteActionSheet;
@property (nonatomic, strong) UIActionSheet *consentActionSheet;
@property (nonatomic, strong) NSIndexPath *indexPathToDelete;
@property (nonatomic, strong) UIImage *imageToSave;
@property (nonatomic, strong) VoidBlock consentActionSheetCallback;
@property (nonatomic, strong) UIImageView *marker;

@property (nonatomic, assign) BOOL dirty;

@end


@implementation IOCollectionHandler
{
    UIImagePickerController *_imagePicker;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        self.photos = [[IOPhotoCollection alloc] init];
        self.canAddMorePhotos = self.photos.count < MAXIMUM_PHOTOS;
        
        // Fun :)
        self.delegate = self;
        self.dataSource = self;

    }
    return self;
}



- (NSString *)getUUID
{
    return self.photos.uuid;
}



- (void)setUUID:(NSString *)UUID
{
    __weak IOCollectionHandler *weakSelf = self;
    [self.photos reSetTheUUID:UUID retainingPhotos:self.retainPhotos withCallback:^(NSError *error) {
        NSNumber *photosCount = [weakSelf.controllerDelegate getManagedObjectDataForKey:@"photosCount"];
        if ([photosCount intValue] != weakSelf.photos.count)
            [weakSelf.controllerDelegate setManagedObjectDataForKey:@"photosCount" withObject:@(weakSelf.photos.count)];
        
        weakSelf.canAddMorePhotos = weakSelf.photos.count < MAXIMUM_PHOTOS;
        
        [weakSelf reloadData];
    }];
}



#pragma mark - Collection view delegate

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell;
    if (indexPath.row == self.photos.count && self.canAddMorePhotos)
    {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"AddLoggingPhotoCell" forIndexPath:indexPath];
        UIButton *addPhotoButton = (UIButton *)[cell viewWithTag:1];
        
        [addPhotoButton addTarget:self action:@selector(addAPhoto:) forControlEvents:UIControlEventTouchUpInside];
    }
    else
    {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"LoggingPhotoCell" forIndexPath:indexPath];
        UIImageView *imageView = (UIImageView *)[cell viewWithTag:1];
        
        imageView.image = [self.photos photoAtIndex:indexPath.row];
    }
    
    return cell;
}



- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath;
{
    return YES;
}



-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    self.indexPathToDelete = indexPath;
    self.deleteActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Do you want to remove the photo\nfrom this sighting?", @"Action sheet title.")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", @"Action sheet button title.")
                                         destructiveButtonTitle:NSLocalizedString(@"Delete", @"Action sheet button title.")
                                              otherButtonTitles:nil];
    self.deleteActionSheet.delegate = self;
    
    [self.deleteActionSheet showFromTabBar:[self.controllerDelegate theTabBar]];
}



-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (self.canAddMorePhotos)
        return self.photos.count + 1;
    else
        return self.photos.count;
}



#pragma mark - Camera & Photo library controller

- (void)addAPhoto:(id)sender
{
    int actions = 0;
    
    if (HasPhotosAlbum())
        actions += 1;
    if (HasCamera())
        actions += 1;
    
    if (actions == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error alert title when trying to load a photo from the users' library or camera")
                                                        message:NSLocalizedString(@"Your device does not allow access to the Photos album or your Photos album is empty and doesn't have a Camera.", @"Error alert message")
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"Dismiss", @"Error alert dismiss button title")
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    else if (actions == 1)
    {
        // manually invoking the action, bypassing the action sheet
        [self actionSheet:nil clickedButtonAtIndex:0];
        return;
    }
    
#if TRACK
    [GoogleAnalytics sendEventWithCategory:@"uiAction" withAction:@"buttonPress" withLabel:@"addAPhoto" withValue:@1];
#endif
    
    self.importActionSheet = [[UIActionSheet alloc] init];
    self.importActionSheet.delegate = self;
    
    if (HasPhotosAlbum())
        [self.importActionSheet addButtonWithTitle:NSLocalizedString(@"Choose from Library", @"Action sheet button title. Shown if the user allowed access to the Photos Library.")];
    if (HasCamera())
        [self.importActionSheet addButtonWithTitle:NSLocalizedString(@"Take a photo", @"Action sheet button title. Shown if users' device has a camera.")];
    
    [self.importActionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"Action sheet button title.")];
    self.importActionSheet.cancelButtonIndex = self.importActionSheet.numberOfButtons - 1;
    
    [self.importActionSheet showFromTabBar:[self.controllerDelegate theTabBar]];
}



- (void)saveAPhotoFromImage:(UIImage *)image
{
    if (self.photos.count + 1 == MAXIMUM_PHOTOS)
    {
        self.canAddMorePhotos = NO;
        [self deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.photos.count inSection:0]]];
    }
    
    if ([self.photos addPhotoObject:image])
    {
        self.dirty = YES;
        [self insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:(self.photos.count - 1) inSection:0]]];
        [self.controllerDelegate setManagedObjectDataForKey:@"photosCount" withObject:@(self.photos.count)];
        
#if TRACK
        [GoogleAnalytics sendEventWithCategory:@"checkpoint" withAction:@"saveAPhoto" withLabel:@"savedAPhoto" withValue:@1];
#endif
    }
}



- (void)removeAPhotoAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < self.photos.count && [self.photos removePhotoObjectAtIndex:indexPath.row])
    {
#if TRACK
        [GoogleAnalytics sendEventWithCategory:@"uiAction" withAction:@"buttonPress" withLabel:@"deleteAPhoto" withValue:@1];
#endif
        
        [self deleteItemsAtIndexPaths:@[indexPath]];
        [self.controllerDelegate setManagedObjectDataForKey:@"photosCount" withObject:@(self.photos.count)];
        if (self.photos.count < MAXIMUM_PHOTOS)
        {
            self.canAddMorePhotos = YES;
            [self insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.photos.count inSection:0]]];
        }
    }
}



#pragma mark - Static helpers

static BOOL HasPhotosAlbum() {
    static BOOL hasPhotosAlbum = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //hasPhotosAlbum = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum] == YES;
        hasPhotosAlbum = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary] == YES;
#if TRACK
        [GoogleAnalytics sendEventWithCategory:@"checkpoint" withAction:@"deviceCheck" withLabel:@"hasPhotosAlbum" withValue:@(hasPhotosAlbum)];
#endif
    });
    return hasPhotosAlbum;
}



static BOOL HasCamera() {
    static BOOL hasCamera = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        hasCamera = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == YES;
#if TRACK
        [GoogleAnalytics sendEventWithCategory:@"checkpoint" withAction:@"deviceCheck" withLabel:@"hasCamera" withValue:@(hasCamera)];
#endif
    });
    return hasCamera;
}



#pragma mark - Action Sheet delegate

- (void)actionSheet:(nonnull UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // IMPORT A PHOTO
    if (actionSheet == self.importActionSheet)
    {
        UIViewController *vc = (UIViewController *)self.controllerDelegate;
        
        // if manually called actionSheet could be nil !
        if (buttonIndex == 0)
        {
            if (HasPhotosAlbum())
                [self startMediaBrowserFromViewController:vc usingDelegate:self];
            else if (HasCamera())
                [self startCameraControllerFromViewController:vc usingDelegate:self];
            
        }
        else if (buttonIndex == 1 && HasCamera())
            [self startCameraControllerFromViewController:vc usingDelegate:self];
        
        self.importActionSheet.delegate = nil;
        self.importActionSheet = nil;
    }
    
    // DELETE A PHOTO
    else if (actionSheet == self.deleteActionSheet)
    {
        if (buttonIndex != 1)
        {
            [self removeAPhotoAtIndexPath:self.indexPathToDelete];
            self.indexPathToDelete = nil;
        }
        
        self.deleteActionSheet.delegate = nil;
        self.deleteActionSheet = nil;
    }
    
    // CONSENT APPROVAL
    else if (actionSheet == self.consentActionSheet)
    {
        if (buttonIndex == 0)
            self.consentActionSheetCallback();
        self.consentActionSheetCallback = nil;
        
        self.consentActionSheet.delegate = nil;
        self.consentActionSheet = nil;
    }
}



#pragma mark - Start a Media/Camera Browser

- (BOOL)startMediaBrowserFromViewController:(UIViewController*)controller usingDelegate:(id <UIImagePickerControllerDelegate, UINavigationControllerDelegate>)delegate
{
    if (!HasPhotosAlbum() || delegate == nil || controller == nil)
        return NO;
    
#if TRACK
    [GoogleAnalytics sendEventWithCategory:@"uiAction" withAction:@"actionTaken" withLabel:@"importPhotoFromCameraRoll" withValue:@1];
#endif
    
    _imagePicker = [[UIImagePickerController alloc] init];
    _imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    //_imagePicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    _imagePicker.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeImage, nil];
    _imagePicker.allowsEditing = NO;
    _imagePicker.delegate = delegate;
    
    [controller presentViewController:_imagePicker animated:YES completion:nil];
    return YES;
}



- (BOOL)startCameraControllerFromViewController:(UIViewController*)controller usingDelegate:(id <UIImagePickerControllerDelegate, UINavigationControllerDelegate>)delegate
{
    if (!HasCamera() || delegate == nil || controller == nil)
        return NO;
    
#if TRACK
    [GoogleAnalytics sendEventWithCategory:@"uiAction" withAction:@"actionTaken" withLabel:@"shootAPhotoWithCamera" withValue:@1];
#endif
    
    _imagePicker = [[UIImagePickerController alloc] init];
    _imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    _imagePicker.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeImage, nil];
    _imagePicker.allowsEditing = NO;
    _imagePicker.delegate = delegate;
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [controller presentViewController:_imagePicker animated:YES completion:nil];
    return YES;
}



/*
- (void)presentViewController:(UIViewController *)viewControllerToPresent fromViewController:(UIViewController *)fromViewController
{
    // http://stackoverflow.com/a/10611815/1484467
    [fromViewController presentViewController:viewControllerToPresent animated:YES completion:^{
        // scroll to the end - hack
        UIView *imagePickerView = viewControllerToPresent.view;
        
        UIView *view = [imagePickerView hitTest:CGPointMake(5,5) withEvent:nil];
        while (view != nil && ![view isKindOfClass:[UIScrollView class]]) {
            // note: in iOS 5, the hit test view is already the scroll view. I don't want to rely on that though, who knows
            // what Apple might do with the ImagePickerController view structure. Searching backwards from the hit view
            // should always work though.
            //NSLog(@"passing %@", view);
            view = [view superview];
        }
        
        if ([view isKindOfClass:[UIScrollView class]]) {
            //NSLog(@"got a scroller!");
            UIScrollView *scrollView = (UIScrollView *) view;
            // check what it is scrolled to - this is the location of the initial display - very important as the image picker
            // actually slides under the navigation bar, but if there's only a few images we don't want this to happen.
            // The initial location is determined by status bar height and nav bar height - just get it from the picker
            CGPoint contentOffset = scrollView.contentOffset;
            CGFloat y = MAX(contentOffset.y, [scrollView contentSize].height-scrollView.frame.size.height);
            CGPoint bottomOffset = CGPointMake(0, y);
            [scrollView setContentOffset:bottomOffset animated:YES];
        }
    }];
}
 */



#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    __block UIImage *originalImage, *editedImage, *imageToUse;
    __weak IOCollectionHandler *weakSelf = self;
    
    // Handle a still image picked from a photo album
    if (CFStringCompare((CFStringRef)mediaType, kUTTypeImage, 0) == kCFCompareEqualTo)
    {
        [self askForConsentInView:picker.view callback:^(){
            editedImage = (UIImage *)[info objectForKey:UIImagePickerControllerEditedImage];
            originalImage = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
            
            /*
             // lookup for embedded GPS location coordinates within the image
             NSURL *url = [info objectForKey:UIImagePickerControllerReferenceURL];
             if (url)
             {
             ALAssetsLibrary *assetsLib = [[ALAssetsLibrary alloc] init];
             [assetsLib assetForURL:url resultBlock:^(ALAsset *asset) {
             CLLocation *location = [asset valueForProperty:ALAssetPropertyLocation];
             
             // TODO: Ask the user to use the location data if the photo is shot at a different location
             IOLog(@"Location: %@", location);
             
             } failureBlock:^(NSError *error) {
             
             IOLog(@"cant get image - %@", error.localizedDescription);
             }];
             }
             */
            
            if (editedImage)
                imageToUse = editedImage;
            else
                imageToUse = originalImage;
            
            [weakSelf saveAPhotoFromImage:imageToUse];
            
            [[picker presentingViewController] dismissViewControllerAnimated:YES completion:nil];
        }];
    }
    else
    {
        [[picker presentingViewController] dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [[picker presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}



- (void)askForConsentInView:(UIView *)view callback:(VoidBlock)callback
{
    self.consentActionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Do you own all rights to this photo, and give permission for Redmap Australia to display it on their website and use in other related publications and articles?", @"Action sheet title.")
                                                          delegate:self
                                                 cancelButtonTitle:NSLocalizedString(@"No", @"Action sheet button title.")
                                            destructiveButtonTitle:nil
                                                 otherButtonTitles:NSLocalizedString(@"Yes", @"Action sheet button title."), nil];
    self.consentActionSheetCallback = callback;
    self.consentActionSheet.delegate = self;
    
    [self.consentActionSheet showInView:view];
    //[self.consentActionSheet showFromTabBar:[self.controllerDelegate theTabBar]];
}



#pragma mark - Custom methods

- (void)mark
{
    if (!self.marker)
    {
        UIImage *markerImage = [UIImage imageNamed:@"red-marker"];
        UIImageView *view = [[UIImageView alloc] initWithImage:markerImage];
        //UIView *marker = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5.0, self.bounds.size.height)];
        //marker.backgroundColor = [UIColor IOLightRedColor];
        self.marker = view;
        [self addSubview:self.marker];
    }
    else
        self.marker.hidden = NO;
    
    CGRect frame = CGRectMake(
                              self.frame.origin.x + 1.5f,//self.marker.image.size.width / 2,
                              (self.frame.size.height - self.marker.image.size.height) / 2,
                              self.marker.image.size.width,
                              self.marker.image.size.height
                              );
    self.marker.frame = frame;
}



- (void)unmark
{
    if (self.marker)
        self.marker.hidden = YES;
}



- (BOOL)isDirty
{
    return _dirty;
}


/*
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (iOS_7_OR_LATER())
    {
        if (viewController == [_imagePicker presentingViewController])
            [[UIApplication sharedApplication] setStatusBarHidden:NO];
        else
            [[UIApplication sharedApplication] setStatusBarHidden:YES];
    }
    
    if (viewController == [_imagePicker presentingViewController])
    {
        _imagePicker.delegate = nil;
        _imagePicker = nil;
    }
}
 */

@end
