//
//  IOLogger.m
//  Redmap
//
//  Created by Evo Stamatov on 4/03/2014.
//  Copyright (c) 2014 Ionata. All rights reserved.
//

#import "IOLogger.h"
#import <DDFileLogger.h>
#import <MessageUI/MessageUI.h>
#import <zipzap.h>

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;
NSString *const IOLoggerDidRemoveErrorLogsNotification = @"IOLoggerDidRemoveErrorLogsNotification";
typedef void (^EmailErrorLogBlock)(NSData *errorLog, NSString *mimeType, NSString *fileName);

@interface IOLogger () <MFMailComposeViewControllerDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) DDFileLogger *fileLogger;
@property (nonatomic, weak) UIViewController *presentingViewController;
@property (nonatomic, readwrite) BOOL logging;

@end

////////////////////////////////////////////////////////////////////////////////
@implementation IOLogger
{
    UIAlertView *_genericAlertView;
    UIAlertView *_errorLogAlertView;
    UIAlertView *_deleteLogsAlertView;
    void (^_emailErrorLog)();
}

////////////////////////////////////////////////////////////////////////////////
+ (instancetype)sharedInstance
{
    static IOLogger *instance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [IOLogger new];
    });
    
    return instance;
}

////////////////////////////////////////////////////////////////////////////////
- (BOOL)startLogging
{
    if (self.logging)
    {
        DDLogVerbose(@"%@: No need to start logging, since we are already doing so", self.class);
        return NO;
    }
    
    self.logging = YES;
    DDFileLogger *fileLogger = [DDFileLogger new];
    fileLogger.rollingFrequency = 60 * 60 * 24;
    
    [DDLog addLogger:fileLogger withLogLevel:LOG_LEVEL_VERBOSE];
    
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString *buildNumber = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    DDLogVerbose(@"Redmap iOS app v%@ (%@)", appVersion, buildNumber);
    
    DDLogVerbose(@"Device: %@, %@ %@", [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemName], [[UIDevice currentDevice] systemVersion]);
    DDLogVerbose(@"Multitasking: %@", [[UIDevice currentDevice] isMultitaskingSupported] ? @"YES": @"NO");
    
    DDLogVerbose(@"---===---");
    DDLogVerbose(@"%@: File logger initialised.", self.class);
    
    self.fileLogger = fileLogger;
    return YES;
}

////////////////////////////////////////////////////////////////////////////////
- (BOOL)stopLogging
{
    if (self.fileLogger != nil && self.logging)
    {
        DDLogVerbose(@"---===---");
        DDLogVerbose(@"%@: File logger stopped.", self.class);
        [DDLog removeLogger:self.fileLogger];
        self.fileLogger = nil;
        self.logging = NO;
        return YES;
    }
    else
    {
        DDLogVerbose(@"%@: No need to stop logging, since we aren't doing so", self.class);
        return NO;
    }
}

////////////////////////////////////////////////////////////////////////////////
- (void)emailAndRemoveLogFilesIfNeededFromViewController:(UIViewController *)viewController
{
    if ([self hasLogs])
    {
        DDLogInfo(@"%@: Found log files.", self.class);
        DDLogInfo(@"%@: Attempting to email them.", self.class);
        
        [self composeEmailWithDebugAttachmentOnViewController:viewController];
    }
}

////////////////////////////////////////////////////////////////////////////////
- (BOOL)hasLogs
{
    DDFileLogger *fileLogger = self.fileLogger;
    if (fileLogger == nil)
        fileLogger = [DDFileLogger new];
    
    NSArray *sortedLogFileInfos = [fileLogger.logFileManager sortedLogFileInfos];
    return (sortedLogFileInfos.count > 0);
}

#pragma mark -
#pragma mark - Private methods

