//
//  IOBaseCellController.m
//  Redmap
//
//  Created by Evo Stamatov on 16/08/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import "IOBaseCellController.h"

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

@interface IOBaseCellController ()
{
    BOOL _dirty;
}

@property (nonatomic, assign, readwrite) BOOL marked;

@end


@implementation IOBaseCellController

#pragma mark - IOCellControllerConnection Protocol

- (id)initWithSettings:(NSDictionary *)settings delegate:(id <IOBaseCellControllerDelegate>)delegate
{
    self = [super init];
    if (self)
    {
        _settings = settings;
        _delegate = delegate;
        if (_settings)
        {
            if (_settings[kIOLVCManagedObjectKey])
                _managedObjectKey = _settings[kIOLVCManagedObjectKey];
            else if (_settings[kIOLVCManagedObjectKeys])
                _managedObjectKeys = _settings[kIOLVCManagedObjectKeys];
        }
    }
    return self;
}



- (void)configureTableViewCell:(IOBaseCell *)cell
{
    self.connectedTableViewCell = cell;
}



- (void)didSelectTableViewCell:(IOBaseCell *)cell
{
    DDLogVerbose(@"%@: Should implement didSelectTableViewCell: method in the child class!", self.class);
}



- (void)didEndDisplayingTableViewCell:(IOBaseCell *)cell
{
    self.connectedTableViewCell = nil;
    
    [cell didEndDisplay];
}



- (void)willDisplayTableViewCell:(IOBaseCell *)cell
{
    self.connectedTableViewCell = cell;
    
    cell.marked = _marked;
    
    [cell willDisplay];
}



- (BOOL)marked
{
    if (self.connectedTableViewCell)
        self.connectedTableViewCell.marked = _marked;
    
    return _marked;
}



- (void)markTableViewCell:(IOBaseCell *)cell
{
    _marked = YES;
    if (cell)
        [cell setMarked:_marked animated:YES];
    else
        [self.connectedTableViewCell setMarked:_marked animated:YES];
}



- (void)unmarkTableViewCell:(IOBaseCell *)cell
{
    _marked = NO;
    if (cell)
        [cell setMarked:_marked animated:YES];
    else
        [self.connectedTableViewCell setMarked:_marked animated:YES];
}



- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    DDLogVerbose(@"%@: Should implement prepareForSegue:sender: method in the child class!", self.class);
}



- (BOOL)isDirty
{
    return _dirty;
}



- (id)managedObjectValue
{
    if (self.managedObjectKey && [self.delegate respondsToSelector:@selector(getManagedObjectDataForKey:)])
        return [self.delegate getManagedObjectDataForKey:self.managedObjectKey];
    
    return nil;
}



- (void)setManagedObjectValue:(id)managedObjectValue
{
    if (self.managedObjectKey && [self.delegate respondsToSelector:@selector(setManagedObjectDataForKey:withObject:)])
        [self.delegate setManagedObjectDataForKey:self.managedObjectKey withObject:managedObjectValue];
}



#pragma mark - IOCellConnection Protocol

- (void)acceptedSelection:(NSDictionary *)object
{
    _dirty = YES;
}

@end
