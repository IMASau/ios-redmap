//
//  IOLogger.h
//  Redmap
//
//  Created by Evo Stamatov on 4/03/2014.
//  Copyright (c) 2014 Ionata. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IOLogger;

extern NSString *const IOLoggerDidRemoveErrorLogsNotification;

/*!
 * A global logger class, for enabling/disabling error messages file logging.
 *
 * The only way to remove the log files is by cancelling the email view controller
 * and confirming the alert view popup.
 *
 * It is strongly advised to not remove the logs in any other way.
 */
@interface IOLogger : NSObject

/*!
 * A shared instance of the file logger.
 */
+ (instancetype)sharedInstance;

/*!
 * Starts the file logger.
 *
 * Will return YES if started logging and NO if logging was already happening.
 */
- (BOOL)startLogging;

/*!
 * Stops the file logger, but keeps the log files.
 *
 * Will return YES if stopped and NO if logging was already stopped.
 */
- (BOOL)stopLogging;

/*!
 * As the name imposes - tells whether the logger is logging or not.
 */
@property (nonatomic, readonly) BOOL logging;

/*!
 * Checks for log files and shows an email view controller with them attached as either txt or zip.
 *
 * Plain text is used if total file size is below 10Mb. Otherwise the will be zipped.
 * If total file size is more than 100Mb the logs will be automatically removed.
 */
- (void)emailAndRemoveLogFilesIfNeededFromViewController:(UIViewController *)viewController;

/*!
 * Checks for log files.
 */
- (BOOL)hasLogs;

@end