////////////////////////////////////////////////////////////////////////////////
- (id)init
{
    self = [super init];
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

////////////////////////////////////////////////////////////////////////////////
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

////////////////////////////////////////////////////////////////////////////////
- (void)applicationDidEnterBackground
{
    if (_genericAlertView)
    {
        [_genericAlertView dismissWithClickedButtonIndex:_genericAlertView.cancelButtonIndex animated:NO];
        _genericAlertView.delegate = nil;
        _genericAlertView = nil;
    }
    
    if (_errorLogAlertView)
    {
        [_errorLogAlertView dismissWithClickedButtonIndex:_errorLogAlertView.cancelButtonIndex animated:NO];
        _errorLogAlertView.delegate = nil;
        _errorLogAlertView = nil;
        self.presentingViewController = nil;
        _emailErrorLog = nil;
    }
    
    if (_deleteLogsAlertView)
    {
        [_deleteLogsAlertView dismissWithClickedButtonIndex:_deleteLogsAlertView.cancelButtonIndex animated:NO];
        _deleteLogsAlertView.delegate = nil;
        _deleteLogsAlertView = nil;
    }
}

////////////////////////////////////////////////////////////////////////////////
- (NSMutableArray *)errorLogData
{
    DDFileLogger *fileLogger = self.fileLogger;
    if (fileLogger == nil)
        fileLogger = [DDFileLogger new];
    
    NSUInteger maximumLogFilesToReturn = MIN(fileLogger.logFileManager.maximumNumberOfLogFiles, 10);
    NSMutableArray *errorLogFiles = [NSMutableArray arrayWithCapacity:maximumLogFilesToReturn];
    NSArray *sortedLogFileInfos = [fileLogger.logFileManager sortedLogFileInfos];
    
    for (int i = 0; i < MIN(sortedLogFileInfos.count, maximumLogFilesToReturn); i++) {
        DDLogFileInfo *logFileInfo = [sortedLogFileInfos objectAtIndex:i];
        NSData *fileData = [NSData dataWithContentsOfFile:logFileInfo.filePath];
        [errorLogFiles addObject:fileData];
    }
    
    return errorLogFiles;
}

////////////////////////////////////////////////////////////////////////////////
- (void)composeEmailWithDebugAttachmentOnViewController:(UIViewController *)viewController
{
    if ([MFMailComposeViewController canSendMail])
    {
        NSUInteger maxFileSize = 10 * 1048576;
        NSUInteger absoluteMaxFileSize = 100 * 1048576;
        
        NSMutableData *errorLogData = [NSMutableData data];
        for (NSData *errorLogFileData in [self errorLogData])
            [errorLogData appendData:errorLogFileData];
        
        if ([errorLogData length] > absoluteMaxFileSize)
        {
            DDLogError(@"%@: ERROR. Extremely big log file", self.class);
            
            NSString *message = NSLocalizedString(@"Sorry, your log file was extremely big (>%gMb) and was removed. Please, re-enable logging and re-create the issue, then disable logging to send the collected data.", @"");
            message = [NSString stringWithFormat:message, absoluteMaxFileSize / 1048576.0];
            _genericAlertView = [[UIAlertView alloc] initWithTitle:nil
                                                           message:message
                                                          delegate:nil
                                                 cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                                 otherButtonTitles:nil];
            [_genericAlertView show];
            
            [self removeLogFiles];
            return;
        }
        
        MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
        mailViewController.mailComposeDelegate = self;
        
        NSString *errorLogMimeType = @"text/plain";
        NSString *errorLogFilename = @"serviceLog.txt";
        NSArray *recipientsEmails = @[@"evo@ionata.com.au"];
        self.presentingViewController = viewController;
        
        EmailErrorLogBlock localEmailErrorLog = ^(NSData *errorLog, NSString *mimeType, NSString *fileName) {
            NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
            NSString *buildNumber = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
            [mailViewController addAttachmentData:errorLog mimeType:mimeType fileName:fileName];
            [mailViewController setSubject:[NSString stringWithFormat:NSLocalizedString(@"Service log -- Redmap iOS app v%@ (%@)", @"Email subject line. Doubles as view controller's navigation bar title."), appVersion, buildNumber]];
            [mailViewController setToRecipients:recipientsEmails];
            
            NSNumberFormatter *nf = [NSNumberFormatter new];
            [nf setNumberStyle:NSNumberFormatterDecimalStyle];
            NSString *messageBody = [NSString stringWithFormat:NSLocalizedString(@"See attached service log: %@ (%@ bytes)", @"Email message plain text body."), fileName, [nf stringFromNumber:@(errorLog.length)]];
            [mailViewController setMessageBody:messageBody isHTML:NO];
            
            [viewController presentViewController:mailViewController animated:YES completion:nil];
        };
        
        if ([errorLogData length] > maxFileSize)
        {
            DDLogInfo(@"%@: Service log is too large to email as plain text.", self.class);
            DDLogInfo(@"%@: Attempting to compress it.", self.class);
            NSMutableData *compressedErrorLogData = [self compressData:errorLogData];
            
            if (![compressedErrorLogData isEqual:errorLogData])
            {
                DDLogInfo(@"%@: Successfully compressed it.", self.class);
                errorLogMimeType = @"application/zip";
                errorLogFilename = @"serviceLog.zip";
            }
            else
            {
                DDLogError(@"%@: ERROR. Failed to compress it.", self.class);
                DDLogInfo(@"%@: Will send it as plain text.", self.class);
            }
            
            if ([compressedErrorLogData length] > maxFileSize)
            {
                DDLogInfo(@"%@: Service log is too large to email even when compressed.", self.class);
                DDLogInfo(@"%@: Showing an alert for confirmation.", self.class);
                
                NSString *message = NSLocalizedString(@"You are about to email a log file, which is larger than %gMb. Make sure your email service can handle attachments of %.2fMb in size.", @"");
                message = [NSString stringWithFormat:message, maxFileSize / 1048576.0, compressedErrorLogData.length / 1048576.0];
                _errorLogAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure?", @"Title of alert view when zipped log is bigger than allowed maximum file size.")
                                                                message:message
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"Don't send", @"Cancel title of alert view when zipped log is bigger than allowed maximum file size.")
                                                      otherButtonTitles:NSLocalizedString(@"Yes", @"Agree title of alert view when zipped log is bigger than allowed maximum file size."), nil];
                [_errorLogAlertView show];
                _emailErrorLog = ^{ // Love blocks!
                    localEmailErrorLog(errorLogData, errorLogMimeType, errorLogFilename);
                };
            }
            else
                localEmailErrorLog(errorLogData, errorLogMimeType, errorLogFilename);
        }
        else
            localEmailErrorLog(errorLogData, errorLogMimeType, errorLogFilename);
    }
    else
    {
        DDLogError(@"%@: ERROR. No email accounts are setup on the device.", self.class);
        NSString *message = NSLocalizedString(@"Sorry, your service log can't be reported right now. This is most likely because no mail accounts are set up on your mobile device. Open up the Settings app and add an email account.", @"");
        
        _genericAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Service log reporting", @"Title of alert view when no mail accounts are set up.")
                                                       message:message
                                                      delegate:nil
                                             cancelButtonTitle:NSLocalizedString(@"OK", @"Cancel title of alert view when no mail accounts are set up.")
                                             otherButtonTitles:nil];
        [_genericAlertView show];
    }
}

