//
//  TentStatusClient.m
//  TentStatusExample
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

#import "TentStatusClient.h"

@implementation TentStatusClient

- (id)initWithEntity:(NSURL *)entityURL {
    self = [super initWithEntity:entityURL];
    if (!self) {
        return nil;
    }
    
    self.appName = @"TentStatusClient";
    self.appDescription = NSLocalizedString(@"A TPTentClient example app", nil);
    self.appWebsiteURL = [NSURL URLWithString:@"http://tentstatusclient.example.com"];
    self.customURLScheme = @"tentstatus";
    self.scopes = @{@"read_profile": NSLocalizedString(@"TentStatusClient would like to access your profile", nil),
                    @"read_posts": NSLocalizedString(@"TentStatusClient would like to access your posts", nil),
                    @"write_posts": NSLocalizedString(@"TentStatusClient would like to post on your behalf", nil)};
    
    return self;
}

@end
