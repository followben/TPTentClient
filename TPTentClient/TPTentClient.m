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

static NSString * const TPTentClientProfileInfoTypeCore = @"https://tent.io/types/info/core/v0.1.0";
static NSString * const TPTentClientProfileInfoTypeBasic = @"https://tent.io/types/info/basic/v0.1.0";

NSString * const TPTentClientDidRegisterWithEntityNotification = @"com.thoughtfulpixel.tptentclient.notification.didregisterwithentity";
NSString * const TPTentClientDidRegisterWithEntityNotificationURLKey = @"TPTentClientDidRegisterWithEntityURL";



#pragma mark 

@interface TPTentClient ()

@property (nonatomic, strong) TPTentHTTPClient *httpClient;

@end

#pragma mark
@implementation TPTentClient

#pragma mark - Public methods

#pragma mark Discovery

- (void)discoverTentServerForEntityURL:(NSURL *)url
                               success:(void (^)(NSURL *canonicalServerURL, NSURL *canonicalEntityURL))success
                               failure:(void (^)(NSError *error))failure
{
    AFHTTPClient *discoveryHTTPClient = [[AFHTTPClient alloc] initWithBaseURL:url];
    [self headTentServerWithDiscoveryHTTPClient:discoveryHTTPClient success:success failure:failure];
}

#pragma mark OAuth

- (BOOL)isAuthorizedForTentServer:(NSURL *)url
{
    if (self.httpClient && [self.httpClient.baseURL isEquivalent:url] && [self.httpClient isRegisteredWithBaseURL]) {
        return YES;
    }
    
    return NO;
}

- (void)authorizeForTentServerURL:(NSURL *)url
{
    [self authorizeForTentServerURL:url success:nil failure:nil];
}

- (void)authorizeForTentServerURL:(NSURL *)url
                          success:(void (^)())success
                          failure:(void (^)(NSError *error))failure
{
    if (self.httpClient.isRegisteredWithBaseURL && [self.httpClient.baseURL isEqual:url]) {
        return;
    }
    
    if (![self.httpClient.baseURL isEqual:url]) {
        self.httpClient = [[TPTentHTTPClient alloc] initWithBaseURL:url];
        self.httpClient.delegate = self;
    }
    
    [self.httpClient registerForBaseURLWithSuccess:success failure:failure];
}

- (BOOL)handleOpenURL:(NSURL *)url
{
    return [self.httpClient handleOpenURL:url];
}

#pragma mark Retrieving Represenations

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

#pragma mark Creating Resources

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

#pragma mark - TPTentHTTPClientDelegate conformance

- (void)httpClientDidRegisterWithBaseURL:(TPTentHTTPClient *)httpClient
{
    [[NSNotificationCenter defaultCenter] postNotificationName:TPTentClientDidRegisterWithEntityNotification
                                                        object:nil
                                                      userInfo:@{TPTentClientDidRegisterWithEntityNotification: httpClient.baseURL}];
    
    if ([self.delegate respondsToSelector:@selector(tentClient:didAuthorizeWithTentServerURL:)]) {
        [self.delegate tentClient:self didAuthorizeWithTentServerURL:httpClient.baseURL];
    }
}

#pragma mark - Private methods

#pragma mark Discovery

- (void)headTentServerWithDiscoveryHTTPClient:(AFHTTPClient *)discoveryHTTPClient
                                      success:(void (^)(NSURL *canonicalServerURL, NSURL *canonicalEntityURL))success
                                      failure:(void (^)(NSError *error))failure
{
    NSMutableURLRequest *headRequest = [discoveryHTTPClient requestWithMethod:@"HEAD" path:@"/" parameters:nil];
    
    AFHTTPRequestOperation *headOperation = [[AFHTTPRequestOperation alloc] initWithRequest:headRequest];
    
    [headOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSURL *profileURL = [self profileURLFromCompletedHeadOperation:operation];
        if (!profileURL) {
            [self getTentServerWithDiscoveryHTTPClient:discoveryHTTPClient success:success failure:failure];
            return;
        }
        
        [self getCanonicalURLsFromProfileURL:profileURL success:success failure:failure];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];

    [discoveryHTTPClient enqueueHTTPRequestOperation:headOperation];
}

- (NSURL *)profileURLFromCompletedHeadOperation:(AFHTTPRequestOperation *)operation
{
    NSString *linkHeader = [[operation.response allHeaderFields] valueForKey:@"Link"];
    NSString *linkHeaderPrefix = @"<";
    NSString *linkHeaderSuffix = @">; rel=\"https://tent.io/rels/profile\"";
    
    if (![linkHeader hasPrefix:linkHeaderPrefix] || ![linkHeader hasSuffix:linkHeaderSuffix]) {
        return nil;
    }
    
    linkHeader = [linkHeader substringFromIndex:1];

    NSScanner *scanner = [NSScanner scannerWithString:linkHeader];
    NSString *profileURLString;
    
    if (![linkHeader hasPrefix:@"http"]) {
        
        NSString *relativeURLString;
        [scanner scanUpToString:linkHeaderSuffix intoString:&relativeURLString];
        if ([relativeURLString hasPrefix:@"/"]) relativeURLString = [relativeURLString substringFromIndex:1];
        profileURLString = [NSString stringWithFormat:@"%@%@", [operation.response.URL absoluteString], relativeURLString];
        
    } else {
        [scanner scanUpToString:@"http" intoString:nil];
        if (![scanner isAtEnd]) {
            [scanner scanUpToString:linkHeaderSuffix intoString:&profileURLString];
        }
    }
    
    NSURL *profileURL;
    if (profileURLString.length > 0) {
        profileURL = [NSURL URLWithString:profileURLString];
    }
    
    return profileURL;
}

