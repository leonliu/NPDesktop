//
//  RFBConnection.m
//  NPDesktop
//
//  Created by leon@github on 3/5/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import "RFBConnection.h"
#import "RFBServerData.h"
#import "RFBHandshaker.h"
#import "RFBDecoderStore.h"
#import "RFBRawDecoder.h"
#import "RFBTightDecoder.h"
#import "RFBCopyRectDecoder.h"
#import "QualityLevelPseudoDecoder.h"
#import "CompressLevelPseudoDecoder.h"
#import "Utility.h"

static NSInteger _globalConnectionTag = 1;
NSString *const RFBConnectionErrorDomain = @"RFBConnectionErrorDomain";

#define SOCKET_WRITE_TIMEOUT  30
#define SOCKET_READ_TIMEOUT   30
#define SOCKET_READ_TIMEOUT_INFINITE (-1.0)

#define RFB_LAST_ENCODING     rfbEncodingZlibHex
#define MAX_ENCODINGS         20

@interface RFBConnection()


@end

@implementation RFBConnection

@synthesize tag = _tag;
@synthesize serverData = _serverData;
@synthesize rfbMajorVersion;
@synthesize rfbMinorVersion;
@synthesize handler;
@synthesize pixelFormat;
@synthesize receivingFrameBufferUpdate;
@synthesize delegate;

- (id)init
{
    RFBServerData *svr = [[RFBServerData alloc] init];
    return [self initWithServerData:svr];
}

- (id)initWithServerData:(RFBServerData *)svr
{
    if ((self = [super init])) {
        _tag = _globalConnectionTag++;
        _socketQueue = dispatch_queue_create("VNCSocketQueue", NULL);
        _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:_socketQueue];
        _serverData = svr;
        _recvBuf = [[NSMutableData alloc] init];
        
        pixelFormat = [self defaultPixelFormat];
        handler = [[RFBHandshaker alloc] init];
        delegate = nil;
        
        RFBDecoderStore *decoderStore = [RFBDecoderStore sharedInstance];
        decoderStore.preferedEncoding = rfbEncodingTight;
        decoderStore.allowCopyRect = YES;
        
        RFBDecoder *decoder = [[RFBRawDecoder alloc] init];
        [decoderStore addDecoder:decoder withPriority:0];
        
        decoder = [[RFBTightDecoder alloc] init];
        [decoderStore addDecoder:decoder withPriority:9];
        
        decoder = [[RFBCopyRectDecoder alloc] init];
        [decoderStore addDecoder:decoder withPriority:10];
        
//        decoder = [[CompressLevelPseudoDecoder alloc] initWithCompressionLevel:6];
//        [decoderStore addDecoder:decoder withPriority:-1];
        
        decoder = [[QualityLevelPseudoDecoder alloc] initWithQualityLevel:6];
        [decoderStore addDecoder:decoder withPriority:-1];
    }
    
    return self;
}

- (void)setPassword:(NSString *)pwd
{
    NSAssert(_serverData != nil, @"This method does not apply to nil ServerData!");
    [_serverData setPassword:pwd];
}

- (int)bytesPerPixel
{
    return ((pixelFormat.bitsPerPixel + 7) >> 3);
}

- (rfbPixelFormat)defaultPixelFormat
{
    rfbPixelFormat format;
    format.bigEndian = [Utility isSystemBigEndian] ? 1 : 0;
    format.trueColour = 1;
    format.bitsPerPixel = 32;
    format.depth = 24;
    format.redMax = 0xff;
    format.greenMax = 0xff;
    format.blueMax = 0xff;
    
    if (format.bigEndian == 1) {
        // ABGR
        format.redShift = 0;
        format.greenShift = 8;
        format.blueShift = 16;
    } else {
        // ARGB
        format.redShift = 16;
        format.greenShift = 8;
        format.blueShift = 0;
    }
    
    return format;
}

