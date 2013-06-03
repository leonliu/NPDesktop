//
//  RFBTightDecoder.m
//  NPDesktop
//
//  Created by leon@github on 3/22/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import "RFBTightDecoder.h"
#import "ZlibInflater.h"
#import "Utility.h"

static const int kRFBFilterIdMask = 0x40;
static const int kRFBStreamIdMask = 0x30;
static const int kRFBDecodersNum  = 4;
static const int kRFBMinSizeToCompress  = 12;
static const int kRFBMaxPaletteColors   = 256;
static const int kRFBTightBytesPerPixel = 3;

@interface RFBTightDecoder()

- (void)resetInflaters:(CARD8)control;

- (NSUInteger)processControlByte:(NSData *)data from:(RFBConnection *)connection;
- (NSUInteger)processFilterByte:(NSData *)data from:(RFBConnection *)connection;
- (NSUInteger)processFillPixelColor:(NSData *)data from:(RFBConnection *)connection;
- (NSUInteger)processPixelDataSize:(NSData *)data from:(RFBConnection *)connection;
- (NSUInteger)processZlibData:(NSData *)data from:(RFBConnection *)connection;
- (NSUInteger)processJpegData:(NSData *)data from:(RFBConnection *)connection;
- (NSUInteger)processRawData:(NSData *)data from:(RFBConnection *)connection;
- (NSUInteger)processPaletteColorNumber:(NSData *)data from:(RFBConnection *)connection;
- (NSUInteger)processPaletteData:(NSData *)data from:(RFBConnection *)connection;

- (NSString *)stateToString:(RFBTightDecoderState)aState;

@end

@implementation RFBTightDecoder
@synthesize state;

- (id)init
{
    if ((self = [super initWithParent:nil])) {
        
        _encoding = rfbEncodingTight;
    
        _control = 0;
        _filter = rfbTightFilterCopy;
        _nbytesForDataSize = 0;
        _dataSize = 0;
        
        _inflaters = [[NSMutableArray alloc] initWithCapacity:kRFBDecodersNum];
        for (int i = 0; i < kRFBDecodersNum; i++) {
            ZlibInflater *inflater = [[ZlibInflater alloc] init];
            [_inflaters addObject:inflater];
        }
        
        _palette = [[NSMutableData alloc] init];
        
        _jpeg = [[JpegDecompressor alloc] init];
        state = RFBTightDecoderStateIdle;
    }
    
    return self;
}

- (BOOL)start:(RFBConnection *)connection
{
    self.nbytesWaiting = sizeof(CARD8);
    self.state = RFBTightDecoderStateWaitControlByte;
    
    [connection setHandler:self];
    
    return YES;
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
        case RFBTightDecoderStateWaitControlByte:
        {            
            ret = [self processControlByte:theData from:connection];
        }
            break;
        case RFBTightDecoderStateWaitFillPixel:
        {
            ret = [self processFillPixelColor:theData from:connection];
        }
            break;
        case RFBTightDecoderStateWaitBasicFilterId:
        {            
            ret = [self processFilterByte:theData from:connection];
        }
            break;
        case RFBTightDecoderStateWaitBasicPaletteColorNum:
        {            
            ret = [self processPaletteColorNumber:theData from:connection];
        }
            break;
        case RFBTightDecoderStateWaitBasicPaletteData:
        {
            ret = [self processPaletteData:theData from:connection];
        }
            break;
        case RFBTightDecoderStateWaitZlibDataSize:
        case RFBTightDecoderStateWaitJpegDataSize:
        {            
            ret = [self processPixelDataSize:theData from:connection];
        }
            break;
        case RFBTightDecoderStateWaitZlibData:
        {
            ret = [self processZlibData:theData from:connection];
        }
            break;
        case RFBTightDecoderStateWaitRawData:
        {
            ret = [self processRawData:theData from:connection];
        }
            break;
        case RFBTightDecoderStateWaitJpegData:
        {
            ret = [self processJpegData:theData from:connection];
        }
            break;
            
        default:
            DLogError(@"invalid state: %@", [self stateToString:state]);
            break;
    }

    return ret;
}

- (void)resetInflaters:(CARD8)control
{
    for (int i = 0; i < kRFBDecodersNum; i++) {
        if (control & (0x01 << i)) {
            ZlibInflater *inf = [[ZlibInflater alloc] init];
            [_inflaters replaceObjectAtIndex:i withObject:inf];
        }
    }
}

