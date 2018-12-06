//
// Created by avioli on 13/03/13.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "MKNetworkKit.h"

@interface ImageEngine : MKNetworkEngine

- (id)initWithDefaultSettings;
- (MKNetworkOperation *)loadImageFromURL:(NSString *)fullURL
                            successBlock:(void (^)(UIImage *image))successBlock
                              errorBlock:(void (^)(NSError *error, NSInteger statusCode))errorBlock;

@end