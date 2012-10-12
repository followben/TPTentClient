//
//  NewStatusPostViewController.h
//  TentStatusExample
//
//  Created by Ben Stovold on 04/10/2012.
//  Copyright (c) 2012 Thoughtful Pixel. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol NewStatusPostViewControllerDelegate;

@class TentStatusClient;

@interface NewStatusPostViewController : UIViewController

@property (nonatomic, strong) TentStatusClient *tentClient;

@property (nonatomic, weak) id<NewStatusPostViewControllerDelegate> delegate;

@end

@protocol NewStatusPostViewControllerDelegate <NSObject>
@optional
- (void)newStatusPostViewController:(NewStatusPostViewController *)controller didPostStatus:(BOOL)didPost;
@end