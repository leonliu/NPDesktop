//
//  RFBCopyRectDecoder.m
//  NPDesktop
//
//  Created by leon@github on 4/3/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import "RFBCopyRectDecoder.h"

@implementation RFBCopyRectDecoder

- (id)init
{
    if ((self = [super initWithParent:nil])) {
        _encoding = rfbEncodingCopyRect;
    }
    
    return self;
}

- (BOOL)start:(RFBConnection *)connection
{
    if ((_rectangle.w == 0) || (_rectangle.h == 0)) {
        DLogError(@"Rect size is zero.");
        return NO;
    }
    
    self.nbytesWaiting = sz_rfbCopyRect;
    [connection setHandler:self];
    
    return YES;
}


- (NSUInteger)processMessage:(NSData *)data from:(RFBConnection *)connection
{
    if (data.length < self.nbytesWaiting) {
        DLogInfo(@"\ndata length=%d, bytes wanted=%ld", data.length, self.nbytesWaiting);
        return 0;
    }
    
    NSUInteger ret = self.nbytesWaiting;
    
    rfbCopyRect origin;
    [data getBytes:&origin length:sz_rfbCopyRect];
    origin.srcX = ntohs(origin.srcX);
    origin.srcY = ntohs(origin.srcY);
    
    if (connection.delegate) {
        [connection.delegate connection:connection didReceiveCopyRect:origin forRect:_rectangle];
    }
    
    DLogInfo(@"received data for rect:\n x=%d, y=%d, w=%d, h=%d", _rectangle.x, _rectangle.y, _rectangle.w, _rectangle.h);
    
    if (self.parent) {
        CGRect aRect = CGRectMake(_rectangle.x, _rectangle.y, _rectangle.w, _rectangle.h);
        NSDictionary *job = [NSDictionary dictionaryWithObject:[NSValue valueWithCGRect:aRect] forKey:RFBHandleRectKey];
        [self.parent child:self finishedJob:job onConnection:connection];
    }

    return ret;
}

@end
