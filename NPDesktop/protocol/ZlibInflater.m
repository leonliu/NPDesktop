//
//  ZlibInflater.m
//  NPDesktop
//
//  Created by leon@github on 3/25/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import "ZlibInflater.h"

@implementation ZlibInflater

@synthesize input;
@synthesize unpackedSize;

- (id)init
{
    if ((self = [super init])) {
        input = nil;
        _outBuf = [[NSMutableData alloc] init];
        unpackedSize = 0;
        _outputSize = 0;
        
        _stream.zalloc = Z_NULL;
        _stream.zfree = Z_NULL;
        
        inflateInit(&_stream);
        
        _stream.next_in = 0;
        _stream.avail_in = 0;
        _stream.next_out = 0;
        _stream.avail_out = 0;
    }
    
    return self;
}

- (void)dealloc
{
    inflateEnd(&_stream);
}

- (NSData *)output
{
    return [_outBuf subdataWithRange:NSMakeRange(0, _outputSize)];
}

- (BOOL)inflate
{
    BOOL ret = YES;
    
    size_t availOut = unpackedSize + unpackedSize / 100 + 1024;
    size_t prevTotalOut = _stream.total_out;
    
    unsigned int constrainedVal = (unsigned int)availOut;
    NSAssert(constrainedVal == availOut, @"value overflow");
    
    constrainedVal = (unsigned int)prevTotalOut;
    NSAssert(constrainedVal == prevTotalOut, @"value overflow");
    
    [_outBuf setLength:availOut];
    
    _stream.next_in = (Bytef *)[input bytes];
    _stream.avail_in = (unsigned int)[input length];
    _stream.next_out = (Bytef *)[_outBuf bytes];
    _stream.avail_out = (unsigned int)availOut;
    
    int status = inflate(&_stream, Z_SYNC_FLUSH);
    if (status == Z_STREAM_END) {
        DLogError(@"Zlib stream end");
        ret = NO;  // FIXME: is this an error???
    } else if (status == Z_NEED_DICT) {
        DLogError(@"Zlib needs dictionary");
        ret = NO;
    } else if (status == Z_STREAM_ERROR) {
        DLogError(@"Zlib stream error");
        ret = NO;
    } else if (status == Z_MEM_ERROR) {
        DLogError(@"Zlib memory error");
        ret = NO;
    } else if (status == Z_DATA_ERROR) {
        DLogError(@"Zlib data error");
        ret = NO;
    }
    
    if (_stream.avail_in != 0) {
        DLogError(@"Zlib no enough buffer for decompression");
        ret = NO;
    }
    
    _outputSize = _stream.total_out - prevTotalOut;
    return ret;
}

@end