- (void)getTentServerWithDiscoveryHTTPClient:(AFHTTPClient *)discoveryHTTPClient
                                     success:(void (^)(NSURL *canonicalServerURL, NSURL *canonicalEntityURL))success
                                     failure:(void (^)(NSError *error))failure
{
    [discoveryHTTPClient getPath:@"/" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSURL *profileURL = [self profileURLFromCompletedGetOperation:operation
                                                       responseString:[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]];
        
        if (!profileURL) {
            NSLog(@"Error: can't find tent profile using %@", [discoveryHTTPClient.baseURL absoluteString]);
            if (failure) {
                failure(nil);   // TODO: throw an error
            }
            return;
        }
        
        [self getCanonicalURLsFromProfileURL:profileURL success:success failure:failure];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (NSURL *)profileURLFromCompletedGetOperation:(AFHTTPRequestOperation *)operation responseString:(NSString *)responseString
{
    NSString *linkTagPrefix = @"<link";
    NSString *linkRelationshipURIString = @"https://tent.io/rels/profile";
    NSString *linkTagSuffix = @"/>";
    
    if ([responseString rangeOfString:linkRelationshipURIString].location == NSNotFound) {
        return nil;
    }
    
    NSScanner *scanner = [NSScanner scannerWithString:responseString];
    NSString *linkTagString = [NSString string];
    while ([linkTagString rangeOfString:linkRelationshipURIString].location == NSNotFound) {
        [scanner scanUpToString:linkTagPrefix intoString:nil];
        if (![scanner isAtEnd]) {
            [scanner scanUpToString:linkTagSuffix intoString:&linkTagString];
        }
    }
    
    scanner = [NSScanner scannerWithString:linkTagString];
    NSString *hrefString;
    [scanner scanUpToString:@"href=" intoString:nil];
    if (![scanner isAtEnd]) {
        [scanner scanUpToString:@" " intoString:&hrefString];
    }
    
    hrefString = [hrefString stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    hrefString = [hrefString stringByReplacingOccurrencesOfString:@"'" withString:@""];
    
    NSString *profileURLString = [hrefString stringByReplacingOccurrencesOfString:@"href=" withString:@""];
    
    if (![profileURLString hasPrefix:@"http"]) {
        NSString *relativeURLString = profileURLString;
        if ([relativeURLString hasPrefix:@"/"]) relativeURLString = [relativeURLString substringFromIndex:1];
        profileURLString = [NSString stringWithFormat:@"%@%@", [operation.response.URL absoluteString], relativeURLString];
    }
    
    NSURL *profileURL;
    if (profileURLString.length > 0) {
        profileURL = [NSURL URLWithString:profileURLString];
    }
    
    return profileURL;
}

- (void)getCanonicalURLsFromProfileURL:(NSURL *)url
                                  success:(void (^)(NSURL *canonicalServerURL, NSURL *canonicalEntityURL))success
                                  failure:(void (^)(NSError *error))failure
{
    AFHTTPClient *aHTTPClient = [[TPTentHTTPClient alloc] initWithBaseURL:url];
    
    NSMutableURLRequest *getRequest = [aHTTPClient requestWithMethod:@"GET" path:[NSString string] parameters:nil];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:getRequest success:^(NSURLRequest *getRequest, NSHTTPURLResponse *getResponse, id JSON) {

        NSURL *tentServerURL = [self serverURLFromJSON:JSON];
        if (!tentServerURL) {
            NSLog(@"Error: can't find a tent server in the profile located at %@", [aHTTPClient.baseURL absoluteString]);
            if (failure) {
                failure(nil);   // TODO: throw an error
            }
            return;
        }
        
        NSURL *tentEntityURL = [self entityURLFromJSON:JSON];
        if (!tentEntityURL) {
            NSLog(@"Error: can't find a tent entity in the profile located at %@", [aHTTPClient.baseURL absoluteString]);
            if (failure) {
                failure(nil);   // TODO: throw an error
            }
            return;
        }
        
        if (success) {
            success(tentServerURL, tentEntityURL);
        }
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if (failure) {
            failure(error);
        }
    }];
    
    [aHTTPClient enqueueHTTPRequestOperation:operation];
}

- (NSURL *)serverURLFromJSON:(id)JSON
{
    NSArray *serverURLs = JSON[TPTentClientProfileInfoTypeCore][@"servers"];
    
    // TODO: Support multiple servers
    NSString *tentServerURLString;
    if (serverURLs && [serverURLs count] > 0) {
        tentServerURLString = serverURLs[0];
    }

    return [NSURL URLWithString:tentServerURLString];
}

- (NSURL *)entityURLFromJSON:(id)JSON
{
    return [NSURL URLWithString:JSON[TPTentClientProfileInfoTypeCore][@"entity"]];
}

@end
