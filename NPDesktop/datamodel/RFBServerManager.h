//
//  RFBServerManager.h
//  NPDesktop
//
//  Created by leon@github on 13-2-28.
//  Copyright (c) 2013年 leon@github. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RFBServerData.h"

@interface RFBServerManager : NSObject
{
    NSMutableArray *_servers;
}

+ (RFBServerManager *)sharedInstance;

- (NSUInteger)countOfServers;
- (id)objectInServersAtIndex:(NSUInteger)index;
- (void)insertObject:(RFBServerData *)server inServersAtIndex:(NSUInteger)index;
- (void)removeObjectFromServersAtIndex:(NSUInteger)index;

- (BOOL)addServer:(RFBServerData *)server;
- (RFBServerData *)serverWithId:(int)sid;
- (void)removeServer:(RFBServerData *)server;
- (void)removeServerWithId:(int)sid;

- (BOOL)loadServerList;
- (BOOL)saveServerList;

@end