////////////////////////////////////////////////////////////////////////////////
- (NSMutableData *)compressData:(NSMutableData *)data
{
    // TODO: test if the new version actually works - no ZZMutableArchive
    NSError *error = nil;
    ZZArchive *newArchive = [ZZArchive archiveWithData:[NSMutableData new] error:&error];
    
    NSError *archiveError = nil;
    if (![newArchive updateEntries:@[
                                     [ZZArchiveEntry archiveEntryWithFileName:@"serviceLog.txt"
                                                                     compress:YES
                                                                    dataBlock:^NSData *(NSError *__autoreleasing *error) {
                                                                        return data;
                                                                    }]
                                     ]
                             error:&archiveError])
    {
        NSString *logMessage = [NSString stringWithFormat:@"%@: Compression error[%d]: %@", self.class, [archiveError code], [archiveError localizedDescription]];
        DDLogError(logMessage);
        
        // actually append the compression error message
        [data appendData:[logMessage dataUsingEncoding:NSUTF8StringEncoding]];
        
        return data;
    }
    
    NSMutableData *compressedData = [newArchive.contents mutableCopy];
    
    /*
#if DEBUG
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    [compressedData writeToFile:[docsDir stringByAppendingPathComponent:@"serviceLog.zip"] atomically:YES];
#endif
     */
    
    return compressedData;
}

////////////////////////////////////////////////////////////////////////////////
- (void)removeLogFiles
{
    if (self.logging)
        [self stopLogging];
    
    DDFileLogger *fileLogger = self.fileLogger;
    if (fileLogger == nil)
        fileLogger = [DDFileLogger new];
        
    DDLogInfo(@"%@: Attempting to remove all log files.", self.class);
    NSUInteger errorCounter = 0;
    for (DDLogFileInfo *logFileInfo in fileLogger.logFileManager.sortedLogFileInfos)
    {
        NSError *removeError = nil;
        if (![[NSFileManager defaultManager] removeItemAtPath:logFileInfo.filePath error:&removeError])
        {
            DDLogError(@"%@: ERROR removing log file at: %@", self.class, logFileInfo.filePath);
            errorCounter ++;
        }
    }
    if (errorCounter > 0)
        DDLogError(@"%@: ERROR. Some log files were not removed.", self.class);
    else
        DDLogInfo(@"%@: All log files were successfully removed.", self.class);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:IOLoggerDidRemoveErrorLogsNotification object:nil];
}

////////////////////////////////////////////////////////////////////////////////
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    if (result == MFMailComposeResultSent)
        [self removeLogFiles];
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    self.presentingViewController = nil;
    
    if (result == MFMailComposeResultCancelled)
    {
        NSString *messge = NSLocalizedString(@"Would you like to remove the service logs?", @"");
        _deleteLogsAlertView = [[UIAlertView alloc] initWithTitle:nil
                                                          message:messge
                                                         delegate:self
                                                cancelButtonTitle:NSLocalizedString(@"No", @"Cancel title when asking to remove log files.")
                                                otherButtonTitles:NSLocalizedString(@"Yes", @"Agree title when asking to remove log files."), nil];
        [_deleteLogsAlertView show];
    }
}

////////////////////////////////////////////////////////////////////////////////
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView == _errorLogAlertView)
    {
        if (buttonIndex != alertView.cancelButtonIndex && _emailErrorLog != nil)
        {
            DDLogVerbose(@"%@: User aggreed to send the service log", self.class);
            _emailErrorLog();
        }
        else
        {
            DDLogVerbose(@"%@: User disagreed to send the service log", self.class);
            self.presentingViewController = nil;
        }
        
        _emailErrorLog = nil;
        _errorLogAlertView.delegate = nil;
        _errorLogAlertView = nil;
    }
    else if (alertView == _deleteLogsAlertView)
    {
        if (buttonIndex != alertView.cancelButtonIndex)
            [self removeLogFiles];
        
        _deleteLogsAlertView.delegate = nil;
        _deleteLogsAlertView = nil;
    }
}

@end
