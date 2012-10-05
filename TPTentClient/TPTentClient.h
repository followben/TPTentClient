//
//  TPTentClient.h
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

#import "TPTentHTTPClient.h"

@protocol TPTentClientDelegate;

@interface TPTentClient : NSObject <TPTentHTTPDelegate>

@property (nonatomic, weak) id<TPTentClientDelegate> delegate;

@property (nonatomic, strong) NSString *customURLScheme;
@property (nonatomic, strong) NSString *appName;
@property (nonatomic, strong) NSString *appDescription;
@property (nonatomic, strong) NSURL *appWebsiteURL;
@property (nonatomic, strong) NSDictionary *scopes;

// Discovery
- (void)discoverTentServerForEntityURL:(NSURL *)url
                               success:(void (^)(NSURL *canonicalServerURL, NSURL *canonicalEntityURL))success
                               failure:(void (^)(NSError *error))failure;

// OAuth
- (BOOL)isAuthorizedForTentServer:(NSURL *)url;
- (void)authorizeForTentServerURL:(NSURL *)url;
- (void)authorizeForTentServerURL:(NSURL *)url
                          success:(void (^)())success
                          failure:(void (^)(NSError *error))failure;

- (BOOL)handleOpenURL:(NSURL *)url;

// Retrieving Representations
- (void)getPostRepresentationsWithSuccess:(void (^)(NSArray *statusRepresentations))success
                                  failure:(void (^)(NSError *error))failure;

// Creating Resources
- (void)postStatusWithText:(NSString *)text permissions:(NSDictionary *)permissions
                   success:(void (^)(void))success
                   failure:(void (^)(NSError *error))failure;
- (void)postPostWithType:(NSString *)postType permissions:(NSDictionary *)permissions content:(NSDictionary *)content
                 success:(void (^)(void))success
                 failure:(void (^)(NSError *error))failure;
@end

// Tent post types
extern NSString * const TPTentClientPostTypeStatus;
extern NSString * const TPTentClientPostTypeEssay;
extern NSString * const TPTentClientPostTypePhoto;
extern NSString * const TPTentClientPostTypeAlbum;
extern NSString * const TPTentClientPostTypeRepost;
extern NSString * const TPTentClientPostTypeProfileModification;
extern NSString * const TPTentClientPostTypeDeleteNotification;

// Notifications and UserInfo dict keys
extern NSString * const TPTentServerDiscoveryCheckingHeadResponseForProfileLinkNotification;
extern NSString * const TPTentServerDiscoveryFellBackToGetResponseForProfileLinkNotification;
extern NSString * const TPTentServerDiscoveryFetchingCanonicalURLsFromProfileNotification;
extern NSString * const TPTentServerDiscoveryCompleteNotification;
extern NSString * const TPTentServerDiscoveryCompleteNotificationCanonicalServerURLKey;
extern NSString * const TPTentServerDiscoveryCompleteNotificationCanonicalEntityURLKey;
extern NSString * const TPTentClientWillAuthorizeWithTentServerNotification;
extern NSString * const TPTentClientDidAuthorizeWithTentServerNotification;
extern NSString * const TPTentClientAuthorizingWithTentServerURLKey;

@protocol TPTentClientDelegate <NSObject>
@optional
// TODO: notes and delegate calls should map one-to-one
- (void)tentClient:(TPTentClient *)tentClient didAuthorizeWithTentServerURL:(NSURL *)canonicalServerURL;
@end