- (BOOL)compareLocalFormatWithRemote:(rfbPixelFormat)format
{
    BOOL ret = NO;
    
    if (format.trueColour == 0) {
        if ((format.bitsPerPixel == pixelFormat.bitsPerPixel) &&
            (format.depth == pixelFormat.depth) &&
            ((format.bigEndian == pixelFormat.bigEndian) || (format.bitsPerPixel == 8)) &&
            (format.trueColour == pixelFormat.trueColour)) {
            ret = YES;
        }
    } else {
        if ((format.bitsPerPixel == pixelFormat.bitsPerPixel) &&
            (format.depth == pixelFormat.depth) &&
            ((format.bigEndian == pixelFormat.bigEndian) || (format.bitsPerPixel == 8)) &&
            (format.trueColour == pixelFormat.trueColour) &&
            (format.redMax == pixelFormat.redMax) &&
            (format.greenMax == pixelFormat.greenMax) &&
            (format.blueMax == pixelFormat.blueMax) &&
            (format.redShift == pixelFormat.redShift) &&
            (format.greenShift == pixelFormat.greenShift) &&
            (format.blueShift == pixelFormat.blueShift)) {
            ret = YES;
        }
    }
    
    return ret;
}

- (BOOL)connect
{
    BOOL ret = NO;
    if (_serverData && _socket) {
        DLogInfo(@"connecting to %@:%d", _serverData.host, _serverData.port);
        
        NSError __autoreleasing *err;
        ret = [_socket connectToHost:_serverData.host onPort:_serverData.port error:&err];
    }
    
    return ret;
}

- (void)close
{
    [_socket disconnect];
    [_recvBuf replaceBytesInRange:NSMakeRange(0, _recvBuf.length) withBytes:NULL length:0];
}

#pragma -
#pragma mark - Client messages

- (void)sendProtocolVersion
{
    rfbProtocolVersionMsg pv;
    pv[sz_rfbProtocolVersionMsg] = '\0';
    sprintf(pv, rfbProtocolVersionFormat, rfbMajorVersion, rfbMinorVersion);
    
    DLogInfo(@"send ProtocolVersion %s", pv);
    
    [_socket writeData:[NSData dataWithBytes:pv length:sz_rfbProtocolVersionMsg]
           withTimeout:SOCKET_WRITE_TIMEOUT
                   tag:0];
}

- (void)sendSecurityType:(CARD8)secType
{
    DLogInfo(@"send SecurityType: %@", [Utility rfbSecurityTypeToString:secType]);
    [_socket writeData:[NSData dataWithBytes:&secType length:sizeof(CARD8)]
           withTimeout:SOCKET_WRITE_TIMEOUT
                   tag:0];
}

- (void)sendClientInit
{
    CARD8 shared = _serverData.shared ? 1 : 0;
    
    DLogInfo(@"send ClientInit: %d", shared);
    
    [_socket writeData:[NSData dataWithBytes:&shared length:sizeof(CARD8)]
           withTimeout:SOCKET_WRITE_TIMEOUT
                   tag:0];
}

- (void)sendAuthResponse:(NSData *)cdata
{
    DLogInfo(@"send AuthResponse");
    [_socket writeData:cdata
           withTimeout:SOCKET_WRITE_TIMEOUT
                   tag:0];
}

- (void)sendSetPixelFormat:(rfbPixelFormat)format
{
    rfbSetPixelFormatMsg spf;
    
    DLogInfo(@"send SetPixelFormat: %@", [Utility rfbPixelFormatToString:format]);
    
    spf.type = rfbSetPixelFormat;
    spf.format = format;
    spf.format.redMax = htons(spf.format.redMax);
    spf.format.greenMax = htons(spf.format.greenMax);
    spf.format.blueMax = htons(spf.format.blueMax);
    
    [_socket writeData:[NSData dataWithBytes:&spf length:sz_rfbPixelFormat] withTimeout:SOCKET_WRITE_TIMEOUT tag:0];
}

- (void)sendSetEncodings
{
    DLogInfo(@"send SetEncodings");
    
    char buf[sz_rfbSetEncodingsMsg + MAX_ENCODINGS * 4];
    rfbSetEncodingsMsg *se = (rfbSetEncodingsMsg *)buf;
    CARD32 *encodings = (CARD32 *)(&buf[sz_rfbSetEncodingsMsg]);
    
    se->type = rfbSetEncodings;
    
    NSArray *encAry = [[RFBDecoderStore sharedInstance] decoderIds];
    int count = [encAry count];
    se->nEncodings = count;
    
    for (int i = 0; i < count; i++) {
        encodings[i] = htonl([(NSNumber *)[encAry objectAtIndex:i] unsignedIntValue]);
    }
    
    int len = sz_rfbSetEncodingsMsg + se->nEncodings * 4;
    se->nEncodings = htons(se->nEncodings);
    
    [_socket writeData:[NSData dataWithBytes:buf length:len] withTimeout:SOCKET_WRITE_TIMEOUT tag:0];
}

