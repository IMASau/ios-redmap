//
//  MockCategoriesDataSource.m
//  RedMap
//
//  Created by Evo Stamatov on 26/03/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "MockCategoriesDataSource.h"

@implementation MockCategoriesDataSource

- (id)init
{
    if (self = [super init])
    {
        mockCategories = [NSArray array];
    }
    return self;
}



- (void)loadEntries
{
    NSURL *plistFile = [[NSBundle mainBundle] URLForResource:@"Mocks" withExtension:@"plist"];
    NSDictionary *plist = [[NSMutableDictionary alloc] initWithContentsOfURL:plistFile];
    mockCategories = (NSArray *)[plist objectForKey:@"Categories"];
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [mockCategories count];
}



- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SpotCell";
    UITableViewCell *cell;
    
    cell = [tv dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];

    UILabel *textLabel;

    //IOLog(@"Using Mocks");
    
    textLabel = (UILabel *)[cell viewWithTag:1];
    textLabel.text = (NSString *)[mockCategories objectAtIndex:[indexPath row]];
    
    [[cell viewWithTag:4] setHidden:YES];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;

    UIActivityIndicatorView *activityIndicator;
    activityIndicator = (UIActivityIndicatorView *)[cell viewWithTag:3];
    [activityIndicator startAnimating];
    
    activityIndicator = (UIActivityIndicatorView *)[cell viewWithTag:5];
    [activityIndicator startAnimating];
    
    return cell;
}



- (NSIndexPath *)tableView: (UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

@end
