//
//  JpegDecompressor.h
//  NPDesktop
//
//  Created by leon@github on 3/22/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "jpeglib.h"
#include "rfbproto.h"

#define JPEG_BYTES_PER_PIXEL    3

@interface JpegDecompressor : NSObject
{
    struct jpeg_decompress_struct cinfo;
    struct jpeg_error_mgr jerr;
}

- (BOOL)decompress:(NSData *)inbuf output:(NSMutableData *)outbuf rect:(rfbRectangle)rect;

@end