- (void)sendFrameBufferUpdateRequest:(CGRect)rect incremental:(BOOL)inc
{
    rfbFramebufferUpdateRequestMsg fbur;
    fbur.type = rfbFramebufferUpdateRequest;
    fbur.incremental = inc ? 1 : 0;
    fbur.x = (CARD16)rect.origin.x;
    fbur.y = (CARD16)rect.origin.y;
    fbur.w = (CARD16)rect.size.width;
    fbur.h = (CARD16)rect.size.height;
    
    DLogInfo(@"\nsend FramebufferUpdateRequest: w=%d, h=%d, incremental: %@", fbur.w, fbur.h, inc ? @"Y" : @"N");
    
    fbur.x = htons(fbur.x);
    fbur.y = htons(fbur.y);
    fbur.w = htons(fbur.w);
    fbur.h = htons(fbur.h);
    
    [_socket writeData:[NSData dataWithBytes:&fbur length:sz_rfbFramebufferUpdateRequestMsg]
           withTimeout:SOCKET_WRITE_TIMEOUT
                   tag:0];
}

- (void)queueFrameBufferUpdateRequest:(CGRect)rect
{
    RFBConnection * __weak weakSelf = self;
    int64_t delayInMs = 20;  // 20 ms
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInMs * NSEC_PER_MSEC);
    dispatch_after(popTime, _socketQueue, ^(void){
        [weakSelf sendFrameBufferUpdateRequest:rect incremental:YES];
    });
}

- (void)sendPointerEvent:(CARD8)buttonMask position:(CGPoint)pos
{
    if (![_socket isConnected]) {
        return;
    }
    
    rfbPointerEventMsg message;
    message.type = rfbPointerEvent;
    message.buttonMask = buttonMask;
    message.x = (CARD16)pos.x;
    message.y = (CARD16)pos.y;
    
    message.x = htons(message.x);
    message.y = htons(message.y);
    
    [_socket writeData:[NSData dataWithBytes:&message length:sz_rfbPointerEventMsg]
           withTimeout:SOCKET_WRITE_TIMEOUT
                   tag:0];
}

- (void)sendKeyEvent:(CARD32)key downflag:(BOOL)down
{
    if (![_socket isConnected]) {
        return;
    }
    
    rfbKeyEventMsg message;
    message.type = rfbKeyEvent;
    message.down = down ? 1 : 0;
    message.key = htonl(key);
    
    [_socket writeData:[NSData dataWithBytes:&message length:sz_rfbKeyEventMsg]
           withTimeout:SOCKET_WRITE_TIMEOUT
                   tag:0];
}

#pragma -
#pragma mark - Server messages
- (void)recvData:(NSUInteger)length
{
//    DLogInfo(@"read data: length=%d", length);
    if (length == 0) {
        [_socket readDataWithTimeout:-1.0 tag:0];
    } else {
        [_socket readDataToLength:length withTimeout:-1.0 tag:0];
    }
}


#pragma -
#pragma mark GCDAsyncSocketDelegate methods

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    DLogInfo(@"connected to %@:%d", host, port);
    
    [_socket readDataWithTimeout:-1.0 tag:0];
    [handler start:self];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    if (!handler) {
        DLogError(@"no handler!");
        return;
    }
    
    [_recvBuf appendData:data];
    
    DLogInfo(@"\nreceived=%d, buffered=%d", data.length, _recvBuf.length);
    
    NSUInteger bytesDone = 0;
    NSUInteger bytesLeft = _recvBuf.length;
    NSUInteger ret = 0;
    
    while (bytesLeft > 0) {
        
        ret = [handler processMessage:[_recvBuf subdataWithRange:NSMakeRange(bytesDone, bytesLeft)] from:self];
        DLogInfo(@"\nbytes processed =%d, bytesDone=%d, bytesLeft=%d", ret, bytesDone, bytesLeft);
        if (ret > 0) {
            bytesDone += ret;
            bytesLeft -= ret;
        } else if (ret == 0){
            break;
        }
    }
    
    if (bytesDone > 0) {
        [_recvBuf replaceBytesInRange:NSMakeRange(0, bytesDone) withBytes:NULL length:0];
    }
    
    [_socket readDataWithTimeout:-1.0 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    // do nothing
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    NSAssert(delegate, @"delegate must be set");
    
    // cleanup the resources
    [[RFBDecoderStore sharedInstance] removeAllDecoders];
    
    [delegate connection:self didCloseWithError:err];
}

@end
