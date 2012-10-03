//
//  TPTentClient.m
//
//  Created by Ben Stovold on 30/09/2012.
//  Copyright (c) 2012 Thoughtful Pixel. All rights reserved.
//

#import "TPTentClient.h"
#import "TPTentHTTPClient.h"
#import "AFJSONRequestOperation.h"


#pragma mark - Constants

NSString * const TPTentClientPostTypeStatus = @"https://tent.io/types/post/status/v0.1.0";
NSString * const TPTentClientPostTypeEssay = @"https://tent.io/types/post/essay/v0.1.0";
NSString * const TPTentClientPostTypePhoto = @"https://tent.io/types/post/photo/v0.1.0";
NSString * const TPTentClientPostTypeAlbum = @"https://tent.io/types/post/album/v0.1.0";
NSString * const TPTentClientPostTypeRepost = @"https://tent.io/types/post/repost/v0.1.0";
NSString * const TPTentClientPostTypeProfileModification = @"https://tent.io/types/post/profile/v0.1.0";
NSString * const TPTentClientPostTypeDeleteNotification = @"https://tent.io/types/post/delete/v0.1.0";


NSString * const TPTentClientDidRegisterWithEntityNotification = @"com.thoughtfulpixel.tptentclient.notification.didregisterwithentity";
NSString * const TPTentClientDidRegisterWithEntityNotificationURLKey = @"TPTentClientDidRegisterWithEntityURL";


#pragma mark - NSURL comparison extensions

@interface NSURL (TPEquivalence)

- (BOOL)isEquivalent:(NSURL *)aURL;

@end

@implementation NSURL (TPEquivalence)

- (BOOL)isEquivalent:(NSURL *)aURL {
    if ([self isEqual:aURL]) return YES;
    if ([[self scheme] caseInsensitiveCompare:[aURL scheme]] != NSOrderedSame) return NO;
    if ([[self host] caseInsensitiveCompare:[aURL host]] != NSOrderedSame) return NO;
    if ([[self path] compare:[aURL path]] != NSOrderedSame) return NO;
    if ([[self port] compare:[aURL port]] != NSOrderedSame) return NO;
    if ([[self query] compare:[aURL query]] != NSOrderedSame) return NO;
    return YES;
}

@end


#pragma mark 

@interface TPTentClient ()

@property (nonatomic, strong) TPTentHTTPClient *httpClient;

@end

#pragma mark
@implementation TPTentClient

#pragma mark - Public methods

- (BOOL)isAuthorizedWithEntityURL:(NSURL *)url
{
    if (self.httpClient && [self.httpClient.baseURL isEquivalent:url] && [self.httpClient isRegisteredWithBaseURL]) {
        return YES;
    }
    
    return NO;
}

- (void)authorizeWithEntityURL:(NSURL *)url
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
    
    if ([self.delegate respondsToSelector:@selector(tentClient:didAuthorizeWithEntityURL:)]) {
        [self.delegate tentClient:self didAuthorizeWithEntityURL:httpClient.baseURL];
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
