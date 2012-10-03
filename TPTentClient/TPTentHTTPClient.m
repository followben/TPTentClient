//
//  TPTentHTTPClient.m
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
#import "AFJSONRequestOperation.h"
#import "NSURL+SSToolkitAdditions.h"
#import <CommonCrypto/CommonHMAC.h>

#pragma mark - Functions and constants

static NSString *TPBase64EncodedStringFromData(NSData *data) {
    NSUInteger length = [data length];
    NSMutableData *mutableData = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    
    uint8_t *input = (uint8_t *)[data bytes];
    uint8_t *output = (uint8_t *)[mutableData mutableBytes];
    
    for (NSUInteger i = 0; i < length; i += 3) {
        NSUInteger value = 0;
        for (NSUInteger j = i; j < (i + 3); j++) {
            value <<= 8;
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        static uint8_t const kTPBase64EncodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        
        NSUInteger idx = (i / 3) * 4;
        output[idx + 0] = kTPBase64EncodingTable[(value >> 18) & 0x3F];
        output[idx + 1] = kTPBase64EncodingTable[(value >> 12) & 0x3F];
        output[idx + 2] = (i + 1) < length ? kTPBase64EncodingTable[(value >> 6)  & 0x3F] : '=';
        output[idx + 3] = (i + 2) < length ? kTPBase64EncodingTable[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[NSString alloc] initWithData:mutableData encoding:NSASCIIStringEncoding];
}

static NSString *const kTPTentContentType = @"application/vnd.tent.v0+json";


#pragma mark - NSString extensions for HMACSHA256

@interface NSString (TPHMACSHA256Encoding)
+ (NSString *)HMACSHA256EncodedStringWithString:(NSString *)string key:(NSString *)key;
@end

@implementation NSString (TPHMACSHA256Encoding)
+ (NSString *)HMACSHA256EncodedStringWithString:(NSString *)string key:(NSString *)key;
{
    const char *cKey = [key cStringUsingEncoding:NSUTF8StringEncoding];
    const char *cData = [string cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:CC_SHA256_DIGEST_LENGTH];
    
    return TPBase64EncodedStringFromData(HMAC);
}
@end


#pragma mark 

@interface TPTentHTTPClient ()

@property (nonatomic, strong) NSString *tentClientId;
@property (nonatomic, strong) NSString *tentState;
@property (nonatomic, strong) NSString *tentMacAlgorithm;
@property (nonatomic, strong) NSString *tentMacKeyId;
@property (nonatomic, strong) NSString *tentMacKey;
@property (nonatomic, strong) NSString *tentAccessToken;

@end

#pragma mark
@implementation TPTentHTTPClient

#pragma mark - Lifecycle

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    [self setParameterEncoding:AFJSONParameterEncoding];
	[self setDefaultHeader:@"Accept" value:kTPTentContentType];
    [AFJSONRequestOperation addAcceptableContentTypes:[NSSet setWithObject:kTPTentContentType]];
    
    return self;
}

#pragma mark - AFHTTPClient

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters
{
    NSMutableURLRequest *request = [super requestWithMethod:method path:path parameters:parameters];
    
    if ([method isEqualToString:@"POST"]) {
        [request setValue:kTPTentContentType forHTTPHeaderField:@"Content-Type"];
    }
    
    NSString *authorizationHeader = [self authorizationHeaderForRequest:request];
    if (authorizationHeader) {
        [request setValue:authorizationHeader forHTTPHeaderField:@"Authorization"];
    }
    
    return request;
}

#pragma mark - Public methods

- (BOOL)isRegisteredWithBaseURL
{
    return self.tentAccessToken.length > 0;
}

- (void)registerWithBaseURL
{
    if ([self isRegisteredWithBaseURL]) {
        NSLog(@"Token found - skipping App registration");
        return;
    }
    
    if (![self mainBundleContainsURLScheme:self.delegate.customURLScheme]) {
        NSLog(@"Can't find a match for _customURLScheme in mainBundle");
        return;
    }
    
    if (!self.baseURL) {
        NSLog(@"Cannot register against an unspecified URI");
        return;
    }
    
    self.tentState = [[[NSProcessInfo processInfo] globallyUniqueString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
    
    NSDictionary *params = @{@"name": self.delegate.appName,
        @"description": self.delegate.appDescription,
        @"url": [self.delegate.appWebsiteURL absoluteString],
        @"redirect_uris": @[[NSString stringWithFormat:@"%@://oauth", self.delegate.customURLScheme]],
        @"scopes": self.delegate.scopes};
    
    NSMutableURLRequest *request = [self requestWithMethod:@"POST" path:@"apps" parameters:params];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        self.tentMacAlgorithm = JSON[@"mac_algorithm"];
        self.tentMacKey = JSON[@"mac_key"];
        self.tentMacKeyId = JSON[@"mac_key_id"];
        self.tentClientId = JSON[@"id"];
        
        NSDictionary *authRequestParams = @{@"client_id": self.tentClientId,
            @"tent_profile_info_types": @"all",
            @"tent_post_types": @"all",
            @"redirect_uri": [NSString stringWithFormat:@"%@://oauth", self.delegate.customURLScheme],
            @"scope": [[self.delegate.scopes allKeys] componentsJoinedByString:@","],
            @"state": self.tentState};
        
        NSString *authRequestURLString = [NSString stringWithFormat:@"%@%@%@", self.baseURL, @"/oauth/authorize?", AFQueryStringFromParametersWithEncoding(authRequestParams, NSUTF8StringEncoding)];
        
        NSURL *authRequestURL = [NSURL URLWithString:authRequestURLString];
        
        if (![[UIApplication sharedApplication] openURL:authRequestURL]) {
            NSLog(@"%@%@",@"Failed to open url:",[authRequestURL description]);
        }
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"Something went very wrong");
    }];
    
    [self enqueueHTTPRequestOperation:operation];
}

