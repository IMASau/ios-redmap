//
//  IORedMapThemeManager.h
//  RedMap
//
//  Created by Evo Stamatov on 24/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, IOButtonType) {
    IOButtonTypeNormal = 0,
    IOButtonTypeSpecial,
    IOButtonTypeReset,
    IOButtonTypeTransparent,
    IOButtonTypeClear
};

typedef NS_ENUM(NSInteger, IOButtonState) {
    IOButtonStateNormal = 0,
    IOButtonStateHighlight
};

typedef NS_ENUM(NSInteger, IOTableViewStyle) {
    IOTableViewStylePlain = 0,
    IOTableViewStyleWithBackground
};

@interface IORedMapThemeManager : NSObject

+ (void)styleButton:(UIButton *)button asButtonType:(IOButtonType)buttonType withBaseColor:(UIColor *)colorOrNil;
+ (void)styleNormalButton:(UIButton *)button;
+ (void)styleSpecialButton:(UIButton *)button;
+ (void)styleResetButton:(UIButton *)button;
+ (void)styleButton:(UIButton *)button withCustomColor:(UIColor *)color;

+ (void)styleNavigationBarAppearance;

+ (void)styleSegmentedControlAppearance;

+ (void)styleTableView:(UITableView *)tableView as:(IOTableViewStyle)style;
+ (void)styleTableViewCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath as:(IOTableViewStyle)style;
+ (UIView *)separatorViewForFrame:(CGRect)frame width:(CGFloat)width;
+ (CGFloat)tableView:(UITableView *)tableView dataSource:(id <UITableViewDataSource>)dataSource heightForHeaderInSection:(NSInteger)section;
+ (UIView *)tableView:(UITableView *)tableView dataSource:(id <UITableViewDataSource>)dataSource viewForHeaderInSection:(NSInteger)section;

+ (UIFont *)scribblyFont; // defaults to font size of 35 points
+ (UIFont *)scribblyFontWithFontSize:(CGFloat)fontSize;

+ (void)styleTabBar:(UITabBar *)tabBar;

@end
