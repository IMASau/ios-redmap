//
//  IOCommonListingTVC.m
//  RedMap
//
//  Created by Evo Stamatov on 19/04/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOCommonListingTVC.h"
#import "IOAuth.h"
#import "IOSightingAttributesController.h"

@interface IOCommonListingTVC () <IOCommonListingDataSource>

@property (nonatomic, strong) NSIndexPath *previousSelectionIndexPath;
@property (nonatomic, strong) NSIndexPath *selectionIndexPath;

@end


@implementation IOCommonListingTVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.navigationTitle)
        self.navigationItem.title = self.navigationTitle;
    else if (self.listingKey)
        self.navigationItem.title = [self.listingKey stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[self.listingKey substringToIndex:1] uppercaseString]];
    else
        self.navigationItem.title = nil;
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    if (self.dataSource == nil)
    {
        self.dataSource = self;
        [self loadTheListing];
    }
    
    if (self.selectedValue || self.selectedTitle || self.selectedTitleContains)
        [self checkPreSelection];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}



- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.selectionIndexPath)
    {
        [self.tableView scrollToRowAtIndexPath:self.selectionIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
        self.selectionIndexPath = nil;
    }
}



- (void)loadTheListing
{
    if (self.listingContent == nil && self.listingKey != nil)
        self.listingContent = [[IOSightingAttributesController sharedInstance] entriesForCategory:self.listingKey];
}



#pragma mark - TableView
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([self.dataSource respondsToSelector:@selector(numberOfSections)])
        return [self.dataSource numberOfSections];
    
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.dataSource numberOfRowsInSection:section];
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CommonListingCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    NSDictionary *selection = [self.dataSource objectAtIndexPath:indexPath];
    
    if (selection)
    {
        cell.textLabel.text = selection.title;
        
        if ([self checkSelectionMatch:selection])
            [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        else
            [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    
    return cell;
}



#pragma mark IOCommonListingDataSource protocol

- (NSDictionary *)objectAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.listingContent objectAtIndex:indexPath.row];
}

- (NSInteger)numberOfRowsInSection:(NSInteger)section
{
    return [self.listingContent count];
}

- (NSInteger)numberOfSections
{
    return 1;
}



#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if (self.previousSelectionIndexPath)
    {
        cell = [tableView cellForRowAtIndexPath:self.previousSelectionIndexPath];
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    
    cell = [tableView cellForRowAtIndexPath:indexPath];
    [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *obj = [self.dataSource objectAtIndexPath:indexPath];
    
    self.selection = obj;
    self.navigationItem.rightBarButtonItem.enabled = YES;
    self.previousSelectionIndexPath = indexPath;
}



#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"ReturnListingInput"])
        [self.delegate acceptedSelection:self.selection];
    else if ([[segue identifier] isEqualToString:@"CancelInput"] && [self.delegate respondsToSelector:@selector(cancelled)])
        [self.delegate cancelled];
}



#pragma mark - Custom methods

- (BOOL)checkSelectionMatch:(NSDictionary *)selection
{
    return ((self.selectedValue && [selection.ID isEqual:self.selectedValue]) ||
        (self.selectedTitle && [selection.title isEqualToString:self.selectedTitle]) ||
        (self.selectedTitleContains && [selection.title rangeOfString:self.selectedTitleContains].location != NSNotFound)
    );
}



- (void)checkPreSelection
{
    int sectionsCount = [self.dataSource numberOfSections];
    for (int j = 0; j < sectionsCount; j++)
    {
        int entriesCount = [self.dataSource numberOfRowsInSection:j];
        for (int i = 0; i < entriesCount; i++)
        {
            NSDictionary *obj = (NSDictionary *)[self.dataSource objectAtIndexPath:[NSIndexPath indexPathForItem:i inSection:j]];
            
            if (obj == nil)
                return;
            
            if ([self checkSelectionMatch:obj])
            {
                self.selection = obj;
                self.selectionIndexPath = [NSIndexPath indexPathForItem:i inSection:j];
                self.previousSelectionIndexPath = self.selectionIndexPath;
                self.navigationItem.rightBarButtonItem.enabled = YES;
                return;
            }
        }
    }
}

@end
