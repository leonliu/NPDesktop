//
//  RFBRawDecoder.m
//  NPDesktop
//
//  Created by leon@github on 3/13/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import "RFBRawDecoder.h"

static const size_t kAreaOfOneSlice = 1024 * 64;

@implementation RFBRawDecoder

- (id)init
{
    if ((self = [super initWithParent:nil])) {
        _bytesReceived = 0;
        _encoding = rfbEncodingRaw;
    }
    
    return self;
}

- (BOOL)start:(RFBConnection *)connection
{
    if ((_rectangle.w == 0) || (_rectangle.h == 0)) {
        DLogError(@"Rect size is zero.");
        return NO;
    }
    
    [connection setHandler:self];
    
    return YES;
}

- (NSUInteger)processMessage:(NSData *)data from:(RFBConnection *)connection
{
    NSUInteger bytesWanted = _rectangle.w * _rectangle.h * connection.bytesPerPixel;
    
    if (data.length < bytesWanted) {
        return 0;
    }
    
    RFBRect *rect = [[RFBRect alloc] initWithData:data rect:_rectangle];
    rect.encoding = rfbEncodingRaw;
    
    if (connection.delegate) {
        [connection.delegate connection:connection didReceiveDataForRect:rect];
    }
    
    DLogInfo(@"received data for rect:\n x=%d, y=%d, w=%d, h=%d", _rectangle.x, _rectangle.y, _rectangle.w, _rectangle.h);
    
    if (self.parent) {
        CGRect aRect = CGRectMake(_rectangle.x, _rectangle.y, _rectangle.w, _rectangle.h);
        NSDictionary *job = [NSDictionary dictionaryWithObject:[NSValue valueWithCGRect:aRect] forKey:RFBHandleRectKey];
        [self.parent child:self finishedJob:job onConnection:connection];
    }
    
    return bytesWanted;
}

@end
