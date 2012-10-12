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

/**
 TPTentHTTPDelegate protocol properties. Subclasses should override these properties to configure appropriate values for the tent application using the TPTentClient library.
 **/
@property (nonatomic, strong) NSString *customURLScheme;
@property (nonatomic, strong) NSString *appName;
@property (nonatomic, strong) NSString *appDescription;
@property (nonatomic, strong) NSURL *appWebsiteURL;
@property (nonatomic, strong) NSDictionary *scopes;

/**
 The main tent entity. All operations will be performed on the primary (first) server in this entity's profile. Note that this entity may differ from that provided in the designated initialiser or factory, i.e. if discovery has been performed, this property will return the canonical entity.
 TODO: Handle multiple/ fallback tent servers for the entity
 **/
@property (nonatomic, strong, readonly) NSURL *entity;

/**
 The delegate. At present the delegate protocol provides very few hooks into TPTentClient logic, so it's not very useful.
 TODO: Improve delegate protocol functionality to match notifications
 **/
@property (nonatomic, weak) id<TPTentClientDelegate> delegate;


///---------------------------------------------
/// @name Creating and Initializing Tent Clients
///---------------------------------------------

/**
 Creates and initializes an `TPTentClient` object with the specified entity.
 
 @param entityURL The URL of the base Tent Entity. This argument must not be nil.
 
 @return The newly-initialized Tent client
 */
+ (TPTentClient *)clientWithEntity:(NSURL *)entityURL;

/**
 Initializes an `TPTentClient` object with the specified entity.
 
 @param entityURL The URL of the base Tent Entity. This argument must not be nil.
 
 @discussion This is the designated initializer.
 
 @return The newly-initialized Tent client
 */
- (id)initWithEntity:(NSURL *)entityURL;


///---------------------------------------------
/// @name Authorization
///---------------------------------------------

/**
 Checks the keychain for previous authorization tokens matching the entity's primary tent server.
 
 @discussion If canonical entity and server URLs have not yet been discovered, that is performed here also.
 
 @return YES if tokens exist for the entity's primary server.
 
 @warning This method does does not validate that auth tokens are valid, simply that they exist (e.g. they may have been revoked). This should be enough for login/ account authorisation purposes however: if any operations on the entity's primary server return a 403, authorisation is re-initiated.
 */
- (void)checkAuthTokensWithBlock:(void (^)(BOOL tokensFound))block;

/**
 Removes any authorization tokens matching the entity's primary tent server from the keychain.
 
 @discussion This does not revoke or remove authorisations on the server, only the client.
 
 TODO: currently this method removes all tokens and subsequent calls to auth will be like a new app. Logic needs to change so subsequent calls only re-auth and obtain new secrets, keeping app id etc. the same.
 */
- (void)removeAuthTokens;

/**
 Attempts to authorize the client with the entity's primary server.
 
 @discussion If canonical entity and server URLs have not yet been discovered, that is performed here also. Only those permissions specified on in the scopes member property are requested.
 */
- (void)authorizeWithEntitySuccess:(void (^)())success
                           failure:(void (^)(NSError *error))failure;

/**
 URL handler for returning from oAuth redirects
 
 @discussion If Authorization is required, TPTentClient will open mobile safari. Client applications are expected to configure a customURLScheme in the application's plist matching that specified in the member variable of the same name in order to respond to the redirect. Any calls to that scheme should be forwarded to this method such that the tent client can continue with the authorization process.
 
 @return YES if the URL could be handled.
 */
- (BOOL)handleOpenURL:(NSURL *)url;


///---------------------------------------------
/// @name Retrieving Representations
///---------------------------------------------

/**
TODO: document
 */
- (void)getProfileRepresentationForEntityURL:(NSURL *)entityURL
                                     success:(void (^)(NSDictionary *basicInfo))success
                                     failure:(void (^)(NSError *error))failure;
/**
 TODO: document
 */
- (void)getPostRepresentationsWithSuccess:(void (^)(NSArray *statusRepresentations))success
                                  failure:(void (^)(NSError *error))failure;


///---------------------------------------------
/// @name Creating Resources
///---------------------------------------------

/**
 TODO: document
 */
- (void)postStatusWithText:(NSString *)text permissions:(NSDictionary *)permissions
                   success:(void (^)(void))success
                   failure:(void (^)(NSError *error))failure;
/**
 TODO: document
 */
- (void)postPostWithType:(NSString *)postType permissions:(NSDictionary *)permissions content:(NSDictionary *)content
                 success:(void (^)(void))success
                 failure:(void (^)(NSError *error))failure;

@end

// Tent types
extern NSString * const TPTentClientProfileInfoTypeCore;
extern NSString * const TPTentClientProfileInfoTypeBasic;
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
extern NSString * const TPTentServerDiscoveryFailureNotification;
extern NSString * const TPTentServerDiscoverySuccessNotification;
extern NSString * const TPTentServerDiscoverySuccessNotificationCanonicalServerURLKey;
extern NSString * const TPTentServerDiscoverySuccessNotificationCanonicalEntityURLKey;
extern NSString * const TPTentClientWillAuthorizeWithTentServerNotification;
extern NSString * const TPTentClientDidAuthorizeWithTentServerNotification;
extern NSString * const TPTentClientAuthorizingWithTentServerURLKey;

@protocol TPTentClientDelegate <NSObject>
@optional
// TODO: notes and delegate calls should map one-to-one
- (void)tentClient:(TPTentClient *)tentClient didAuthorizeWithTentServerURL:(NSURL *)canonicalServerURL;
@end

