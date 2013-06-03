//
//  RFBFrameBuffer.h
//  NPDesktop
//
//  Created by leon@github on 3/8/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "rfbproto.h"

//
// Only support 32-bit true color.

@interface RFBFrameBuffer : NSObject
{
    CGSize _size;
    NSMutableData *_buffer;
}

@property (readonly) CGSize size;
@property CGFloat scale;  // scale of remote desktop size to client view size
@property rfbPixelFormat pixelFormat;  // pixel format picked by client

- (id)initWithSize:(CGSize)size pixelFormat:(rfbPixelFormat)format;

// draw a rect of data
- (void)drawRect:(CGRect)rect context:(CGContextRef)ctx;

// flush the framebuffer into target rect
- (void)drawFullInRect:(CGRect)rect context:(CGContextRef)ctx;

/*
 * Fill the rectangle with raw pixel data.
 */
- (void)fillRect:(CGRect)rect withData:(NSData *)data;

/*
 * Fill the rectangle with a specified color
 */
- (void)fillRect:(CGRect)rect withColor:(CARD8 *)color;

/* Fill the rectangle with Tight decoded data, no filter applied.
 * If the color depth is 24, and all three color components are 8-bit wide,
 * then one pixel in Tight encoding is always represented by three bytes,
 * where the first byte is red component, the second byte is green component,
 * and the third byte is blue component of the pixel color value.
 */
- (void)fillRect:(CGRect)rect withTightData:(NSData *)data;

/*
 * Fill the rectangle with data by applying the palette filter.
 * The "palette" filter converts true-color pixel data to indexed colors
 * and a palette which can consist of 2..256 colors. If the number of colors
 * is 2, then each pixel is encoded in 1 bit, otherwise 8 bits is used to
 * encode one pixel. 1-bit encoding is performed such way that the most
 * significant bits correspond to the leftmost pixels, and each row of pixels
 * is aligned to the byte boundary.
 */
- (void)fillRect:(CGRect)rect withPalette:(NSData *)palette data:(NSData *)data;

/*
 * Fill the rectangle with pixel data by applying the gradient filter.
 * The "gradient" filter pre-processes pixel data with a simple algorithm
 * which converts each color component to a difference between a "predicted"
 * intensity and the actual intensity. Such a technique does not affect
 * uncompressed data size, but helps to compress photo-like images better.
 * Pseudo-code for converting intensities to differences is the following:
 *
 *   P[i,j] := V[i-1,j] + V[i,j-1] - V[i-1,j-1];
 *   if (P[i,j] < 0) then P[i,j] := 0;
 *   if (P[i,j] > MAX) then P[i,j] := MAX;
 *   D[i,j] := V[i,j] - P[i,j];
 *
 * Here V[i,j] is the intensity of a color component for a pixel at
 * coordinates (i,j). MAX is the maximum value of intensity for a color
 * component.
 */
- (void)fillRect:(CGRect)rect withGradient:(NSData *)data;

/*
 * Copy the pixel data at a position in frame buffer to the destination
 * rectangle.
 */
- (void)copyRect:(CGRect)rect source:(CGPoint)origin;

@end
