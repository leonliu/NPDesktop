//
//  RFBHandler.m
//  NPDesktop
//
//  Created by leon@github on 3/12/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import "RFBHandler.h"

NSString *const RFBHandleRectKey = @"RFBHandleRectKey";
NSString *const RFBHandleFbUpdateKey = @"RFBHandleFbUpdateKey";

@implementation RFBHandler

@synthesize parent;
@synthesize nbytesWaiting;


- (id)init
{
    return [self initWithParent:nil];
}

- (id)initWithParent:(RFBHandler *)aParent
{
    if ((self = [super init])) {
        parent = aParent;
        nbytesWaiting = 0;
    }
    
    return self;
}

- (BOOL)start:(RFBConnection *)connection
{
    DLogError(@"SHOULD NOT CALL ME!");
    return YES;
}

- (NSUInteger)handleMessage:(NSData *)data from:(RFBConnection *)connection
{
    NSUInteger bytesDone = 0;
    NSUInteger bytesLeft = data.length;
    NSUInteger ret = 0;
    
    while (bytesLeft > 0) {
        
        ret = [self processMessage:[data subdataWithRange:NSMakeRange(bytesDone, bytesLeft)] from:connection];
        if (ret > 0) {
            bytesDone += ret;
            bytesLeft -= ret;
        } else {
            break;
        }
    }
    
    return bytesDone;
}

- (NSUInteger)processMessage:(NSData *)data from:(RFBConnection *)connection
{
    DLogError(@"SHOULD NOT CALL ME!");
    return 0;
}

- (void)child:(RFBHandler *)handler finishedJob:(NSDictionary *)job onConnection:(RFBConnection *)connection
{
    DLogError(@"SHOULD NOT CALL ME!");
}

@end
