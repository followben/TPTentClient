//
//  TPTentClient.h
//
//  Created by Ben Stovold on 30/09/2012.
//  Copyright (c) 2012 Thoughtful Pixel. All rights reserved.
//

#import "TPTentHTTPClient.h"

@protocol TPTentClientDelegate;

@interface TPTentClient : NSObject <TPTentHTTPDelegate>

@property (nonatomic, weak) id<TPTentClientDelegate> delegate;

@property (nonatomic, strong) NSString *customURLScheme;
@property (nonatomic, strong) NSString *appName;
@property (nonatomic, strong) NSString *appDescription;
@property (nonatomic, strong) NSURL *appWebsiteURL;
@property (nonatomic, strong) NSDictionary *scopes;

- (BOOL)isAuthorizedWithTentServer:(NSURL *)url;
- (void)authorizeWithTentServer:(NSURL *)url;

- (BOOL)handleOpenURL:(NSURL *)url;

- (void)discoverTentServerForEntity:(NSURL *)url
                            success:(void (^)(NSURL *tentServerURL))success
                            failure:(void (^)(NSError *error))failure;

- (void)postRepresentationsWithSuccess:(void (^)(NSArray *statusRepresentations))success
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
extern NSString * const TPTentClientDidRegisterWithEntityNotification;
extern NSString * const TPTentClientDidRegisterWithEntityNotificationURLKey;

@protocol TPTentClientDelegate <NSObject>
@optional
- (void)tentClient:(TPTentClient *)tentClient didAuthorizeWithEntityURL:(NSURL *)url;
@end