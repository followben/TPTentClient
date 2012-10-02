//
//  AppDelegate.m
//  TentStatusExample
//
//  Created by Ben Stovold on 02/10/2012.
//  Copyright (c) 2012 Thoughtful Pixel. All rights reserved.
//

#import "AppDelegate.h"
#import "TentStatusClient.h"
#import "AFNetworkActivityIndicatorManager.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    
    return YES;
}
							
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    return [[TentStatusClient sharedClient] handleOpenURL:url];
}



@end
