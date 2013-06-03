//
//  RFBServerData.h
//  NPDesktop
//
//  Created by leon@github on 13-2-28.
//  Copyright (c) 2013年 leon@github. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RFBServerData : NSObject
{
    int _serverId;
    NSString *_name;
    
    NSString *_host;
    NSString *_password;
    int _port;
    BOOL _shared;
    BOOL _viewOnly;
    BOOL _rememberName;
}

@property int serverId;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *host;
@property (strong, nonatomic) NSString *password;
@property int port;
@property BOOL shared;
@property BOOL viewOnly;
@property BOOL rememberName;

@end
