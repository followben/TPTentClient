//
//  StatusPostCell.h
//  TentStatusExample
//
//  Created by Ben Stovold on 02/10/2012.
//  Copyright (c) 2012 Thoughtful Pixel. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StatusPostCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *statusLabel;
@property (nonatomic, weak) IBOutlet UILabel *entityLabel;
@property (nonatomic, weak) IBOutlet UILabel *publishedAtLabel;

@end
