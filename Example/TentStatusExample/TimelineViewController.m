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
#import "NewStatusPostViewController.h"

@interface TimelineViewController () <TPTentClientDelegate, NewStatusPostViewControllerDelegate>

@property (nonatomic, strong) NSArray *statusArray;

@end

@implementation TimelineViewController

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Shouldn't need to do this, but hooking up UIRefreshControl in IB doesn't work. Bug?
    [self.refreshControl addTarget:self action:@selector(refreshData:) forControlEvents:UIControlEventValueChanged];
    
    [self refreshData:nil];
}

#pragma mark - Actions

- (IBAction)refreshData:(UIRefreshControl *)sender
{
    __weak TimelineViewController *weakSelf = self;
    
    [[TentStatusClient sharedClient] getPostRepresentationsWithSuccess:^(NSArray *representations) {
        
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
        if (sender) {
            [sender endRefreshing];
        }
        
    } failure:nil];
}

#pragma mark - UIViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ShowNewStatusPost"]) {
        NewStatusPostViewController *vc = (NewStatusPostViewController *)[segue destinationViewController];
        vc.delegate = self;
    }
}

#pragma mark - UITableViewDataSource conformance

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{

    NSString *cellText = ((StatusPost *)[self.statusArray objectAtIndex:indexPath.row]).status;
    UIFont *cellFont = [UIFont fontWithName:@"Helvetica Neue" size:14.0f];
    CGSize constraintSize = CGSizeMake(280.0f, MAXFLOAT);
    CGSize labelSize = [cellText sizeWithFont:cellFont constrainedToSize:constraintSize lineBreakMode:NSLineBreakByTruncatingTail];

    return labelSize.height + 86.0f;
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

#pragma mark - NewStatusPostViewControllerDelegate conformance

- (void)newStatusPostViewController:(NewStatusPostViewController *)controller didPostStatus:(BOOL)didPost
{
    if (didPost) {
        [self refreshData:nil];
    }
}

@end
