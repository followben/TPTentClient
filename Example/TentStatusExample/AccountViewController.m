//
//  AccountViewController.m
//  TentStatusExample
//
//  Created by Ben Stovold on 03/10/2012.
//  Copyright (c) 2012 Thoughtful Pixel. All rights reserved.
//

#import "AccountViewController.h"
#import "TentStatusClient.h"
#import "NSURL+TPEquivalence.h"

@interface AccountViewController () <UITextFieldDelegate>

@property (nonatomic, strong) IBOutlet UITextField *entityURIField;
@property (nonatomic, strong) NSURL *entityURL;
@property (nonatomic, strong) NSURL *tentServerURL;

@end

@implementation AccountViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didAuthorizeWithEntity:)
                                                 name:TPTentClientDidRegisterWithEntityNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.entityURIField.text.length == 0) {
        self.entityURIField.text = @"https://";
    }
    
    [self.entityURIField becomeFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSURL *entityURL = [NSURL URLWithString:textField.text];
    if (!entityURL) {
        return NO;
    }
    
    [textField resignFirstResponder];
    
    if ([self.entityURL isEquivalent:entityURL] &&
        [[TentStatusClient sharedClient] isAuthorizedWithTentServer:self.tentServerURL]) {
        [self showTimeline];
        return YES;
    }
    
    self.entityURL = entityURL;
    
    __weak AccountViewController *weakSelf = self;
    [[TentStatusClient sharedClient] discoverTentServerForEntity:self.entityURL success:^(NSURL *tentServerURL) {
        if ([weakSelf.tentServerURL isEquivalent:tentServerURL] &&
            [[TentStatusClient sharedClient] isAuthorizedWithTentServer:weakSelf.tentServerURL]) {
            [weakSelf showTimeline];
        } else {
            weakSelf.tentServerURL = tentServerURL;
            [[TentStatusClient sharedClient] authorizeWithTentServer:weakSelf.tentServerURL];
        }
    } failure:nil];

    return YES;
}

- (void)didAuthorizeWithEntity:(NSDictionary *)notification
{
    [self showTimeline];
}

- (void)showTimeline
{
    [self performSegueWithIdentifier:@"ShowTimeline" sender:self];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
