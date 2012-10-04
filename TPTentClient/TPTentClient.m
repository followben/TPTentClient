//
//  TPTentClient.m
//
//  Copyright (c) 2012 Ben Stovold http://thoughtfulpixel.com
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "TPTentClient.h"
#import "TPTentHTTPClient.h"
#import "NSURL+TPEquivalence.h"
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


#pragma mark 

@interface TPTentClient ()

@property (nonatomic, strong) TPTentHTTPClient *httpClient;

@end

#pragma mark
@implementation TPTentClient

#pragma mark - Public methods

- (BOOL)isAuthorizedWithTentServer:(NSURL *)url
{
    if (self.httpClient && [self.httpClient.baseURL isEquivalent:url] && [self.httpClient isRegisteredWithBaseURL]) {
        return YES;
    }
    
    return NO;
}

- (void)authorizeWithTentServer:(NSURL *)url
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

- (void)discoverTentServerForEntity:(NSURL *)url
                            success:(void (^)(NSURL *tentServerURL))success
                            failure:(void (^)(NSError *error))failure
{
    AFHTTPClient *discoveryHTTPClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    
    NSMutableURLRequest *request = [discoveryHTTPClient requestWithMethod:@"HEAD" path:@"/" parameters:nil];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        NSURL *tentServerURL = [self canonicalTentServerURLFromDiscoveryResponse:response];
        if (tentServerURL && success) {
            success(tentServerURL);
        }
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if (failure) {
            failure(error);
        }
    }];
    
    [discoveryHTTPClient enqueueHTTPRequestOperation:operation];
}

- (NSURL *)canonicalTentServerURLFromDiscoveryResponse:(NSHTTPURLResponse *)response
{
    NSString *profileLink = [[response allHeaderFields] valueForKey:@"Link"];
    
    if (![profileLink hasPrefix:@"<"]) {
        NSLog(@"Cannot parse profile link \n%@", profileLink);
        return nil;
    }
    
    // TODO: Lookup canonical url(s); just parse link for now
    
    profileLink = [profileLink substringFromIndex:1];
    NSString *profileDeclarationSuffix = @">; rel=\"https://tent.io/rels/profile\"";
    NSScanner *scanner = [NSScanner scannerWithString:profileLink];
    NSString *profileURLString;
    
    if (![profileLink hasPrefix:@"http"]) {
        
        NSString *relativeURLString;
        [scanner scanUpToString:profileDeclarationSuffix intoString:&relativeURLString];
        if ([relativeURLString hasPrefix:@"/"]) relativeURLString = [relativeURLString substringFromIndex:1];
        profileURLString = [NSString stringWithFormat:@"%@%@", [response.URL absoluteString], relativeURLString];
        
    } else {
        [scanner scanUpToString:@"http" intoString:nil];
        if (![scanner isAtEnd]) {
            [scanner scanUpToString:profileDeclarationSuffix intoString:&profileURLString];
        }
    }
    NSMutableString *serverURLString = [profileURLString mutableCopy];
    [serverURLString deleteCharactersInRange:NSMakeRange(serverURLString.length - [@"/profile" length], [@"/profile" length])];
    return [NSURL URLWithString:serverURLString];
}

- (void)postStatusWithText:(NSString *)text permissions:(NSDictionary *)permissions
                   success:(void (^)(void))success
                   failure:(void (^)(NSError *error))failure
{
    if (!permissions) {
        permissions = @{ @"public": @"true" };
    }
    
    [self postPostWithType:TPTentClientPostTypeStatus permissions:permissions content:@{@"text": text} success:^{
        if (success) {
            success();
        }
    } failure:^(NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)postPostWithType:(NSString *)postType permissions:(NSDictionary *)permissions content:(NSDictionary *)content
                 success:(void (^)(void))success
                 failure:(void (^)(NSError *error))failure
{
    long secs = round([[NSDate date] timeIntervalSince1970]);
    NSString *timeStamp = [NSString stringWithFormat:@"%ld", secs];
    
    NSDictionary *params = @{@"type": postType, @"publishedAt": timeStamp, @"permissions": permissions, @"content": content};
    
    NSMutableURLRequest *request = [self.httpClient requestWithMethod:@"POST" path:@"posts" parameters:params];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        if (success) {
            success();
        }
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if (failure) {
            failure(error);
        }
    }];
    
    [self.httpClient enqueueHTTPRequestOperation:operation];
}

- (void)getPostRepresentationsWithSuccess:(void (^)(NSArray *statusRepresentations))success
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