- (BOOL)handleOpenURL:(NSURL *)url
{
    NSDictionary *queryDictionary = [url queryDictionary];
    
    if (![self.tentState isEqualToString:queryDictionary[@"state"]]) {
        return NO;
    }
    
    NSMutableURLRequest *request = [self requestWithMethod:@"POST"
                                                      path:[NSString stringWithFormat:@"apps/%@/authorizations", self.tentClientId]
                                                parameters:@{@"code": queryDictionary[@"code"], @"token_type": @"mac"}];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        if (JSON[@"access_token"]) {
            
            self.tentAccessToken = JSON[@"access_token"];
            self.tentMacKey = JSON[@"mac_key"];
            
            if ([self.delegate respondsToSelector:@selector(httpClientDidRegisterWithBaseURL:)]) {
                [self.delegate httpClientDidRegisterWithBaseURL:self];
            }
            
        }
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        NSLog(@"Something went very wrong");
    }];
    
    [self enqueueHTTPRequestOperation:operation];
    
    return YES;
}

#pragma mark - Private methods

- (NSString *)authorizationHeaderForRequest:(NSURLRequest *)request
{
    if (self.tentAccessToken.length == 0 && self.tentMacKeyId.length == 0) {
        return nil;
    }
    
    long secs = round([[NSDate date] timeIntervalSince1970]);
    NSString *timeStamp = [NSString stringWithFormat:@"%ld", secs];
    NSString *nonce = [[[NSProcessInfo processInfo] globallyUniqueString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
    
    // Create the normalised request string (http://tools.ietf.org/html/draft-ietf-oauth-v2-http-mac-01#section-3.2.1)
    NSMutableString *normalisedRequestString = [NSMutableString stringWithString:timeStamp];
    [normalisedRequestString appendFormat:@"\n%@\n", nonce];
    [normalisedRequestString appendFormat:@"%@\n", request.HTTPMethod];
    [normalisedRequestString appendFormat:@"%@\n", request.URL.path];
    [normalisedRequestString appendFormat:@"%@\n", request.URL.host];
    
    NSString *port = [request.URL.port stringValue];
    if (!port) {
        port = ([request.URL.scheme isEqualToString:@"http"]) ? @"80" : @"443";
    }
    [normalisedRequestString appendFormat:@"%@\n\n", port];
    
    NSString *mac = [NSString HMACSHA256EncodedStringWithString:normalisedRequestString key:self.tentMacKey];
    NSString *authorizationId = (self.tentAccessToken.length > 0) ? self.tentAccessToken : self.tentMacKeyId;
    
    return [NSString stringWithFormat:@"MAC id=\"%@\", ts=\"%@\", nonce=\"%@\", mac=\"%@\"", authorizationId, timeStamp, nonce, mac];
}

- (BOOL)mainBundleContainsURLScheme:(NSString *)urlScheme
{
    if (self.delegate.customURLScheme.length == 0) {
        return NO;
    }
    
    NSArray *types = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleURLTypes"];
    for (id type in types) {
        if ([type isKindOfClass:[NSDictionary class]]) {
            NSArray *schemes = [type valueForKey:@"CFBundleURLSchemes"];
            for (id scheme in schemes) {
                if ([scheme isEqualToString:urlScheme]) {
                    return YES;
                }
            }
        }
    }
    
    return NO;
}




@end
