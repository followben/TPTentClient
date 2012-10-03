//
//  AccountViewController.m
//  TentStatusExample
//
//  Created by Ben Stovold on 03/10/2012.
//  Copyright (c) 2012 Thoughtful Pixel. All rights reserved.
//

#import "AccountViewController.h"
#import "TentStatusClient.h"

@interface AccountViewController () <UITextFieldDelegate>

@property (nonatomic, strong) IBOutlet UITextField *entityURIField;

@end

@implementation AccountViewController

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
    
    if (![[TentStatusClient sharedClient] isAuthorizedWithEntityURL:entityURL]) {
        [[TentStatusClient sharedClient] authorizeWithEntityURL:entityURL];
    } else {
        [self showTimeline];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didAuthorizeWithEntity:)
                                                 name:TPTentClientDidRegisterWithEntityNotification
                                               object:nil];
    [textField resignFirstResponder];
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
