//
//  ZlibInflater.h
//  NPDesktop
//
//  Created by leon@github on 3/25/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <zlib.h>

@interface ZlibInflater : NSObject
{
    z_stream _stream;
    NSMutableData *_outBuf;
    
    size_t _outputSize;  // output size of latest round of inflation
}

@property NSData *input;
@property (readonly) NSData *output;
@property size_t unpackedSize;

- (BOOL)inflate;

@end
