//
//  IORedMapThemeManager.m
//  RedMap
//
//  Created by Evo Stamatov on 24/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IORedMapThemeManager.h"
#import "UIColor+IOColor.h"
#import "AppDelegate.h"
#import <CoreText/CoreText.h>

#define kIOMainTabBarSpotTag 510
#define kIOMainTabBarLogTag 520
#define kIOMainTabBarPersonalTag 530


@implementation IORedMapThemeManager

+ (UIImage *)buttonImageForButtonType:(IOButtonType)buttonType withBaseColor:(UIColor *)colorOrNil andState:(IOButtonState)state
{
    NSString *imageName;
    
    switch (buttonType) {
        case IOButtonTypeSpecial:
        case IOButtonTypeReset:
            imageName = @"uibutton-red";
            break;
            
        case IOButtonTypeTransparent:
        case IOButtonTypeClear:
            imageName = @"uibutton-clear";
            break;
            
        case IOButtonTypeNormal:
        default:
            imageName = @"uibutton-default";
            break;
    }
    
    if (state == IOButtonStateHighlight)
        imageName = [NSString stringWithFormat:@"%@-hl", imageName];
    
    UIEdgeInsets buttonInset = UIEdgeInsetsMake(15.0, 13.0, 15.0, 13.0);
    UIImage *image = [UIImage imageNamed:imageName];
    
    if ((buttonType == IOButtonTypeTransparent || buttonType == IOButtonTypeClear) && colorOrNil)
    {
        UIImage *mask = [UIImage imageNamed:@"uibutton-clear-mask"];
        image = [self image:image withBelowColor:colorOrNil andMaskImage:mask];
    }
    
    return [image resizableImageWithCapInsets:buttonInset resizingMode:UIImageResizingModeStretch];
}



+ (void)styleButton:(UIButton *)button asButtonType:(IOButtonType)buttonType withBaseColor:(UIColor *)colorOrNil
{
    assert(button.buttonType == UIButtonTypeCustom);
    
    UIEdgeInsets contentInset = UIEdgeInsetsMake(0.0, 0.0, 1.0, 0.0);
    [button setContentEdgeInsets:contentInset];
    
    UIImage *normalStateImage = [self buttonImageForButtonType:buttonType withBaseColor:colorOrNil andState:IOButtonStateNormal];
    UIImage *pressedStateImage = [self buttonImageForButtonType:buttonType withBaseColor:colorOrNil andState:IOButtonStateHighlight];
    
    [button setBackgroundImage:normalStateImage forState:UIControlStateNormal];
    [button setBackgroundImage:pressedStateImage forState:UIControlStateHighlighted];
}