- (NSUInteger)processControlByte:(NSData *)data from:(RFBConnection *)connection
{
    NSUInteger ret = self.nbytesWaiting;
    
    _control = *((CARD8 *)[data bytes]);
    CARD8 compression = (_control >> 4) & 0x0f;
    
    if (compression > rfbTightMaxSubencoding) {
        DLogError(@"invalid subencoding of Tight-encoder");
        return self.nbytesWaiting;
    }
    
    DLogInfo(@"\ncompression: %@", [Utility rfbTightSubEncodingToString:compression]);
    
    // reset Zlib inflaters according to the control byte
    [self resetInflaters:_control];
    
    if (compression == rfbTightFill) {
        self.nbytesWaiting = kRFBTightBytesPerPixel;
        self.state = RFBTightDecoderStateWaitFillPixel;
    } else if (compression == rfbTightJpeg) {
        self.nbytesWaiting = sizeof(CARD8);
        self.state = RFBTightDecoderStateWaitJpegDataSize;
    } else {
        if ((_control & 0x40) != 0) {
            // has filter, read the filter ID
            self.nbytesWaiting = sizeof(CARD8);
            self.state = RFBTightDecoderStateWaitBasicFilterId;
        } else {
            // no filter, same as "copy" filter
            CARD8 filter = rfbTightFilterCopy;
            [self processFilterByte:[NSData dataWithBytes:&filter length:sizeof(CARD8)] from:connection];
        }
    }
    
    return ret;
}

- (NSUInteger)processFilterByte:(NSData *)data from:(RFBConnection *)connection
{
    NSUInteger ret = self.nbytesWaiting;
    
    _filter = *((CARD8 *)[data bytes]);
    size_t bytesPerRect = _rectangle.w * _rectangle.h * kRFBTightBytesPerPixel;
    
    DLogInfo(@"\nfilter: %@", [Utility rfbTightFilterToString:_filter]);
    
    switch (_filter) {
        case rfbTightFilterCopy:
        {
            if (bytesPerRect < kRFBMinSizeToCompress) {
                self.nbytesWaiting = bytesPerRect;
                self.state = RFBTightDecoderStateWaitRawData;
            } else {
                self.nbytesWaiting = sizeof(CARD8);
                self.state = RFBTightDecoderStateWaitZlibDataSize;
            }
        }
            break;
        case rfbTightFilterPalette:
        {
            // read palette color number
            self.nbytesWaiting = sizeof(CARD8);
            self.state = RFBTightDecoderStateWaitBasicPaletteColorNum;
        }
            break;
        case rfbTightFilterGradient:
        {
            if (bytesPerRect < kRFBMinSizeToCompress) {
                self.nbytesWaiting = bytesPerRect;
                self.state = RFBTightDecoderStateWaitRawData;
            } else {
                self.nbytesWaiting = sizeof(CARD8);
                self.state = RFBTightDecoderStateWaitZlibDataSize;
            }
        }
            break;
            
        default:
            break;
    }
    
    return ret;
}

- (NSUInteger)processFillPixelColor:(NSData *)data from:(RFBConnection *)connection
{
    NSUInteger ret = self.nbytesWaiting;
    
    CARD8 buffer[4];
    CARD8 *bytes = (CARD8 *)[data bytes];
    
    // RGB to XRGB
    // If the color depth is 24, and all three color components are 8-bit wide,
    // then one pixel in Tight encoding is always represented by three bytes,
    // where the first byte is red component, the second byte is green component
    // , and the third byte is blue component of the pixel color value. This
    // applies to colors in palettes as well.
    
    buffer[0] = 0;
    buffer[1] = bytes[0];
    buffer[2] = bytes[1];
    buffer[3] = bytes[2];
    
    NSData *cdata = [NSData dataWithBytes:buffer length:4];
    if (connection.delegate) {
        [connection.delegate connection:connection didReceiveFillColor:cdata forRect:_rectangle];
    }
    
    if (self.parent) {
        CGRect aRect = CGRectMake(_rectangle.x, _rectangle.y, _rectangle.w, _rectangle.h);
        NSDictionary *job = [NSDictionary dictionaryWithObject:[NSValue valueWithCGRect:aRect] forKey:RFBHandleRectKey];
        [self.parent child:self finishedJob:job onConnection:connection];
    }
    
    return ret;
}

