//
//  RFBFrameBuffer.m
//  NPDesktop
//
//  Created by leon@github on 3/8/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import "RFBFrameBuffer.h"
#import "Utility.h"
#import <Accelerate/Accelerate.h>
#import "JpegDecompressor.h"

@implementation RFBFrameBuffer

@synthesize size = _size;
@synthesize scale;
@synthesize pixelFormat;

- (id)initWithSize:(CGSize)size pixelFormat:(rfbPixelFormat)format
{
    if ((self = [super init])) {
        _size = size;
        scale = 1.0f;
        pixelFormat = format;
        int bytesPerPixel = (pixelFormat.bitsPerPixel + 7) >> 3;
        _buffer = [[NSMutableData alloc] initWithLength:(size.width * size.height * bytesPerPixel)];
    }
    
    return self;
}

- (void)drawRect:(CGRect)rect context:(CGContextRef)ctx
{
//    DLogInfo(@"\nx=%f, y=%f, w=%f, h=%f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    
    int bytesPerPixel = (pixelFormat.bitsPerPixel + 7) >> 3;
    
    CGContextTranslateCTM(ctx, 0, _size.height);
    CGContextScaleCTM(ctx, 1.0, -1.0);
    
    CGRect trect = rect;
    CGFloat w = trect.size.width;
    CGFloat h = trect.size.height;
    if (w > _size.width) {
        w = _size.width;
    }
    
    if (h > _size.height) {
        h = _size.height;
    }
    
    trect = CGRectMake(trect.origin.x, trect.origin.y, w, h);
    trect.origin.y = (CGFloat)_size.height - trect.size.height - trect.origin.y;
    
    // FIXME: rect origin can be negative?
    uint32_t *start = (uint32_t *)_buffer.bytes + (int)(rect.origin.y * _size.width) + (int)rect.origin.x;
    int bytesPerRow = _size.width * bytesPerPixel;
    
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    CGContextRef bmpctx = CGBitmapContextCreate(start, trect.size.width, trect.size.height, 8, bytesPerRow, cs, kCGImageAlphaNoneSkipFirst);
    CGImageRef image = CGBitmapContextCreateImage(bmpctx);
    
    CGContextDrawImage(ctx, trect, image);
    
    CGImageRelease(image);
    CGColorSpaceRelease(cs);
    CGContextRelease(bmpctx);
}

- (void)drawFullInRect:(CGRect)rect context:(CGContextRef)ctx
{
    int bytesPerPixel = (pixelFormat.bitsPerPixel + 7) >> 3;
    
    CGContextTranslateCTM(ctx, 0, _size.height);
    CGContextScaleCTM(ctx, 1.0, -1.0);
    
    // FIXME: rect origin can be negative?
    uint32_t *start = (uint32_t *)_buffer.bytes;
    int bytesPerRow = _size.width * bytesPerPixel;
    
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    CGContextRef bmpctx = CGBitmapContextCreate(start, self.size.width, self.size.height, 8, bytesPerRow, cs, kCGImageAlphaNoneSkipFirst);
    CGImageRef image = CGBitmapContextCreateImage(bmpctx);
    
    CGContextDrawImage(ctx, rect, image);
    
    CGImageRelease(image);
    CGColorSpaceRelease(cs);
    CGContextRelease(bmpctx);
}