+ (UIImage *)image:(UIImage *)image withBelowColor:(UIColor *)color andMaskImage:(UIImage *)mask
{
    if (!image)
        return nil;
    
    // TODO: for some reason the image height is 1px smaller
    CGSize size = image.size;
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [color setFill];
    
    CGContextTranslateCTM(context, 0, size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    
    if (mask)
        CGContextClipToMask(context, rect, mask.CGImage);
    
    CGContextAddRect(context, rect);
    CGContextDrawPath(context, kCGPathEOFill);
    CGContextDrawImage(context, rect, image.CGImage);
    
    UIImage *coloredImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return coloredImage;
}



+ (void)styleNormalButton:(UIButton *)button
{
    [self styleButton:button asButtonType:IOButtonTypeNormal withBaseColor:nil];
}



+ (void)styleSpecialButton:(UIButton *)button
{
    [self styleButton:button asButtonType:IOButtonTypeSpecial withBaseColor:nil];
}



+ (void)styleResetButton:(UIButton *)button
{
    [self styleButton:button asButtonType:IOButtonTypeReset withBaseColor:nil];
}



+ (void)styleButton:(UIButton *)button withCustomColor:(UIColor *)color
{
    [self styleButton:button asButtonType:IOButtonTypeTransparent withBaseColor:color];
}



+ (void)styleNavigationBarAppearance
{
    if (iOS_7_OR_LATER())
    {
        [[UINavigationBar appearance] setBackgroundColor:[UIColor IOBlueColor]];
        [[UINavigationBar appearance] setBarTintColor:[UIColor IOBlueColor]];
        
        /*
        NSDictionary *attributes = @{
                                     UITextAttributeTextColor: [UIColor whiteColor],
                                     UITextAttributeFont: [UIFont systemFontOfSize:13.f],
                                     };
        [[UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil] setTitleTextAttributes:attributes forState:UIControlStateNormal];
         */
        //set back button arrow color
        [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
        
        [[UIBarButtonItem appearance] setTintColor:[UIColor whiteColor]];
        
        NSDictionary *titleTextAttirbutes =
            @{
              NSFontAttributeName:[self scribblyFontWithFontSize:28.0f],
              NSForegroundColorAttributeName: [UIColor whiteColor]
              };
        [[UINavigationBar appearance] setTitleTextAttributes:titleTextAttirbutes];
        [[UINavigationBar appearance] setTitleVerticalPositionAdjustment:0.f forBarMetrics:UIBarMetricsDefault];
        
        return;
    }
    
    //UIImage *emptyImage = [[UIImage alloc] init];
    
    // Background
    //[[UINavigationBar appearance] setBackgroundImage:emptyImage forBarMetrics:UIBarMetricsDefault];
    //[[UINavigationBar appearance] setBackgroundColor:[UIColor IOBlueColor]];
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"uinavigationbar-background"] forBarMetrics:UIBarMetricsDefault];
    
    id appearance = [UIBarButtonItem appearance];
    
    UIEdgeInsets backButtonInset = UIEdgeInsetsMake(15.0, 21.0, 15.0, 13.0);
    
     // Back button
    UIImage *normalStateBackImage = [[UIImage imageNamed:@"uibutton-back"] resizableImageWithCapInsets:backButtonInset];
    UIImage *pressedStateBackImage = [[UIImage imageNamed:@"uibutton-back-hl"] resizableImageWithCapInsets:backButtonInset];
    [appearance setBackButtonBackgroundImage:normalStateBackImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [appearance setBackButtonBackgroundImage:pressedStateBackImage forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
    
    
    // Normal button
    UIImage *normalStateImage = [self buttonImageForButtonType:IOButtonTypeNormal withBaseColor:nil andState:IOButtonStateNormal];
    UIImage *pressedStateImage = [self buttonImageForButtonType:IOButtonTypeNormal withBaseColor:nil andState:IOButtonStateHighlight];
    [appearance setBackgroundImage:normalStateImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [appearance setBackgroundImage:pressedStateImage forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
    
    // Done button style
    UIImage *redButtonImage = [self buttonImageForButtonType:IOButtonTypeReset withBaseColor:nil andState:IOButtonStateNormal];
    UIImage *pressedRedButtonImage = [self buttonImageForButtonType:IOButtonTypeReset withBaseColor:nil andState:IOButtonStateHighlight];
    [appearance setBackgroundImage:redButtonImage forState:UIControlStateNormal style:UIBarButtonItemStyleDone barMetrics:UIBarMetricsDefault];
    [appearance setBackgroundImage:pressedRedButtonImage forState:UIControlStateHighlighted style:UIBarButtonItemStyleDone barMetrics:UIBarMetricsDefault];
    
    NSDictionary *titleTextAttirbutes = @{
                                          NSFontAttributeName:[self scribblyFontWithFontSize:28.0f],
                                          };
    [[UINavigationBar appearance] setTitleTextAttributes:titleTextAttirbutes];
    [[UINavigationBar appearance] setTitleVerticalPositionAdjustment:-3.0f forBarMetrics:UIBarMetricsDefault];
}



+ (void)styleSegmentedControlAppearance
{
    /*
    UISegmentedControl *appearance = [UISegmentedControl appearance];
    [appearance setBackgroundImage:[UIImage imageNamed:@"uisegmentedcontrol-background"] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [appearance setBackgroundImage:[UIImage imageNamed:@"uisegmentedcontrol-background-selected"] forState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
    
    [appearance setDividerImage:[UIImage imageNamed:@"uisegmentedcontrol-divider"] forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
     */
}



//[mEditTableView setBackgroundView:nil];
//[mEditTableView setBackgroundView:[[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"apple.png"]] autorelease]];


+ (void)styleTableViewCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath as:(IOTableViewStyle)style
{
    //cell.backgroundView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"cell_normal.png"] stretchableImageWithLeftCapWidth:0.0 topCapHeight:5.0]];
    cell.selectedBackgroundView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"uitableviewcell-background-hl.png"] stretchableImageWithLeftCapWidth:0.0 topCapHeight:5.0]];
    
    /*
    if (cell.accessoryType == UITableViewCellAccessoryDisclosureIndicator)
    {
        NSString* disclosureImageName = @"uitableviewcell-disclosure";
        if (cell.selectionStyle == UITableViewCellSelectionStyleGray)
            disclosureImageName = @"uitableviewcell-disclosure-filled";
    
        UIImageView *disclosureImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:disclosureImageName]];
        disclosureImageView.highlightedImage = [UIImage imageNamed:[NSString stringWithFormat:@"%@-hl", disclosureImageName]];
        cell.accessoryView = disclosureImageView;
    }
     */
    
    if (style == IOTableViewStyleWithBackground)
    {
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"uitableview-background"]];
        [cell addSubview:[self separatorViewForFrame:cell.frame width:cell.frame.size.width - 26.0]];
    }
}



