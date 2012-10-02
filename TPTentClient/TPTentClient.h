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

- (BOOL)isAuthorizedWithEntityURL:(NSURL *)url;
- (void)authorizeWithEntityURL:(NSURL *)url;

- (BOOL)handleOpenURL:(NSURL *)url;

- (void)postRepresentationsWithSuccess:(void (^)(NSArray *statusRepresentations))success
                               failure:(void (^)(NSError *error))failure;

@end

extern NSString * const TPTentClientDidRegisterWithEntityNotification;
extern NSString * const TPTentClientDidRegisterWithEntityURL;

@protocol TPTentClientDelegate <NSObject>
@optional
- (void)tentClient:(TPTentClient *)tentClient didAuthorizeWithEntityURL:(NSURL *)url;
@end