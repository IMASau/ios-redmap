//
//  IOCommonListingDataSource.h
//  RedMap
//
//  Created by Evo Stamatov on 18/06/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol IOCommonListingDataSource <NSObject>

- (NSInteger)numberOfRowsInSection:(NSInteger)section;
- (NSDictionary *)objectAtIndexPath:(NSIndexPath *)indexPath;

@optional
- (NSInteger)numberOfSections;

@end
