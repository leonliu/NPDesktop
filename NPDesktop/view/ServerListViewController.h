//
//  ServerListViewController.h
//  NPDesktop
//
//  Created by leon@github on 3/18/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RFBViewController.h"

@interface ServerListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, RFBViewControllerDisplayDelegate>

@property (strong, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIView *serverInfoView;
@property (strong, nonatomic) IBOutlet UITextField *addrField;
@property (strong, nonatomic) IBOutlet UITextField *portField;
@property (strong, nonatomic) IBOutlet UITextField *pwdField;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *editButton;
@property (strong, nonatomic) IBOutlet UIButton *doneSvrInfoButton;
@property (strong, nonatomic) IBOutlet UIButton *cancelSvrInfoButton;

- (IBAction)doneServerInfo:(id)sender;
- (IBAction)cancelServerInfo:(id)sender;

- (IBAction)addBtnTapped:(id)sender;
- (IBAction)editBtnTapped:(id)sender;

@end
