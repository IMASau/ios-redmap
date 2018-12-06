//
//  User-typedefs.h
//  RedMap
//
//  Created by Evo Stamatov on 25/06/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

#ifndef RedMap_User_typedefs_h
#define RedMap_User_typedefs_h

typedef NS_ENUM(NSInteger, IOAuthUserStatus) {
    IOAuthUserStatusUnknown = 0,
    IOAuthUserStatusLocalLogin,
    IOAuthUserStatusLocalRegistration,
    IOAuthUserStatusFacebookLogin,
    IOAuthUserStatusServerAuthenticated,
    IOAuthUserStatusInSyncWithServer
};

#endif
