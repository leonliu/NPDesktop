//
//  RFBInitializer.m
//  NPDesktop
//
//  Created by leon@github on 3/26/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import "RFBInitializer.h"
#import "RFBMessageHandler.h"
#import "Utility.h"

@interface RFBInitializer()

- (NSUInteger)processServerInit:(NSData *)data from:(RFBConnection *)connection;
- (NSUInteger)processDesktopName:(NSData *)data from:(RFBConnection *)connection;

@end

@implementation RFBInitializer

@synthesize state;

- (id)init
{
    if ((self = [super init])) {
        state = RFBInitializerStateIdle;
    }
    
    return self;
}

- (BOOL)start:(RFBConnection *)connection
{
    [connection sendClientInit];
        
    // read ServerInit
    self.nbytesWaiting = sz_rfbServerInitMsg;
    self.state = RFBInitializerStateWaitServerInit;
    
    [connection setHandler:self];
    
    return YES;
}

- (NSUInteger)processMessage:(NSData *)data from:(RFBConnection *)connection
{
    NSUInteger ret = 0;
    
    switch (state) {
        case RFBInitializerStateWaitServerInit:
            ret = [self processServerInit:data from:connection];
            break;
        case RFBInitializerStateWaitDesktopName:
            ret = [self processDesktopName:data from:connection];
            break;
            
        default:
            DLogError(@"unknown state");
            break;
    }
    
    return ret;
}

#pragma mark - private methods
- (NSUInteger)processServerInit:(NSData *)data from:(RFBConnection *)connection
{
    if (data.length < self.nbytesWaiting) {
        DLogInfo(@"\ndata length=%d, bytes wanted=%ld", data.length, self.nbytesWaiting);
        return 0;
    }
    
    NSUInteger ret = self.nbytesWaiting;
    
    rfbServerInitMsg msg;
    [data getBytes:&msg length:sz_rfbServerInitMsg];
    
    msg.framebufferWidth = ntohs(msg.framebufferWidth);
    msg.framebufferHeight = ntohs(msg.framebufferHeight);
    msg.format.redMax = ntohs(msg.format.redMax);
    msg.format.greenMax = ntohs(msg.format.greenMax);
    msg.format.blueMax = ntohs(msg.format.blueMax);
    msg.nameLength = ntohl(msg.nameLength);
    
    _desktopNameLen = msg.nameLength;
    
    DLogInfo(@"\n width: %d\n height: %d\n", msg.framebufferWidth, msg.framebufferHeight);
    DLogInfo(@"%@", [Utility rfbPixelFormatToString:msg.format]);
    
    if (connection.delegate) {
        [connection.delegate connection:connection didReceiveServerInit:msg];
    }
    
    if (msg.nameLength > 0) {
        self.nbytesWaiting = msg.nameLength * sizeof(CARD8);
        self.state = RFBInitializerStateWaitDesktopName;
    } else {
        RFBMessageHandler *handler = [[RFBMessageHandler alloc] init];
        [handler start:connection];
    }
    
    return ret;
}

- (NSUInteger)processDesktopName:(NSData *)data from:(RFBConnection *)connection
{
    if (data.length < self.nbytesWaiting) {
        DLogInfo(@"\ndata length=%d, bytes wanted=%ld", data.length, self.nbytesWaiting);
        return 0;
    }
    
    NSUInteger ret = self.nbytesWaiting;
    
    NSData *strData = [data subdataWithRange:NSMakeRange(0, _desktopNameLen*sizeof(CARD8))];
    NSString *name = [[NSString alloc] initWithData:strData encoding:NSUTF8StringEncoding];
    DLogInfo(@"desktop name: %@", name);
    
    if (connection.delegate) {
        [connection.delegate connection:connection didReceiveDesktopName:name];
    }
    
    RFBMessageHandler *handler = [[RFBMessageHandler alloc] init];
    [handler start:connection];
    
    return ret;
}

@end
