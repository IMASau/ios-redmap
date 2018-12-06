//
//  IOCellConnection.h
//  RedMap
//
//  Created by Evo Stamatov on 2/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol IOCellConnection <NSObject>

- (void)acceptedSelection:(NSDictionary *)object;

@optional
- (void)cancelled;

@end