- (NSUInteger)processPixelDataSize:(NSData *)data from:(RFBConnection *)connection
{
    NSUInteger ret = self.nbytesWaiting;
    
    CARD32 byte = *((CARD8 *)[data bytes]);
    
    BOOL complete = YES;
    
    if (_nbytesForDataSize == 0) {
        _dataSize = byte & 0x7f;
        if ((byte & 0x80) != 0) {
            _nbytesForDataSize += 1;
            complete = NO;
            self.nbytesWaiting = sizeof(CARD8);
        }
    } else if (_nbytesForDataSize == 1) {
        _dataSize += (byte & 0x7f) << 7;
        if ((byte & 0x80) != 0) {
            _nbytesForDataSize += 1;
            complete = NO;
            self.nbytesWaiting = sizeof(CARD8);
        }
    } else {
        _dataSize += byte << 14;
    }
    
    if (complete) {
        DLogInfo(@"data size: %d", _dataSize);

        self.nbytesWaiting = _dataSize;
        
        if (state == RFBTightDecoderStateWaitZlibDataSize) {
            self.state = RFBTightDecoderStateWaitZlibData;
        } else if (state == RFBTightDecoderStateWaitJpegDataSize) {
            self.state = RFBTightDecoderStateWaitJpegData;
        } else {
            DLogError(@"invalid state");
        }
        
        _nbytesForDataSize = 0;
        _dataSize = 0;
    }
    
    return ret;
}

- (NSUInteger)processZlibData:(NSData *)data from:(RFBConnection *)connection
{
    NSUInteger ret = self.nbytesWaiting;
    
    int infIdx = (_control & kRFBStreamIdMask) >> 4;
    ZlibInflater *inf = [_inflaters objectAtIndex:infIdx];
    
    DLogInfo(@"\ninflater: address=%@, index=%d", inf, infIdx);
    
    [inf setInput:data];
    [inf setUnpackedSize:(_rectangle.w * _rectangle.h * kRFBTightBytesPerPixel)];
    
    if (![inf inflate]) {
        DLogError(@"failed to inflate Zlib data");
        return ret;
    }
    
    NSData *output = [inf output];
    RFBRect *rect = [[RFBRect alloc] initWithData:output rect:_rectangle];
    rect.encoding = rfbEncodingTight;
    rect.filter = _filter;
    
    if (connection.delegate) {
        if (_filter == rfbTightFilterCopy) {
            [connection.delegate connection:connection didReceiveDataForRect:rect];
        } else if (_filter == rfbTightFilterPalette) {
            [connection.delegate connection:connection didReceiveDataForRect:rect withPalette:_palette];
        } else if (_filter == rfbTightFilterGradient) {
            [connection.delegate connection:connection didReceiveDataForRect:rect];
        } else {
            DLogError(@"unknown filter type");
        }
    }
    
    if (self.parent) {
        CGRect aRect = CGRectMake(_rectangle.x, _rectangle.y, _rectangle.w, _rectangle.h);
        NSDictionary *job = [NSDictionary dictionaryWithObject:[NSValue valueWithCGRect:aRect] forKey:RFBHandleRectKey];
        [self.parent child:self finishedJob:job onConnection:connection];
    }
    
    return ret;
}

- (NSUInteger)processJpegData:(NSData *)data from:(RFBConnection *)connection
{
    NSUInteger ret = self.nbytesWaiting;
    
    NSMutableData *output = [[NSMutableData alloc] initWithLength:_rectangle.w * _rectangle.h * JPEG_BYTES_PER_PIXEL];
    if ([_jpeg decompress:data output:output rect:_rectangle]) {
        RFBRect *rect = [[RFBRect alloc] initWithData:output rect:_rectangle];
        rect.encoding = rfbEncodingTight;
        rect.filter = rfbTightFilterCopy;
        
        if (connection.delegate) {
            [connection.delegate connection:connection didReceiveDataForRect:rect];
        }
    }
    
    if (self.parent) {
        CGRect aRect = CGRectMake(_rectangle.x, _rectangle.y, _rectangle.w, _rectangle.h);
        NSDictionary *job = [NSDictionary dictionaryWithObject:[NSValue valueWithCGRect:aRect] forKey:RFBHandleRectKey];
        [self.parent child:self finishedJob:job onConnection:connection];
    }
    
    return ret;
}