+ (void)styleTableView:(UITableView *)tableView as:(IOTableViewStyle)style
{
    if (tableView.separatorStyle == UITableViewCellSeparatorStyleSingleLine)
        [tableView setSeparatorColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"uitableview-separator"]]];
}



+ (UIFont *)scribblyFontWithFontSize:(CGFloat)fontSize
{
    // AlphaMack AOE - AlphaMackAOE
    return [UIFont fontWithName:@"AlphaMackAOE" size:fontSize];
}



+ (UIFont *)scribblyFont
{
    return [self scribblyFontWithFontSize:35.0f];
}



+ (void)styleTabBar:(UITabBar *)tabBar
{
    for (int i = 0, maxI = tabBar.items.count; i < maxI; i++)
    {
        UITabBarItem *item = [tabBar.items objectAtIndex:i];

        [item setTitlePositionAdjustment:UIOffsetMake(0, 0)];
        [item setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateNormal];
        [item setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor IORedColor]} forState:UIControlStateSelected];
        
        [item setImage:[item.image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        [item setSelectedImage:[item.selectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    }

}



+ (UIView *)separatorViewForFrame:(CGRect)frame width:(CGFloat)width
{
    CGFloat padding = (frame.size.width - width) * 0.5;
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(padding, frame.size.height - 1.0, width, 1.0)];
    separator.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"uitableview-separator"]];
    return separator;
}



+ (CGFloat)tableView:(UITableView *)tableView dataSource:(id <UITableViewDataSource>)dataSource heightForHeaderInSection:(NSInteger)section
{
    NSString *title = [dataSource tableView:tableView titleForHeaderInSection:section];
    if (!title)
        return 0.0;
    
    return 23.0;
}



+ (UIView *)tableView:(UITableView *)tableView dataSource:(id <UITableViewDataSource>)dataSource viewForHeaderInSection:(NSInteger)section
{
    NSString *title = [dataSource tableView:tableView titleForHeaderInSection:section];
    if (!title)
        return nil;
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, tableView.frame.size.width, 23.0)];
    view.backgroundColor = [[UIColor colorWithPatternImage:[UIImage imageNamed:@"uitableview-background"]] colorWithAlphaComponent:0.9];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(23.0, 0.0, tableView.frame.size.width - 36.0, 23.0)];
    label.opaque = NO;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor IORedColor];
    label.font = [UIFont boldSystemFontOfSize:20.0];
    label.text = title;
    
    [view addSubview:label];
    [view addSubview:[self separatorViewForFrame:view.frame width:view.frame.size.width - 26.0]];
    
    return view;
}

@end
