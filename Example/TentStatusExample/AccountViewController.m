//
//  AccountViewController.m
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

#import "AccountViewController.h"
#import "TentStatusClient.h"
#import "NSURL+TPEquivalence.h"
#import "TimelineViewController.h"

@interface AccountViewController () <UITextFieldDelegate>

@property (nonatomic, strong) IBOutlet UIView *footerView;
@property (nonatomic, weak) IBOutlet UITextField *entityURIField;

@end

@implementation AccountViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleOpenURLNotification:)
                                                 name:@"AppDelegateReceivedOpenURL"
                                               object:nil];
    self.footerView.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.entityURIField.text.length == 0) {
        self.entityURIField.text = @"https://";
    }
    
    [self.entityURIField becomeFirstResponder];
}

- (IBAction)forgetAuthDetails:(id)sender
{
    [self.tentClient removeAuthTokens];
    self.footerView.hidden = YES;
    self.entityURIField.text = @"https://";
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSURL *entity = [NSURL URLWithString:textField.text];
    if (!entity) {
        return NO;
    }
    
    [textField resignFirstResponder];
    
    if (!self.tentClient || ![self.tentClient.entity isEquivalent:entity]) {
        self.tentClient = [[TentStatusClient alloc] initWithEntity:entity];
    }
    
    [self.tentClient checkAuthTokensWithBlock:^(BOOL authInfoFound) {
        if (authInfoFound) {
            [self showTimeline];
        } else {
            [self.tentClient authorizeWithEntitySuccess:^{
                [self showTimeline];
            } failure:nil];
        }
    }];

    return YES;
}

- (void)handleOpenURLNotification:(NSNotification *)note
{
    NSURL *oAuthURL = (NSURL *)[note.userInfo objectForKey:@"urlKey"];
    [self.tentClient handleOpenURL:oAuthURL];
}

- (void)showTimeline
{
    [self performSegueWithIdentifier:@"ShowTimeline" sender:self];
    self.footerView.hidden = NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ShowTimeline"]) {
        TimelineViewController *vc = (TimelineViewController *)[segue destinationViewController];
        vc.tentClient = self.tentClient;
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
