//
//  JpegDecompressor.m
//  NPDesktop
//
//  Created by leon@github on 3/22/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import "JpegDecompressor.h"
#import "jpeglib.h"

@implementation JpegDecompressor


- (id)init
{
    if ((self = [super init])) {
        cinfo.err = jpeg_std_error(&jerr);
        jpeg_create_decompress(&cinfo);
    }
    
    return self;
}

- (void)dealloc
{
    jpeg_destroy_decompress(&cinfo);
}

- (BOOL)decompress:(NSData *)inbuf output:(NSMutableData *)outbuf rect:(rfbRectangle)rect
{
    if ((rect.w == 0) || (rect.h == 0)) {
        DLogError(@"invalid rect!");
        return NO;
    }
    
    if (inbuf.length == 0) {
        DLogError(@"invalid input buffer size");
        return NO;
    }
    
    size_t dstBufSize = rect.w * rect.h * JPEG_BYTES_PER_PIXEL;
    if ((outbuf.length == 0) || (outbuf.length < dstBufSize)) {
        DLogError(@"invalid output buffer size");
        return NO;
    }
    
    UINT8 *src = (UINT8 *)[inbuf bytes];
    UINT8 *dst = (UINT8 *)[outbuf bytes];
    size_t srcBufSsize = [inbuf length];
    
    // initialize data source and read the JPEG header
    jpeg_mem_src(&cinfo, src, srcBufSsize);
    if (jpeg_read_header(&cinfo, TRUE) != JPEG_HEADER_OK) {
        DLogError(@"bad JPEG header");
        return NO;
    }
    
    JDIMENSION jpegW = rect.w;
    JDIMENSION jpegH = rect.h;
    if ((cinfo.image_width != jpegW) || (cinfo.image_height != jpegH)) {
        DLogError(@"incorrect image size");
        jpeg_abort_decompress(&cinfo);
        return NO;
    }
    
    // configure and start decompression
    cinfo.out_color_space = JCS_EXT_RGB;
    
    jpeg_start_decompress(&cinfo);
    if ((cinfo.output_width != jpegW) || (cinfo.output_height != jpegH)) {
        DLogError(@"something's wrong with JPEG library");
        jpeg_abort_decompress(&cinfo);
        return NO;
    }
    
    size_t bytesPerRow = rect.w * JPEG_BYTES_PER_PIXEL;
    
    // consume decompressed data
    while (cinfo.output_scanline < cinfo.output_height) {
        size_t dstBufOffset = cinfo.output_scanline * bytesPerRow;
        JSAMPROW rowPtr[1];
        rowPtr[0] = &dst[dstBufOffset];
        
        if (jpeg_read_scanlines(&cinfo, rowPtr, 1) != 1) {
            DLogError(@"jpeg decompressing error");
            jpeg_abort_decompress(&cinfo);
            return NO;
        }
    }
    
    // cleanup after decompression
    jpeg_finish_decompress(&cinfo);
    
    return YES;
}

@end
