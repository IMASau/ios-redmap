//
//  IOSightingCollectionCell.m
//  RedMap
//
//  Created by Evo Stamatov on 17/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOSightingCollectionCell.h"
#import "Sighting.h"
#import "IOPhotoCollection.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImageView+IOImage.h"
#import "Species.h"
#import "IOVolatileCache.h"
#import "IOCoreDataHelper.h"

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface IOSightingCollectionCell ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageViewWidthConstraint;
//@property (weak, nonatomic) IBOutlet UIImageView *validatedOverlay;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@property (nonatomic, assign) CGFloat scaledHeight;
@property (nonatomic, assign) CGFloat scaledWidth;
@property (nonatomic, strong) NSMutableArray *additionalSubViews;

@property (nonatomic, strong) IOPhotoCollection *photos;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation IOSightingCollectionCell

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
    {
    logmethod();
        DDLogVerbose(@"%@: Initializing", self.class);
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sightingPhotoUpdated:) name:@"sightingPhotoUpdated" object:nil];
    }
    
    return self;
}

////////////////////////////////////////////////////////////////////////////////
- (void)dealloc
{
    logmethod();
    DDLogVerbose(@"%@: Deallocating", self.class);
    
    if (self.additionalSubViews.count > 0)
        for (UIView *view in self.additionalSubViews)
            [view removeFromSuperview];
    
    _additionalSubViews = nil;
    _photos = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - UICollectionViewCell overwrites

- (void)prepareForReuse
{
    logmethod();
    [super prepareForReuse];
    
    DDLogVerbose(@"%@: Reusing", self.class);
    
    _sightingUUID = nil;
    self.imageView.image = nil;
    self.imageView.backgroundColor = [UIColor grayColor];
    [self addLayerBorder:self.imageView.layer withShadow:NO andRasterize:NO];
    
    self.imageViewHeightConstraint.constant = 90.f;
    self.imageViewWidthConstraint.constant = 90.f;
    
    UIActivityIndicatorView *spinner = (UIActivityIndicatorView *)[self.imageView viewWithTag:1000];
    if (!spinner)
    {
        DDLogVerbose(@"%@: Adding a spinner", self.class);
        spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        spinner.tag = 1000;
        [self.imageView addSubview:spinner];
        [spinner startAnimating];
    }
    spinner.center = CGPointMake(self.imageView.bounds.size.width / 2.0, self.imageView.bounds.size.height / 2.0);
    
    if (self.additionalSubViews.count > 0)
        for (UIView *view in self.additionalSubViews)
            [view removeFromSuperview];
    
    self.photos = nil;
    self.scaledHeight = 0;
    self.scaledWidth = 0;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Custom methods

- (void)setSightingID:(NSManagedObjectID *)sightingID inContext:(NSManagedObjectContext *)context
{
    logmethod();
    DDLogVerbose(@"%@: Setting a sighting", self.class);
    
    self.imageView.backgroundColor = [UIColor grayColor];
    [self addLayerBorder:self.imageView.layer withShadow:NO andRasterize:NO];
    
    UIActivityIndicatorView *spinner = (UIActivityIndicatorView *)[self.imageView viewWithTag:1000];
    if (!spinner)
    {
        DDLogVerbose(@"%@: Adding a spinner", self.class);
        spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        spinner.tag = 1000;
        [self.imageView addSubview:spinner];
        [spinner startAnimating];
    }
    spinner.center = CGPointMake(self.imageView.bounds.size.width / 2.0, self.imageView.bounds.size.height / 2.0);
    
    Sighting *sighting = (Sighting *)[context objectWithID:sightingID];
    
    Species *species = (Species *)sighting.species;
    if (species != nil)
    {
        self.titleLabel.text = species.commonName;
        self.subtitleLabel.text = species.speciesName;
    }
    else if ([sighting.otherSpecies boolValue])
    {
        self.titleLabel.text = sighting.otherSpeciesCommonName;
        self.subtitleLabel.text = sighting.otherSpeciesName;
    }
    else
    {
        self.titleLabel.text = @"Error";
        self.subtitleLabel.text = nil;
    }
    
    self.dateLabel.text = [NSDateFormatter localizedStringFromDate:sighting.dateSpotted dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle];
    
    NSString *sightingUUID = [sighting.uuid copy];
    _sightingUUID = sightingUUID;
    //[IOCoreDataHelper faultObjectWithID:sighting.objectID inContext:context];
    
    //self.validatedOverlay.hidden = [sighting.validSighting boolValue];
    
    UIImage *image = [IOVolatileCache objectForKey:sightingUUID];
    if (image)
        [self setTheImage:image withShadow:NO];
    else
    {
        self.photos = [[IOPhotoCollection alloc] init];
        
        __weak __typeof(self)weakSelf = self;
        [self.photos reSetTheUUID:sightingUUID withCallback:^(NSError *error) {
            if (![weakSelf.sightingUUID isEqualToString:sightingUUID])
            {
                // Bail out quickly if the cell has allready been re-purposed
                DDLogWarn(@"%@: Different sightingUUID: %@ <=> %@", weakSelf.class, weakSelf.sightingUUID, sightingUUID);
                // Note: self.photos will be reset by the new cell
                return;
            }
            
            if (weakSelf.photos.count > 0)
            {
                UIImage *image = [weakSelf.photos photoAtIndex:0 forSize:CGSizeMake(90.0, 90.0)];
                [IOVolatileCache setObject:image forKey:sightingUUID];
                
                //[weakSelf setTheImage:image withShadow:(weakSelf.photos.count > 1)];
                [weakSelf setTheImage:image withShadow:NO];
            }
            /*
            else
                [weakSelf addLayerBorder:weakSelf.imageView.layer withShadow:NO andRasterize:NO];
            
            if (weakSelf.photos.count > 1)
                [weakSelf addBlankSubviews];
             */
            
            weakSelf.photos = nil;
        }];
    }
}

////////////////////////////////////////////////////////////////////////////////
- (void)setTheImage:(UIImage *)image withShadow:(BOOL)withShadow
{
    logmethod();
    DDLogVerbose(@"%@: Setting the image", self.class);
    
    self.imageView.backgroundColor = nil;
    UIView *spinner = [self.imageView viewWithTag:1000];
    if (spinner)
    {
        DDLogVerbose(@"%@: Removing the spinner", self.class);
        [spinner removeFromSuperview];
    }
    
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.image = image;
    
    
    CGFloat aspect = image.size.width / image.size.height;
    
    if (image.size.width > image.size.height)
    {
        self.imageViewWidthConstraint.constant = 90.0;
        self.imageViewHeightConstraint.constant = image.size.width / aspect;
    }
    else
    {
        self.imageViewHeightConstraint.constant = 90.0;
        self.imageViewWidthConstraint.constant = image.size.height * aspect;
    }
    
    [self addLayerBorder:self.imageView.layer withShadow:withShadow andRasterize:NO];
}

////////////////////////////////////////////////////////////////////////////////
- (void)addBlankSubviews
{
    logmethod();
    CGRect frame = self.imageView.frame;
    frame.origin.y = frame.origin.y + (frame.size.height - self.scaledHeight) * .5;
    frame.origin.x = frame.origin.x + (frame.size.width - self.scaledWidth) * .5;
    frame.size.height = self.scaledHeight;
    frame.size.width = self.scaledWidth;
    
    UIView *view = [[UIView alloc] initWithFrame:frame];
    int angle = (arc4random() % 5 + 3) * ((arc4random() % 100) > 50 ? 1 : -1); // an angle between -5..-2 and 2..5
    view.transform = CGAffineTransformMakeRotation(angle * M_PI / 180);
    view.backgroundColor = [UIColor whiteColor];
    
    [self addLayerBorder:view.layer withShadow:NO andRasterize:YES];
    
    self.additionalSubViews = [[NSArray arrayWithObject:view] mutableCopy];
    
    [self insertSubview:view atIndex:0];
}

////////////////////////////////////////////////////////////////////////////////
- (void)addLayerBorder:(CALayer *)layer withShadow:(BOOL)withShadow andRasterize:(BOOL)shouldRasterize
{
    logmethod();
#if DEBUG
    DDLogVerbose(@"%@: Adding border", self.class);
#endif
    
    layer.borderColor = [[UIColor whiteColor] CGColor];
    layer.borderWidth = 4.0f;
    
    if (shouldRasterize)
        layer.shouldRasterize = YES;
    
    if (withShadow)
    {
        layer.shadowOffset = CGSizeMake(0.0, 0.0);
        layer.shadowOpacity = 0.5;
        layer.shadowRadius = 2.0;
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#pragma mark - Notifications

- (void)sightingPhotoUpdated:(NSNotification *)aNotification
{
    logmethod();
    DDLogVerbose(@"%@: Sighting photo is updated", self.class);
    
    NSString *sightingUUID = (NSString *)[aNotification.userInfo objectForKey:@"sightingUUID"];
    if ([self.sightingUUID isEqualToString:sightingUUID])
    {
        self.photos = [[IOPhotoCollection alloc] init];
        
        __weak __typeof(self)weakSelf = self;
        [self.photos reSetTheUUID:sightingUUID withCallback:^(NSError *error) {
            if (![weakSelf.sightingUUID isEqualToString:sightingUUID])
            {
                // Bail out quickly if the cell has allready been re-purposed
                DDLogWarn(@"%@: Different sightingUUID: %@ <=> %@", weakSelf.class, weakSelf.sightingUUID, sightingUUID);
                // Note: self.photos will be reset by the new cell
                return;
            }
            
            if (weakSelf.photos.count > 0)
            {
                DDLogVerbose(@"%@: Update sighting image", weakSelf.class);
                UIImage *image = [weakSelf.photos photoAtIndex:0 forSize:CGSizeMake(90.0, 90.0)];
                [IOVolatileCache setObject:image forKey:sightingUUID];
                
                //[weakSelf setTheImage:image withShadow:(photos.count > 1)];
                [weakSelf setTheImage:image withShadow:NO];
            }
            /*
            else
                [weakSelf addLayerBorder:weakSelf.imageView.layer withShadow:NO andRasterize:NO];
            
            if (photos.count > 1)
                [weakSelf addBlankSubviews];
             */
            
            weakSelf.photos = nil;
        }];
    }
}

@end
