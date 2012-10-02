//
//  TPTentHTTPClient.h
//
//  Created by Ben Stovold on 30/09/2012.
//  Copyright (c) 2012 Thoughtful Pixel. All rights reserved.
//

#import "AFHTTPClient.h"

@protocol TPTentHTTPDelegate;

@interface TPTentHTTPClient : AFHTTPClient

@property (nonatomic, weak) id<TPTentHTTPDelegate> delegate;

- (BOOL)isRegisteredWithBaseURL;
- (void)registerWithBaseURL;

- (BOOL)handleOpenURL:(NSURL *)url;

@end

@protocol TPTentHTTPDelegate <NSObject>

@property (nonatomic, readonly) NSString *customURLScheme;
@property (nonatomic, readonly) NSString *appName;
@property (nonatomic, readonly) NSString *appDescription;
@property (nonatomic, readonly) NSURL *appWebsiteURL;
@property (nonatomic, readonly) NSDictionary *scopes;

@optional
- (void)httpClientDidRegisterWithBaseURL:(TPTentHTTPClient *)HTTPClient;

@end
