//
//  TentStatusClient.m
//  TentStatusExample
//
//  Created by Ben Stovold on 02/10/2012.
//  Copyright (c) 2012 Thoughtful Pixel. All rights reserved.
//

#import "TentStatusClient.h"

@implementation TentStatusClient

+ (TentStatusClient *)sharedClient
{
    static TentStatusClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[TentStatusClient alloc] init];
        
        _sharedClient.appName = @"TentStatusClient";
        _sharedClient.appDescription = NSLocalizedString(@"A TPTentClient example app", nil);
        _sharedClient.appWebsiteURL = [NSURL URLWithString:@"http://tentstatusclient.example.com"];
        _sharedClient.customURLScheme = @"tentstatus";
        _sharedClient.scopes = @{@"read_profile": NSLocalizedString(@"TentStatusClient would like to access your profile", nil),
                                 @"read_posts": NSLocalizedString(@"TentStatusClient would like to access your posts", nil)};
    });
    
    return _sharedClient;
}

@end
