//
//  NewStatusPostViewController.m
//  TentStatusExample
//
//  Created by Ben Stovold on 04/10/2012.
//  Copyright (c) 2012 Thoughtful Pixel. All rights reserved.
//

#import "NewStatusPostViewController.h"
#import "TentStatusClient.h"

@interface NewStatusPostViewController () <UITextViewDelegate>

@property (nonatomic, strong) IBOutlet UIBarButtonItem *doneBarButton;
@property (nonatomic, strong) IBOutlet UITextView *textView;

@end

@implementation NewStatusPostViewController

#pragma mark - Lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.textView becomeFirstResponder];
}

#pragma mark - Actions

- (IBAction)cancel:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)post:(id)sender
{
    __weak NewStatusPostViewController *weakSelf = self;
    
    [self.tentClient postStatusWithText:self.textView.text permissions:nil success:^{
        if ([weakSelf.delegate respondsToSelector:@selector(newStatusPostViewController:didPostStatus:)]) {
            [weakSelf.delegate newStatusPostViewController:self didPostStatus:YES];
        }
    } failure:nil];
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITextViewDelegate conformance

- (void)textViewDidChange:(UITextView *)textView
{
    self.doneBarButton.enabled = !(textView.text.length == 0);
}

@end
