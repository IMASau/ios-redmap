//
//  functions.m
//  Redmap
//
//  Created by Evo Stamatov on 25/02/2014.
//  Copyright (c) 2014 Ionata. All rights reserved.
//

#include <Foundation/Foundation.h>
#import "functions.h"

BOOL iOS_7_OR_LATER() {
    return !(floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1);
}
