//
// Created by avioli on 13/03/13.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "ImageEngine.h"

static const int ddLogLevel = DDLOG_LEVEL_GLOBAL;

@implementation ImageEngine

- (id)initWithDefaultSettings
{
    self = [super initWithHostName:nil customHeaderFields:@{@"x-client-identifier": @"iOS"}];
    if (self)
    {
        logmethod();
    }

    return self;
}



#pragma mark - load images

- (MKNetworkOperation *)loadImageFromURL:(NSString *)fullURL
                            successBlock:(void (^)(UIImage *image))successBlock
                              errorBlock:(void (^)(NSError *error, NSInteger statusCode))errorBlock
{
    logmethod();
    if (fullURL == nil || ![fullURL isKindOfClass:[NSString class]] || fullURL.length == 0)
    {
        if (errorBlock)
            errorBlock([NSError errorWithDomain:@"loadImageFromURL" code:400 userInfo:@{NSLocalizedDescriptionKey: @"Image url is blank"}], 400);
        return nil;
    }
    
    NSURL *imageURL = [[NSURL alloc] initWithString:fullURL];
    
    return [self imageAtURL:imageURL completionHandler:^(UIImage *fetchedImage, NSURL *url, BOOL isInCache) {
//        IOLog(@"%@ ||| Is in cache? %@", url, isInCache ? @"YES" : @"NO");
        
        successBlock(fetchedImage);
        
    } errorHandler:^(MKNetworkOperation *errorOperation, NSError *error) {
        
        NSInteger statusCode = [errorOperation HTTPStatusCode];
        errorBlock(error, statusCode);
        
    }];
}

@end