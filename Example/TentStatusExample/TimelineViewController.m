//
//  TimelineViewController.m
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
    
    __weak TimelineViewController *weakSelf = self;
    
    [[TentStatusClient sharedClient] postRepresentationsWithSuccess:^(NSArray *representations) {
        NSMutableArray *postArray = [NSMutableArray arrayWithCapacity:[representations count]];
        
        for (NSDictionary *representation in representations) {
            if ([representation[@"type"] isEqualToString:TPTentClientPostTypeStatus]) {
                StatusPost *statusPost = [[StatusPost alloc] init];
                statusPost.entityURI = representation[@"entity"];
                statusPost.publishedAtDate = [NSDate dateWithTimeIntervalSince1970:[representation[@"published_at"] doubleValue]];
                NSDictionary *content = representation[@"content"];
                statusPost.status = content[@"text"];
                [postArray addObject:statusPost];
            }
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
    cell.entityLabel.text = statusPost.entityURI;
    cell.publishedAtLabel.text = [NSDateFormatter localizedStringFromDate:statusPost.publishedAtDate
                                                                dateStyle:NSDateFormatterShortStyle
                                                                timeStyle:NSDateFormatterShortStyle];
    return cell;
}

@end
