//
//  HTMLHelper.h
//  RedMap
//
//  Created by Evo Stamatov on 26/03/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IOViewController.h"
#import "IOHomeTableViewControllerProtocol.h"

@interface HTMLHelper : IOViewController <UIWebViewDelegate, IOHomeTableViewControllerProtocol>

@property (nonatomic, copy) NSString *htmlFile; // requires an html filename from within the bundle

// optional
@property (nonatomic, assign) NSNumber *webViewTag; // if not provided traverses the view for a UIWebView
@property (nonatomic, copy) NSURL *webViewBaseUrl; // defaults to local bundle

@end
