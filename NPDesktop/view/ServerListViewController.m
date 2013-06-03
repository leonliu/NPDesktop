//
//  ServerListViewController.m
//  NPDesktop
//
//  Created by leon@github on 3/18/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import "ServerListViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "RFBServerManager.h"

@interface ServerListViewController ()

@end

@implementation ServerListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.containerView.layer.masksToBounds = NO;
    self.containerView.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.containerView.layer.shadowRadius = 2.0f;
    self.containerView.layer.shadowOffset = CGSizeMake(4.0f, 4.0f);
    self.containerView.layer.shadowOpacity = 0.9f;
    
    self.serverInfoView.layer.masksToBounds = NO;
    self.serverInfoView.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.serverInfoView.layer.shadowRadius = 2.0f;
    self.serverInfoView.layer.shadowOffset = CGSizeMake(4.0f, 4.0f);
    self.serverInfoView.layer.shadowOpacity = 0.9;
    self.serverInfoView.center = CGPointMake(1536.f, 374.f);
    
    self.addrField.layer.masksToBounds = YES;
    self.addrField.layer.borderColor = [[UIColor cyanColor] CGColor];
    self.addrField.layer.cornerRadius = 4.0f;
    self.addrField.layer.borderWidth = 5.0f;
    
    self.portField.layer.masksToBounds = YES;
    self.portField.layer.borderColor = [[UIColor cyanColor] CGColor];
    self.portField.layer.cornerRadius = 4.0f;
    self.portField.layer.borderWidth = 5.0f;
    
    self.pwdField.layer.masksToBounds = YES;
    self.pwdField.layer.borderColor = [[UIColor cyanColor] CGColor];
    self.pwdField.layer.cornerRadius = 4.0f;
    self.pwdField.layer.borderWidth = 5.0f;
    
    self.doneSvrInfoButton.backgroundColor = [UIColor lightGrayColor];
    self.doneSvrInfoButton.layer.borderColor = [[UIColor cyanColor] CGColor];
    self.doneSvrInfoButton.layer.borderWidth = 1.0f;
    self.cancelSvrInfoButton.backgroundColor = [UIColor lightGrayColor];
    self.cancelSvrInfoButton.layer.borderColor = [[UIColor cyanColor] CGColor];
    self.cancelSvrInfoButton.layer.borderWidth = 1.0f;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doneServerInfo:(id)sender {
    
    if ((self.addrField.text == nil) || ([self.addrField.text length] == 0)) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:@"Please put in address"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        
        return;
    }
    
    if ((self.portField.text == nil) ||
        ([self.portField.text length] == 0) ||
        ([self.portField.text integerValue] > 65535)) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:@"Please put in port"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        
        return;
    }
                              
    RFBServerData *server = [[RFBServerData alloc] init];
    server.name = @"server";
    server.host = [self.addrField text];
    server.port = [[self.portField text] intValue];
    server.password = [self.pwdField text];
    
    [[RFBServerManager sharedInstance] addServer:server];
    
    [UIView animateWithDuration:0.5 animations:^{
        [self.containerView setCenter:CGPointMake(512.f, 374.f)];
        [self.serverInfoView setCenter:CGPointMake(1536.f, 374.f)];
    } completion:^(BOOL finished) {
        [[RFBServerManager sharedInstance] saveServerList];
        [self.tableView reloadData];
    }];
}

- (IBAction)cancelServerInfo:(id)sender {
    
    [UIView animateWithDuration:0.5f animations:^{
        
        [self.containerView setCenter:CGPointMake(512.f, 374.f)];
        [self.serverInfoView setCenter:CGPointMake(1536.f, 374.f)];
    }];
}

- (IBAction)addBtnTapped:(id)sender
{
    [UIView animateWithDuration:0.5f animations:^{
       
        [self.containerView setCenter:CGPointMake(-512.f, 374.f)];
        [self.serverInfoView setCenter:CGPointMake(512.f, 374.f)];
    }];
}

- (IBAction)editBtnTapped:(id)sender
{
    if (self.tableView.editing) {
        [self.tableView setEditing:NO];
        self.editButton.title = @"Edit";
    } else {
        [self.tableView setEditing:YES];
        self.editButton.title = @"Done";
    }
}

#pragma mark - table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[RFBServerManager sharedInstance] countOfServers];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ServerCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    RFBServerData *server = [[RFBServerManager sharedInstance] objectInServersAtIndex:indexPath.row];
    
    cell.imageView.image = [UIImage imageNamed:@"desk.png"];
    cell.textLabel.text = server.name;
    cell.detailTextLabel.text = server.host;
    cell.indentationLevel = 2;
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // delete the server
        [[RFBServerManager sharedInstance] removeObjectFromServersAtIndex:indexPath.row];
        [[RFBServerManager sharedInstance] saveServerList];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    RFBServerData *server = [[RFBServerManager sharedInstance] objectInServersAtIndex:indexPath.row];
    if (server) {
        // prevent the automatic screen lock
        [UIApplication sharedApplication].idleTimerDisabled = YES;
        
        RFBViewController *rvc = [[RFBViewController alloc] initWithServer:server];
        rvc.delegate = self;
        rvc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [self presentViewController:rvc animated:YES completion:NULL];
    } else {
        DLogError(@"Failed to find server data at index: %d", indexPath.row);
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 120.f;
}

#pragma mark - RFBViewController modal display delegate
- (void)viewController:(RFBViewController *)rvc didFinishDisplay:(int)sid
{
    [self dismissViewControllerAnimated:NO completion:NULL];
    [self.tableView reloadData];
    
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

@end
