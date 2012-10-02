//
//  TPTentClient.m
//
//  Created by Ben Stovold on 30/09/2012.
//  Copyright (c) 2012 Thoughtful Pixel. All rights reserved.
//

#import "TPTentClient.h"
#import "TPTentHTTPClient.h"
#import "AFJSONRequestOperation.h"

NSString * const TPTentClientDidRegisterWithEntityNotification = @"com.thoughtfulpixel.tptentclient.notification.didregisterwithentity";
NSString * const TPTentClientDidRegisterWithEntityURL = @"TPTentClientDidRegisterWithEntityURL";

@interface TPTentClient ()

@property (nonatomic, strong) TPTentHTTPClient *httpClient;

@end

#pragma mark
@implementation TPTentClient

#pragma mark - Public methods

- (BOOL)isRegisteredWithEntityURL:(NSURL *)url
{
    if (self.httpClient && [self.httpClient.baseURL isEqual:url] && [self.httpClient isRegisteredWithBaseURL]) {
        return YES;
    }
    
    return NO;
}

- (void)registerWithEntityURL:(NSURL *)url
{
    if (self.httpClient.isRegisteredWithBaseURL && [self.httpClient.baseURL isEqual:url]) {
        return;
    }
    
    if (![self.httpClient.baseURL isEqual:url]) {
        self.httpClient = [[TPTentHTTPClient alloc] initWithBaseURL:url];
        self.httpClient.delegate = self;
    }
    
    [self.httpClient registerWithBaseURL];
}

- (BOOL)handleOpenURL:(NSURL *)url
{
    return [self.httpClient handleOpenURL:url];
}

- (void)httpClientDidRegisterWithBaseURL:(TPTentHTTPClient *)httpClient
{
    [[NSNotificationCenter defaultCenter] postNotificationName:TPTentClientDidRegisterWithEntityNotification
                                                        object:nil
                                                      userInfo:@{TPTentClientDidRegisterWithEntityNotification: httpClient.baseURL}];
    
    if ([self.delegate respondsToSelector:@selector(tentClient:didRegisterWithEntityURL:)]) {
        [self.delegate tentClient:self didRegisterWithEntityURL:httpClient.baseURL];
    }
}

- (void)postRepresentationsWithSuccess:(void (^)(NSArray *statusRepresentations))success
                               failure:(void (^)(NSError *error))failure
{
    NSMutableURLRequest *request = [self.httpClient requestWithMethod:@"GET" path:@"posts" parameters:nil];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        if (success) {
            success((NSArray *)JSON);
        }
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if (failure) {
            failure(error);
        }
    }];
    
    [self.httpClient enqueueHTTPRequestOperation:operation];
}

@end
