//
//  AppDefines.h
//  RedMap
//
//  Created by Evo Stamatov on 13/05/13.
//  Copyright (c) 2013 Ionata. All rights reserved.
//

////////////////////////////////////////////////////////////////////////////////
// iOS7 detect
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
//#define iOS_7_OR_LATER                              SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7")

#define ENABLE_PONYDEBUGGER 0

////////////////////////////////////////////////////////////////////////////////
// App version
// use these to compare the REDMAP_TARGET_SETTINGS pre-processor macro (set in Build Settings)
#define RM_DEBUG   1
#define RM_RELEASE 2
#define RM_BETA    3
#define RM_VPN     4

////////////////////////////////////////////////////////////////////////////////
// Remote server selection
#define FORCE_LOCAL_SERVER 0
#define USE_STAGING_SERVER 0

#if FORCE_LOCAL_SERVER
    #define REDMAP_URL         @"http://10.66.77.146:8000/"
    #define API_BASE           @"10.66.77.146"
    #define API_PORT           8000
#else
    #if REDMAP_TARGET_SETTING == RM_VPN
        #define REDMAP_URL     @"http://staging.redmap.org.au/"
        #define API_BASE       @"staging.redmap.org.au"
    #elif USE_STAGING_SERVER
        #define REDMAP_URL     @"http://redmap.stage.aki.ionata.com/"
        #define API_BASE       @"redmap.stage.aki.ionata.com"
    #else
        #define REDMAP_URL     @"http://www.redmap.org.au/"
        #define API_BASE       @"www.redmap.org.au"
    #endif
    #define API_PORT           80
#endif

#define API_PATH @"api"
#define USE_SSL 0

////////////////////////////////////////////////////////////////////////////////
// Facebook login
#if USE_STAGING_SERVER
    #define FACEBOOK_APP_API_KEY @"POPULATE_THIS_WITH_YOUR_STAGE_API_KEY"                             // staging app
#else
    #define FACEBOOK_APP_API_KEY @"117379155094908"                             // live fb app
#endif

////////////////////////////////////////////////////////////////////////////////
// Analytics
#if FORCE_LOCAL_SERVER
    #define TRACK 0
#elif USE_STAGING_SERVER
    #define TRACK 0
#else
    #define TRACK 1
#endif

#if TRACK
    #define GA_TRACKING_ID @"UA-XXXXXXXX-X"
#endif

////////////////////////////////////////////////////////////////////////////////
// User Defaults
#define kIOUserDefaultsRegionKey         @"region"
#define kIOUserDefaultsRegionAutodetect  @"Autodetect"

#define kIOUserDefaultsModeKey           @"defaultMode"

#define kIOUserDefaultsServerBaseKey     @"currentServerBase"
#define kIOUserDefaultsServerPortKey     @"currentServerPort"
#define kIOUserDefaultsServerBaseDefault @"defaultServerBase"
#define kIOUserDefaultsServerPortDefault -1

#define kIOUserDefaultsLoggingEnabledKey @"loggingEnabled"

////////////////////////////////////////////////////////////////////////////////
// Console logging
#define DDLOG_LEVEL_GLOBAL LOG_LEVEL_VERBOSE
#define logmethod() { if (self) { DDLogVerbose(@"[%@: %@]", self.class, NSStringFromSelector(_cmd)); } else { DDLogWarn(@"NO SELF [%s]", __PRETTY_FUNCTION__); } }
