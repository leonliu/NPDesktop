//
//  AppDelegate.h
//  NPDesktop
//
//  Created by leon@github on 13-2-28.
//  Copyright (c) 2013年 leon@github. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RFBViewController;
@class ServerListViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) ServerListViewController *viewController;

@end