- (void)fillRect:(CGRect)rect withData:(NSData *)data
{
    DLogInfo(@"\nrect: x=%f, y=%f, w=%f, h=%f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    
    int bytesPerPixel = (pixelFormat.bitsPerPixel + 7) >> 3;
    int h = (int)rect.size.height;
    int w = (int)rect.size.width;
    
    size_t srcBytesPerRow = w * bytesPerPixel;
    size_t dstBytesPerRow = (CARD32)_size.width * bytesPerPixel;
    
    CARD8 *dst = (CARD8 *)[_buffer bytes] + ((int)rect.origin.y * dstBytesPerRow) + ((int)rect.origin.x * bytesPerPixel);
    CARD8 *src = (CARD8 *)[data bytes];
    
    vImage_Buffer srcbuf = { src, h, w, srcBytesPerRow };
    vImage_Buffer dstbuf = { dst, h, w, dstBytesPerRow };
    
    const uint8_t map[4] = { 3, 2, 1, 0 };
    
    // BGRX to XRGB
    vImagePermuteChannels_ARGB8888(&srcbuf, &dstbuf, map, kvImageNoFlags);
}

- (void)fillRect:(CGRect)rect withColor:(CARD8 *)color
{
    DLogInfo(@"\nrect: x=%f, y=%f, w=%f, h=%f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    
    CGRect clipRect = CGRectIntersection(CGRectMake(0.f, 0.f, _size.width, _size.height), rect);
    
    int bytesPerPixel = (pixelFormat.bitsPerPixel + 7) >> 3;
    int h = (int)clipRect.size.height;
    int w = (int)clipRect.size.width;
    
    size_t bytesPerRow = (CARD32)_size.width * 4;
    CARD8 *dst = (CARD8 *)[_buffer bytes] + (((int)clipRect.origin.y * bytesPerRow)) + ((int)clipRect.origin.x * bytesPerPixel);
    
    vImage_Buffer vbuf = { dst, h, w, bytesPerRow };
    vImageBufferFill_ARGB8888(&vbuf, color, kvImageNoFlags);
}

- (void)fillRect:(CGRect)rect withTightData:(NSData *)data
{
    DLogInfo(@"\nrect: x=%f, y=%f, w=%f, h=%f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    
    int bytesPerPixel = (pixelFormat.bitsPerPixel + 7) >> 3;
    int w = (int)rect.size.width;
    int h = (int)rect.size.height;
    
    size_t srcBytesPerRow = w * JPEG_BYTES_PER_PIXEL;
    size_t dstBytesPerRow = (CARD32)_size.width * bytesPerPixel;
    
    CARD8 *src = (CARD8 *)[data bytes];
    CARD8 *dst = (CARD8 *)[_buffer bytes] + ((int)rect.origin.y * dstBytesPerRow) + ((int)rect.origin.x * bytesPerPixel);
    
    vImage_Buffer srcbuf = { src, h, w, srcBytesPerRow };
    vImage_Buffer dstbuf = { dst, h, w, dstBytesPerRow };
    
    // RGB to ARGB
    vImageConvert_RGB888toARGB8888(&srcbuf, NULL, 0, &dstbuf, NO, kvImageNoFlags);
}

- (void)fillRect:(CGRect)rect withPalette:(NSData *)palette data:(NSData *)data
{
    DLogInfo(@"\nrect: x=%f, y=%f, w=%f, h=%f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    
    int bytesPerPixel = (pixelFormat.bitsPerPixel + 7) >> 3;
    int w = (int)rect.size.width;
    int h = (int)rect.size.height;
    int rsize = w * h;
    int delta = _size.width - w;
    
    CARD32 *plt = (CARD32 *)[palette bytes];
    CARD32 *dst = (CARD32 *)[_buffer bytes] + ((int)rect.origin.y * (int)_size.width) + (int)rect.origin.x;
    CARD8  *src = (CARD8 *)[data bytes];
    
    if (palette.length == 8) { // palette size is 2
        int offset = 8;
        int index = -1;
        
        for (int i = 0; i < rsize; i++) {
            
            if ((offset == 0) || (i % w == 0)) {
                offset = 8;
                index++;
            }
            
            offset--;
            memcpy(dst++, &plt[(src[index] >> offset) & 0x01], bytesPerPixel);
            
            if ((i + 1) % w == 0) {
                dst += delta;
            }
        }
    } else {
        for (int i = 0; i < rsize; i++) {

            memcpy(dst++, &plt[src[i]], bytesPerPixel);
            
            if ((i + 1) % w == 0) {
                dst += delta;
            }
        }
    }
}

- (void)fillRect:(CGRect)rect withGradient:(NSData *)data
{
    DLogInfo(@"\nrect: x=%f, y=%f, w=%f, h=%f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
    
    int bytesPerPixel = (pixelFormat.bitsPerPixel + 7) >> 3;
    int w = (int)rect.size.width;
    int h = (int)rect.size.height;
    
    size_t srcBytesPerRow = w * JPEG_BYTES_PER_PIXEL;
    size_t tmpBytesPerRow = w * bytesPerPixel;
    
    CARD8 *src = (CARD8 *)[data bytes];
    CARD8 *temp = malloc(w * h * bytesPerPixel);
    
    vImage_Buffer srcbuf = { src, h, w, srcBytesPerRow };
    vImage_Buffer tmpbuf = { temp, h, w, tmpBytesPerRow };
    
    // BGR to XRGB
    vImageConvert_RGB888toARGB8888(&srcbuf,
                                   NULL,
                                   0, // alpha
                                   &tmpbuf,
                                   NO,
                                   kvImageNoFlags);
    
    size_t dstBytesPerRow = (CARD32)_size.width * bytesPerPixel;
    CARD8 *dst = (CARD8 *)[_buffer bytes] + ((int)rect.origin.y * dstBytesPerRow) + ((int)rect.origin.x * bytesPerPixel);
    vImage_Buffer dstbuf = { dst, h, w, dstBytesPerRow };
    
    int16_t kernel[9] = { -1, 1, 0, 1, -1, 0, 0, 0, 0 };
    vImage_Error err;
    
    err = vImageRichardsonLucyDeConvolve_ARGB8888(&tmpbuf,
                                                  &dstbuf,
                                                  NULL,
                                                  0,
                                                  0,
                                                  kernel,
                                                  NULL,
                                                  3,
                                                  3,
                                                  0,
                                                  0,
                                                  1,
                                                  0,
                                                  NULL,
                                                  3,
                                                  kvImageNoFlags);
    
    if (err < 0) {
        DLogError(@"failed to fill rect");
    }
    
    free(temp);
}

- (void)copyRect:(CGRect)rect source:(CGPoint)origin
{
    CGRect fbRect = CGRectMake(0, 0, _size.width, _size.height);
    CGRect srcRect = CGRectMake(origin.x, origin.y, rect.size.width, rect.size.height);
    CGRect dstRect = rect;
    
    CGRect srcFbRect = CGRectIntersection(srcRect, fbRect);
    CGRect dstFbRect = CGRectIntersection(dstRect, fbRect);
    
    CGRect commonRect = CGRectIntersection(CGRectMake(0, 0, srcFbRect.size.width, srcFbRect.size.height),
                                           CGRectMake(0, 0, dstFbRect.size.width, dstFbRect.size.height));
    
    srcRect.size.width = commonRect.size.width;
    srcRect.size.height = commonRect.size.height;
    dstRect.size.width = commonRect.size.width;
    dstRect.size.height = commonRect.size.height;
    
    if (CGRectIsEmpty(srcRect)) {
        DLogError(@"source rect is empty");
        return;
    }
    
    if (CGRectIsEmpty(dstRect)) {
        DLogError(@"destination rect is empty");
        return;
    }
    
    int bytesPerPixel = (pixelFormat.bitsPerPixel + 7) >> 3;
    int bytesPerStride = _size.width * bytesPerPixel;
    
    int w = dstRect.size.width;
    int h = dstRect.size.height;
    
    int bytesPerRow = w * bytesPerPixel;
    
    CARD8 *src;
    CARD8 *dst;
    
    if (origin.y > rect.origin.y) {
        // pointers set to first line of the rectangles
        dst = (CARD8 *)[_buffer bytes] + (int)dstRect.origin.y * bytesPerStride + (int)dstRect.origin.x * bytesPerPixel;
        src = (CARD8 *)[_buffer bytes] + (int)srcRect.origin.y * bytesPerStride + (int)srcRect.origin.x * bytesPerPixel;
        
        for (int i = 0; i < h; i++) {
            memcpy(dst, src, bytesPerRow);
            src += bytesPerStride;
            dst += bytesPerStride;
        }
    } else {
        // pointers set to last line of the rectangles
        dst = (CARD8 *)[_buffer bytes] + (int)(CGRectGetMaxY(dstRect) - 1) * bytesPerStride
            + (int)dstRect.origin.x * bytesPerPixel;
        src = (CARD8 *)[_buffer bytes] + (int)(CGRectGetMaxY(srcRect) - 1) * bytesPerStride
            + (int)srcRect.origin.x * bytesPerPixel;
        
        for (int i = h - 1; i >= 0; i--) {
            memmove(dst, src, bytesPerRow);
            src -= bytesPerStride;
            dst -= bytesPerStride;
        }
    }
}

@end
