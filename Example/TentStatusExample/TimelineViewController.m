//
//  TimelineViewController.m
//  TentStatusExample
//
//  Created by Ben Stovold on 02/10/2012.
//  Copyright (c) 2012 Thoughtful Pixel. All rights reserved.
//

#import "TimelineViewController.h"
#import "TentStatusClient.h"
#import "StatusPost.h"
#import "StatusPostCell.h"

@interface TimelineViewController () <TPTentClientDelegate>

@property (nonatomic, strong) NSArray *statusArray;

@end

@implementation TimelineViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSURL *entityURL = [NSURL URLWithString:@"https://followben.tent.is/tent"];
    
    if (![[TentStatusClient sharedClient] isRegisteredWithEntityURL:entityURL]) {
        [[TentStatusClient sharedClient] registerWithEntityURL:entityURL];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(registeredWithTentity:)
                                                 name:TPTentClientDidRegisterWithEntityNotification
                                               object:nil];
}
    
- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)registeredWithTentity:(NSDictionary *)notification
{
    __weak TimelineViewController *weakSelf = self;
    
    [[TentStatusClient sharedClient] postRepresentationsWithSuccess:^(NSArray *representations) {
        NSMutableArray *postArray = [NSMutableArray arrayWithCapacity:[representations count]];
        
        for (NSDictionary *representation in representations) {
            StatusPost *statusPost = [[StatusPost alloc] init];
            NSDictionary *content = representation[@"content"];
            statusPost.status = content[@"text"];
            statusPost.publishedAtDate = [NSDate dateWithTimeIntervalSince1970:[representation[@"published_at"] doubleValue]];
            [postArray addObject:statusPost];
        }
        
        weakSelf.statusArray = postArray;
        [weakSelf.tableView reloadData];
        
    } failure:nil];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO: Fix this
    StatusPostCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StatusPostCell"];
    StatusPost *statusPost = (StatusPost *)[self.statusArray objectAtIndex:indexPath.row];
    cell.statusLabel.text = statusPost.status;
    CGFloat cellHeight = cell.frame.size.height;
    CGFloat labelHeight = 19.f;
    CGFloat adjustedlabelHeight = [cell.statusLabel sizeThatFits:CGSizeMake(280.f, CGFLOAT_MAX)].height;
    CGFloat adjustedCellHeight = cellHeight + (adjustedlabelHeight - labelHeight);
    return adjustedCellHeight;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.statusArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    StatusPostCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StatusPostCell"];
    StatusPost *statusPost = (StatusPost *)[self.statusArray objectAtIndex:indexPath.row];
    cell.statusLabel.text = statusPost.status;
    cell.publishedAtLabel.text = [NSDateFormatter localizedStringFromDate:statusPost.publishedAtDate
                                                                dateStyle:NSDateFormatterShortStyle
                                                                timeStyle:NSDateFormatterShortStyle];
    return cell;
}

@end
