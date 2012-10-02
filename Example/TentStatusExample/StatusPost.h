//
//  Status.h
//  TentStatusExample
//
//  Created by Ben Stovold on 02/10/2012.
//  Copyright (c) 2012 Thoughtful Pixel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StatusPost : NSObject

@property (nonatomic, strong) NSDate *publishedAtDate;
@property (nonatomic, strong) NSString *status;

@end
