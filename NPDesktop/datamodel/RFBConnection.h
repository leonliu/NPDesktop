//
//  RFBConnection.h
//  NPDesktop
//
//  Created by leon@github on 3/5/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#import "rfbproto.h"
#import "RFBRect.h"

extern NSString *const RFBConnectionErrorDomain;

enum RFBConnectionError
{
	RFBConnectionNoError = 0,            // Never used
	RFBConnectionSocketError,            // Socket error, detailed error explained in enum GCDAsyncSocketError
    RFBConnectionProtocolError,          // Server either does not support VNC or version not mapped
    RFBConnectionSecurityTypeError,      // Security type negotiation error
    RFBConnectionAuthFailureError,       // Server failed the connection due to invalid security or else
    RFBConnectionAuthNeedPwdError,       // Password is needed for authentication
};

@protocol RFBConnectionDelegate;
@class RFBHandler;
@class RFBServerData;
@interface RFBConnection : NSObject <GCDAsyncSocketDelegate>
{
    NSInteger _tag;
    GCDAsyncSocket *_socket;
    dispatch_queue_t _socketQueue;
    RFBServerData *_serverData;
    NSMutableData *_recvBuf;
}

@property NSInteger tag;
@property RFBServerData *serverData;
@property NSUInteger rfbMajorVersion;
@property NSUInteger rfbMinorVersion;
@property RFBHandler *handler;
@property rfbPixelFormat pixelFormat;
@property BOOL receivingFrameBufferUpdate;
@property(weak) id<RFBConnectionDelegate> delegate;

- (id)initWithServerData:(RFBServerData *)svr;

- (void)setPassword:(NSString *)pwd;

- (int)bytesPerPixel;
- (rfbPixelFormat)defaultPixelFormat;
- (BOOL)compareLocalFormatWithRemote:(rfbPixelFormat)format;

- (BOOL)connect;
- (void)close;

- (void)sendProtocolVersion;
- (void)sendSecurityType:(CARD8)secType;
- (void)sendAuthResponse:(NSData *)cdata;
- (void)sendClientInit;
- (void)sendSetPixelFormat:(rfbPixelFormat)format;
- (void)sendSetEncodings;
- (void)sendFrameBufferUpdateRequest:(CGRect)rect incremental:(BOOL)inc;
- (void)sendPointerEvent:(CARD8)buttonMask position:(CGPoint)pos;
- (void)sendKeyEvent:(CARD32)key downflag:(BOOL)down;

// request incremental frame buffer update with delay
- (void)queueFrameBufferUpdateRequest:(CGRect)rect;

- (void)recvData:(NSUInteger)length;

@end

@protocol RFBConnectionDelegate <NSObject>

- (void)connection:(RFBConnection *)conn didReceiveServerInit:(rfbServerInitMsg)msg;
- (void)connection:(RFBConnection *)conn didReceiveDesktopName:(NSString *)name;
- (void)connection:(RFBConnection *)conn didReceiveFramebufferUpdate:(rfbFramebufferUpdateMsg)msg;
- (void)connection:(RFBConnection *)conn didReceiveDataForRect:(RFBRect *)aRect;
- (void)connection:(RFBConnection *)conn didReceiveFillColor:(NSData *)cData forRect:(rfbRectangle)rect;
- (void)connection:(RFBConnection *)conn didReceiveDataForRect:(RFBRect *)aRect withPalette:(NSData *)palette;
- (void)connection:(RFBConnection *)conn didReceiveCopyRect:(rfbCopyRect)origin forRect:(rfbRectangle)rect;
- (void)connection:(RFBConnection *)conn shouldInvalidateRect:(CGRect)rect;
- (void)connection:(RFBConnection *)conn didCompleteFramebufferUpdate:(int)nRects;

- (void)connection:(RFBConnection *)conn shouldCloseWithError:(NSError *)error;
- (void)connection:(RFBConnection *)conn didCloseWithError:(NSError *)error;

@end
