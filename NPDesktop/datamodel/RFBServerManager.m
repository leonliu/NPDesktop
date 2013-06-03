//
//  RFBServerManager.m
//  NPDesktop
//
//  Created by leon@github on 13-2-28.
//  Copyright (c) 2013年 leon@github. All rights reserved.
//

#import "RFBServerManager.h"
#import "Utility.h"

static RFBServerManager *_instance = nil;

@implementation RFBServerManager

+ (RFBServerManager *)sharedInstance
{
    @synchronized(self)
    {
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    }
    
    return _instance;
}

- (id)init
{
    if (self = [super init]) {
        _servers = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (NSUInteger)countOfServers
{
    return [_servers count];
}

- (id)objectInServersAtIndex:(NSUInteger)index
{
    return [_servers objectAtIndex:index];
}

- (void)insertObject:(RFBServerData *)server inServersAtIndex:(NSUInteger)index
{
    for (RFBServerData *svr in _servers) {
        if ((svr == server) || (([svr.host isEqualToString:server.host]) && (svr.port == server.port))) {
            DLogInfo(@"Sever data already exists.");
            return;
        }
    }
    
    [_servers insertObject:server atIndex:index];
}

- (void)removeObjectFromServersAtIndex:(NSUInteger)index
{
    [_servers removeObjectAtIndex:index];
}

- (BOOL)addServer:(RFBServerData *)server
{
    NSAssert(server != nil, @"Null input.");
    
    for (RFBServerData *svr in _servers) {
        if ((svr == server) || (([svr.host isEqualToString:server.host]) && (svr.port == server.port))) {
            DLogInfo(@"Sever data already exists.");
            return NO;
        }
    }
    
    [_servers addObject:server];
    return YES;
}

- (RFBServerData *)serverWithId:(int)sid
{
    for (RFBServerData *svr in _servers) {
        if (svr.serverId == sid) {
            return svr;
        }
    }
    
    return nil;
}

- (void)removeServer:(RFBServerData *)server
{
    NSAssert(server != nil, @"Null input.");
    [_servers removeObject:server];
}

- (void)removeServerWithId:(int)sid
{
    NSUInteger count = [_servers count];
    for (int i = 0; i < count; i++) {
        RFBServerData *svr = [_servers objectAtIndex:i];
        if (svr.serverId == sid) {
            [_servers removeObjectAtIndex:i];
            break;
        }
    }
}

- (BOOL)loadServerList
{
    /*
     int _serverId;
     NSString *_name;
     
     NSString *_host;
     NSString *_password;
     int _port;
     BOOL _shared;
     BOOL _viewOnly; */
    
    NSString *path = [Utility configPath];
    if (!path) {
        return NO;
    }
    
    NSString *file = [path stringByAppendingString:@"/servers.plist"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:file]) {
        DLogWarn(@"Server data file does not exist.");
        return NO;
    }
    
    NSArray *ary = [[NSArray alloc] initWithContentsOfFile:file];
    if (!ary) {
        DLogWarn(@"Failed to read server data.");
        return NO;
    }
    
    for (NSDictionary *dict in ary) {
        RFBServerData *svr = [[RFBServerData alloc] init];
        svr.name = [dict objectForKey:@"name"];
        svr.host = [dict objectForKey:@"host"];
        svr.password = [dict objectForKey:@"password"];
        svr.port = [(NSNumber *)[dict objectForKey:@"port"] intValue];
        svr.shared = [(NSNumber *)[dict objectForKey:@"shared"] boolValue];
        svr.viewOnly = [(NSNumber *)[dict objectForKey:@"viewonly"] boolValue];
        
        [_servers addObject:svr];
    }
    
    return YES;
}

- (BOOL)saveServerList
{
    NSString *path = [Utility configPath];
    if (!path) {
        return NO;
    }
    
    NSString *file = [path stringByAppendingString:@"/servers.plist"];
//    if (![[NSFileManager defaultManager] fileExistsAtPath:file]) {
//        return NO;
//    }
    
    NSMutableArray *ary = [[NSMutableArray alloc] init];
    
    for (RFBServerData *svr in _servers) {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        [dict setObject:svr.name forKey:@"name"];
        [dict setObject:svr.host forKey:@"host"];
        [dict setObject:svr.password forKey:@"password"];
        [dict setObject:[NSNumber numberWithInt:svr.port] forKey:@"port"];
        [dict setObject:[NSNumber numberWithBool:svr.shared] forKey:@"shared"];
        [dict setObject:[NSNumber numberWithBool:svr.viewOnly] forKey:@"viewonly"];
        
        [ary addObject:dict];
    }
    
    BOOL ret = YES;
    if (![ary writeToFile:file atomically:NO]) {
        DLogWarn(@"Failed to save server data to file.");
        ret = NO;
    }
    
    return ret;
}

@end
