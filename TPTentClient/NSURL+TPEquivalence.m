//
//  NSURL+TPEquivalence.m
//  TentStatusExample
//
//  Created by Ben Stovold on 03/10/2012.
//  Copyright (c) 2012 Thoughtful Pixel. All rights reserved.
//

#import "NSURL+TPEquivalence.h"

@implementation NSURL (TPEquivalence)

- (BOOL)isEquivalent:(NSURL *)aURL {
    if ([self isEqual:aURL]) return YES;
    if ([[self scheme] caseInsensitiveCompare:[aURL scheme]] != NSOrderedSame) return NO;
    if ([[self host] caseInsensitiveCompare:[aURL host]] != NSOrderedSame) return NO;
    if ([[self path] compare:[aURL path]] != NSOrderedSame) return NO;
    if ([[self port] compare:[aURL port]] != NSOrderedSame) return NO;
    if ([[self query] compare:[aURL query]] != NSOrderedSame) return NO;
    return YES;
}

@end