- (NSUInteger)processRawData:(NSData *)data from:(RFBConnection *)connection
{
    NSUInteger ret = self.nbytesWaiting;
    
    RFBRect *rect = [[RFBRect alloc] initWithData:data rect:_rectangle];
    rect.encoding = rfbEncodingTight;
    rect.filter = rfbTightFilterCopy;
    
    if (connection.delegate) {
        [connection.delegate connection:connection didReceiveDataForRect:rect];
    }
    
    if (self.parent) {
        CGRect aRect = CGRectMake(_rectangle.x, _rectangle.y, _rectangle.w, _rectangle.h);
        NSDictionary *job = [NSDictionary dictionaryWithObject:[NSValue valueWithCGRect:aRect] forKey:RFBHandleRectKey];
        [self.parent child:self finishedJob:job onConnection:connection];
    }
    
    return ret;
}

- (NSUInteger)processPaletteColorNumber:(NSData *)data from:(RFBConnection *)connection
{
    NSUInteger ret = self.nbytesWaiting;
    
    _paletteSize = *((CARD8 *)[data bytes]) + 1;
    NSUInteger size = _paletteSize * kRFBTightBytesPerPixel;
    
    // Note, color in local palette uses 4 bytes per pixel
    [_palette setLength:(_paletteSize * sizeof(CARD32))];
    
    self.nbytesWaiting = size;
    self.state = RFBTightDecoderStateWaitBasicPaletteData;
    
    return ret;
}

- (NSUInteger)processPaletteData:(NSData *)data from:(RFBConnection *)connection
{
    NSUInteger ret = self.nbytesWaiting;
    
    CARD32 *pt = (CARD32 *)[_palette bytes];
    CARD8 *byte = (CARD8 *)[data bytes];
    CARD8 buffer[4];
    
    for (int i = 0; i < _paletteSize; i++) {
        buffer[0] = 0;
        buffer[1] = *byte++;
        buffer[2] = *byte++;
        buffer[3] = *byte++;
        
        memcpy(pt++, buffer, 4);
    }
    
    size_t bytesPerRect = _rectangle.w * _rectangle.h;
    if (_paletteSize == 2) {
        bytesPerRect = ((_rectangle.w + 7) / 8) * _rectangle.h;
    }
    
    if (bytesPerRect < kRFBMinSizeToCompress) {
        self.nbytesWaiting = bytesPerRect;
        self.state = RFBTightDecoderStateWaitRawData;
    } else {
        self.nbytesWaiting = sizeof(CARD8);
        self.state = RFBTightDecoderStateWaitZlibDataSize;
    }
    
    return ret;
}

- (NSString *)stateToString:(RFBTightDecoderState)aState
{
    NSString *ret = @"unknown state";
    
    switch (aState) {
        case RFBTightDecoderStateIdle:
            ret = @"StateIdle";
            break;
        case RFBTightDecoderStateWaitControlByte:
            ret = @"StateWaitControlByte";
            break;
        case RFBTightDecoderStateWaitFillPixel:
            ret = @"StateWaitFillPixel";
            break;
        case RFBTightDecoderStateWaitBasicFilterId:
            ret = @"StateWaitFilterId";
            break;
        case RFBTightDecoderStateWaitBasicPaletteColorNum:
            ret = @"StateWaitPaletteColorNum";
            break;
        case RFBTightDecoderStateWaitBasicPaletteData:
            ret = @"StateWaitPaletteData";
            break;
        case RFBTightDecoderStateWaitZlibDataSize:
            ret = @"StateWaitZlibDataSize";
            break;
        case RFBTightDecoderStateWaitZlibData:
            ret = @"StateWaitZlibData";
            break;
        case RFBTightDecoderStateWaitRawData:
            ret = @"StateWaitRawData";
            break;
        case RFBTightDecoderStateWaitJpegDataSize:
            ret = @"StateWaitJpegDataSize";
            break;
        case RFBTightDecoderStateWaitJpegData:
            ret = @"StateWaitJpegData";
            break;
            
        default:
            break;
    }
    
    return ret;
}

@end
