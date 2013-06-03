//
//  RFBFbUpdateHandler.m
//  NPDesktop
//
//  Created by leon@github on 3/12/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import "RFBFbUpdateHandler.h"
#import "RFBMessageHandler.h"
#import "RFBDecoderStore.h"
#import "RFBRawDecoder.h"
#import "RFBTightDecoder.h"
#import "Utility.h"

@interface RFBFbUpdateHandler()

- (NSUInteger)processMessageHeader:(NSData *)data from:(RFBConnection *)connection;
- (NSUInteger)processRectHeader:(NSData *)data from:(RFBConnection *)connection;

- (void)complete:(RFBConnection *)connection;

@end

@implementation RFBFbUpdateHandler
@synthesize state;

- (id)initWithParent:(RFBHandler *)aParent
{
    if ((self = [super initWithParent:aParent])) {
        
        _message.type = rfbFramebufferUpdate;
        _dirtyRects = [[NSMutableArray alloc] init];
        state = FbUpdateHandlerStateIdle;
    }
    
    return self;
}

- (NSUInteger)processMessage:(NSData *)data from:(RFBConnection *)connection
{
    if (data.length < self.nbytesWaiting) {
        DLogInfo(@"\ndata length=%d, bytes wanted=%ld", data.length, self.nbytesWaiting);
        return 0;
    }
    
    NSUInteger ret = 0;
    NSData *theData = [data subdataWithRange:NSMakeRange(0, self.nbytesWaiting)];
    
    switch (state) {
        case FbUpdateHandlerStateWaitMessageHeader:
            ret = [self processMessageHeader:theData from:connection];
            break;
        case FbUpdateHandlerStateWaitRectHeader:
            ret = [self processRectHeader:theData from:connection];
            break;
            
        default:
            DLogError(@"unknown state!");
            break;
    }
    
    return ret;
}

- (BOOL)start:(RFBConnection *)connection
{
    _numRectReceived = 0;
    
    // message type has already been read in RFBMessageTypeHandler
    self.nbytesWaiting = sz_rfbFramebufferUpdateMsg - sizeof(CARD8);
    self.state = FbUpdateHandlerStateWaitMessageHeader;
    
    [connection setHandler:self];
    
    return YES;
}

- (void)child:(RFBHandler *)handler finishedJob:(NSDictionary *)job onConnection:(RFBConnection *)connection
{
    NSValue *value = [job objectForKey:RFBHandleRectKey];
    if (value) {
        _numRectReceived++;
        
        // Uncomment this line if you want to update the screen rect by rect. You really
        // do not want that, I am sure.
//        [connection.delegate connection:connection shouldInvalidateRect:[value CGRectValue]];
        
        if (_numRectReceived == _message.nRects) {
            [self complete:connection];
        } else {
            self.nbytesWaiting = sz_rfbFramebufferUpdateRectHeader;
            self.state = FbUpdateHandlerStateWaitRectHeader;
            
            [connection setHandler:self];
        }
    }
}

#pragma mark - private methods
#
- (NSUInteger)processMessageHeader:(NSData *)data from:(RFBConnection *)connection
{
    NSUInteger ret = self.nbytesWaiting;
    
    CARD8 *pos = (CARD8 *)&_message + sizeof(_message.type);
    [data getBytes:pos length:self.nbytesWaiting];
    
    _message.nRects = ntohs(_message.nRects);
    
    DLogInfo(@"\nFramebufferUpdate: nRects=%d", _message.nRects);
    
    if (connection.delegate) {
        [connection.delegate connection:connection didReceiveFramebufferUpdate:_message];
    }
    
    self.nbytesWaiting = sz_rfbFramebufferUpdateRectHeader;
    self.state = FbUpdateHandlerStateWaitRectHeader;
    
    return ret;
}

- (NSUInteger)processRectHeader:(NSData *)data from:(RFBConnection *)connection
{
    NSUInteger ret = self.nbytesWaiting;
    
    rfbFramebufferUpdateRectHeader rectHdr;
    
    [data getBytes:&rectHdr length:sz_rfbFramebufferUpdateRectHeader];
    rectHdr.r.x = ntohs(rectHdr.r.x);
    rectHdr.r.y = ntohs(rectHdr.r.y);
    rectHdr.r.w = ntohs(rectHdr.r.w);
    rectHdr.r.h = ntohs(rectHdr.r.h);
    rectHdr.encoding = ntohl(rectHdr.encoding);
    
    DLogInfo(@"%@", [Utility rfbRectHeaderToString:rectHdr]);
    
    if (rectHdr.encoding == rfbEncodingLastRect) {
        [self complete:connection];        
    } else if (![RFBDecoder encodingIsPseudo:rectHdr.encoding]) {
        RFBDecoder *decoder = [[RFBDecoderStore sharedInstance] decoderWithId:rectHdr.encoding];
        if (decoder) {
            CGRect rect = CGRectMake(rectHdr.r.x, rectHdr.r.y, rectHdr.r.w, rectHdr.r.h);
            [_dirtyRects addObject:[NSValue valueWithCGRect:rect]];
            
            [decoder setRectangle:rectHdr.r];
            [decoder setParent:self];
            [decoder start:connection];            
        } else {
            DLogError(@"can not find decoder");
        }
    } else {
        DLogInfo(@"pseudo encoding");
    }
    
    return ret;
}

- (void)complete:(RFBConnection *)connection
{
    if (connection.delegate) {
    
        // now we have all the data ready, update the screen all in once.        
        [_dirtyRects removeAllObjects];
        [connection.delegate connection:connection didCompleteFramebufferUpdate:_message.nRects];
    }
    
    if (self.parent) {
        [self.parent child:self finishedJob:nil onConnection:connection];
    }
}

@end
