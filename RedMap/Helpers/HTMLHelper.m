
//  HTMLHelper.m
//  RedMap
//
//  Created by Evo Stamatov on 26/03/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "HTMLHelper.h"
#import "IOMainTabBarViewController.h"
#import <GRMustache.h>

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

@interface HTMLHelper ()// <IOHomeViewControllerDelegate>

@property (nonatomic, weak) UIWebView *webView;
@property (nonatomic, strong) NSURLRequest *request;

@end


@implementation HTMLHelper

- (void)viewDidLoad
{
    logmethod();
    [super viewDidLoad];
    
    if (!self.webViewBaseUrl)
    {
        //self.webViewBaseUrl = REDMAP_URL;
        
        NSString *path = [[NSBundle mainBundle] bundlePath];
        NSURL *baseURL = [NSURL fileURLWithPath:path];
        self.webViewBaseUrl = baseURL;
    }
    
    if (!self.htmlFile || [self.htmlFile isEqualToString:@""])
    {
        DDLogError(@"%@: ERROR. No or empty htmlFile value is set as a RunTime Attribute!", self.class);
        return;
    }
    
    if (self.webViewTag && self.webViewTag > 0)
    {
        id subView = [self.view viewWithTag:[self.webViewTag intValue]];
        if ([subView class] == [UIWebView class])
            self.webView = (UIWebView *)subView;
    }
    else
        for (UIView *subView in self.view.subviews)
            if ([subView isKindOfClass:[UIWebView class]])
            {
                self.webView = (UIWebView *)subView;
                break;
            }
    
    if (!self.webView)
    {
        DDLogError(@"%@: ERROR. The webViewTag provided does not point to a UIWebView or no UIWebView found in the view's subviews.", self.class);
        return;
    }
    
    self.webView.delegate = self;
    self.webView.backgroundColor = [UIColor grayColor];
    
    NSString *name = [[self.htmlFile lastPathComponent] stringByDeletingPathExtension];
    NSString *type = [self.htmlFile pathExtension];
    
    self.navigationItem.title = NSLocalizedString(@"Loading...", @"The navigation title when loading an html file from the app bundle");
    
    __weak HTMLHelper *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [weakSelf loadHTMLFileWithName:name ofType:type withBaseURL:weakSelf.webViewBaseUrl];
    });
}



- (void)didReceiveMemoryWarning
{
    logmethod();
    [super didReceiveMemoryWarning];
}



- (void)loadHTMLFileWithName:(NSString *)filename ofType:(NSString *)type withBaseURL:(NSURL *)baseURL
{
    logmethod();
    NSString *htmlFile = [[NSBundle mainBundle] pathForResource:filename ofType:type];
    
    NSError *error = nil;
    NSString *html = [NSString stringWithContentsOfFile:htmlFile
                                               encoding:NSUTF8StringEncoding
                                                  error:&error];
    
    if (!error)
    {
        NSString *rendering = [GRMustacheTemplate renderObject:@{
                                                                 @"REDMAP_URL": REDMAP_URL,
                                                                 @"API_BASE": API_BASE
                                                                 } fromString:html error:NULL];

        [self.webView loadHTMLString:rendering baseURL:baseURL];
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error alert title when loading the html file")
                                                            message:NSLocalizedString(@"Could not load the web page contents", @"Error alert message")
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"OK", @"Error alert dismiss button title")
                                                  otherButtonTitles:nil];
            [alert show];
        });
    }
}



#pragma mark - UIWebView delegate

// Open links in Safari

- (BOOL)webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType
{
    logmethod();
    if (inType == UIWebViewNavigationTypeLinkClicked)
    {
        //[inWeb stopLoading];
        NSString *scheme, *selectorString, *argumentString = nil;
		scheme = [[inRequest URL] scheme];
        selectorString = [[inRequest URL] host];
        argumentString = [[inRequest URL] fragment];
        
		if ([scheme isEqualToString: @"redmap"])
        {
			if ([selectorString isEqual: @"spot"])
            {
                IOMainTabBarViewController *vc = (IOMainTabBarViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"MainTabBarViewControllerSBID"];
                vc.homeViewController = self;
                [vc setSelectedIndex:SPOT_TAB_INDEX];
                
                self.hideNavBarWhenDisappearing = YES;
                
                [self.navigationController pushViewController:vc animated:YES];
			}
            else if ([selectorString isEqual: @"log"])
            {
                IOMainTabBarViewController *vc = (IOMainTabBarViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"MainTabBarViewControllerSBID"];
                vc.homeViewController = self;
                [vc setSelectedIndex:LOG_TAB_INDEX];
                
                self.hideNavBarWhenDisappearing = YES;
                
                [self.navigationController pushViewController:vc animated:YES];
			}
		}
        else
        {
            if ([[[inRequest URL] absoluteString] isEqualToString:@"http://www.facebook.com/RedmapAustralia"])
            {
                //NSString *fbPage = [NSString stringWithFormat:@"fb://page/%@", [[inRequest URL] lastPathComponent]];
                NSString *fbPage = @"fb://profile/121764204502516";
                if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:fbPage]])
                {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fbPage]];
                    return NO;
                }
            }
            
            [[UIApplication sharedApplication] openURL:[inRequest URL]];
            /*
            // If we want to show an alert to confirm the app switch
            self.request = inRequest;
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"You are about to leave the app to follow the link." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"Cancel", nil];
            [alert show];
             */
        }
        
        return NO;
    }
    
    return YES;
}



- (void)webViewDidFinishLoad:(UIWebView *)aWebView
{
    logmethod();
    NSString *webPageTitle = [aWebView stringByEvaluatingJavaScriptFromString:@"document.title;"];
    self.navigationItem.title = NSLocalizedString(webPageTitle, @"The navigation title when loaded the html file's title from the html document");
}



#pragma mark - UIAlertView delegate

/*
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"OK"])
        [[UIApplication sharedApplication] openURL:[self.request URL]];
    
    self.request = nil;
}
 */



#pragma mark - IOHomeTableViewControllerProtocol

- (void)goHome
{
    logmethod();
    [self.navigationController popViewControllerAnimated:YES];
}

@end
