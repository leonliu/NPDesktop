//
//  RFBServerData.m
//  NPDesktop
//
//  Created by leon@github on 13-2-28.
//  Copyright (c) 2013年 leon@github. All rights reserved.
//

#import "RFBServerData.h"

static int _globalServerId = 1;

@implementation RFBServerData

@synthesize serverId = _serverId;
@synthesize name = _name;
@synthesize host = _host;
@synthesize password = _password;
@synthesize port = _port;
@synthesize shared = _shared;
@synthesize viewOnly = _viewOnly;
@synthesize rememberName = _rememberName;

- (id)init
{
    if (self = [super init]) {
        _globalServerId++;
        _name = [NSString stringWithFormat:@"Server%02d", _globalServerId];
        _serverId = _globalServerId;
        _host = @"localhost";
        _password = nil;
        _port = 5900;
        _shared = NO;
        _viewOnly = YES;
    }
    
    return self;
}

@end
