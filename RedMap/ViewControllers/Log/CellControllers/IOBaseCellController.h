//
//  IOBaseCellController.h
//  Redmap
//
//  Created by Evo Stamatov on 16/08/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IOLoggingViewController-defines.h"
#import "IOBaseCell.h"
#import "IOCellConnection.h"

////////////
// Protocols
////////////

@protocol IOBaseCellControllerDelegate <NSObject>

- (id)getManagedObjectDataForKey:(NSString *)key;
- (void)setManagedObjectDataForKey:(NSString *)key withObject:(id)object;

@optional
- (void)setManagedObjectDataWithKeyValueDictionary:(NSDictionary *)dictionary;  // this method is optional, since not all cell controllers require a bulk option
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (id)instantiateViewControllerWithIdentifier:(NSString *)identifier;
- (void)setHidesBottomBarWhenPushed:(BOOL)hidden;

@end



@protocol IOCellControllerConnection <NSObject>

- (id)initWithSettings:(NSDictionary *)settings delegate:(id <IOBaseCellControllerDelegate>)delegate;
- (void)configureTableViewCell:(IOBaseCell *)cell;
- (void)didSelectTableViewCell:(IOBaseCell *)cell;
- (void)markTableViewCell:(IOBaseCell *)cell;                                   // don't forget to call super to set self.marked
- (void)unmarkTableViewCell:(IOBaseCell *)cell;                                 // don't forget to call super to set self.marked
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender;
- (BOOL)isDirty;

@optional
- (void)willDisplayTableViewCell:(IOBaseCell *)cell;
- (void)didEndDisplayingTableViewCell:(IOBaseCell *)cell;

@end



///////////////////////
// IOBaseCellController
///////////////////////

@interface IOBaseCellController : NSObject <IOCellControllerConnection, IOCellConnection>

// IOCellControllerConnection
- (id)initWithSettings:(NSDictionary *)settings delegate:(id <IOBaseCellControllerDelegate>)delegate;
- (void)configureTableViewCell:(IOBaseCell *)cell;
- (void)didSelectTableViewCell:(IOBaseCell *)cell;
- (void)markTableViewCell:(IOBaseCell *)cell;                                   // should be called after configureTableViewCell have fired
- (void)unmarkTableViewCell:(IOBaseCell *)cell;                                 // should be called after configureTableViewCell have fired
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender;
- (BOOL)isDirty;

- (void)willDisplayTableViewCell:(IOBaseCell *)cell;
- (void)didEndDisplayingTableViewCell:(IOBaseCell *)cell;

// IOCellConnection
- (void)acceptedSelection:(NSDictionary *)object;

// NOTE: you sould not have both managedObjectKey and managedObjectKeys set at the same time !!!
@property (nonatomic, copy) NSString *managedObjectKey;
@property (nonatomic, retain) id managedObjectValue;                            // gets and sets the managedObject's value, based on managedObjectKey

@property (nonatomic, copy) NSDictionary *managedObjectKeys;                    // you'll have to manage yourself the getter and setter of the values

@property (nonatomic, readonly) BOOL initialized;

@property (nonatomic, weak) id <IOBaseCellControllerDelegate> delegate;
@property (nonatomic, strong) NSDictionary *settings;
@property (nonatomic, readonly) BOOL marked;
@property (nonatomic, weak) IOBaseCell *connectedTableViewCell;

@end
