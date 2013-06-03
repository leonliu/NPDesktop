//
//  RFBHandler.h
//  NPDesktop
//
//  Created by leon@github on 3/12/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RFBConnection.h"

extern NSString *const RFBHandleRectKey;
extern NSString *const RFBHandleFbUpdateKey;

//
// Base class for Remote Frame Buffer protocol handlers.
// User should not use this class directly.
//

@interface RFBHandler : NSObject

@property RFBHandler *parent;   // strong reference
@property size_t nbytesWaiting; // number of bytes that the handler is waiting from socket

- (id)initWithParent:(RFBHandler *)aParent;

// Method to start the handler, normally in this method specific handler
// reads data from socket.
//
- (BOOL)start:(RFBConnection *)connection;

// Method to handle the protocol data. If the specific object is current
// handler, its handleMessage will be called when the socket receives data.
//
- (NSUInteger)handleMessage:(NSData *)data from:(RFBConnection *)connection;

// Method to process the protocol data. This method should be implemented by subclass.
- (NSUInteger)processMessage:(NSData *)data from:(RFBConnection *)connection;

// For the case that a handler needs subordinate handlers to finish their jobs
// before it self can complete, the method is provided for subordinate handlers
// to notify that they are done.
//
- (void)child:(RFBHandler *)handler finishedJob:(NSDictionary *)job onConnection:(RFBConnection *)connection;

@end

