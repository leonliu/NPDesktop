//
//  RFBTightDecoder.h
//  NPDesktop
//
//  Created by leon@github on 3/22/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import "RFBDecoder.h"
#import "JpegDecompressor.h"

typedef NS_ENUM(NSUInteger, RFBTightDecoderState) {
    RFBTightDecoderStateIdle,
    RFBTightDecoderStateWaitControlByte,
    RFBTightDecoderStateWaitFillPixel,
    RFBTightDecoderStateWaitBasicFilterId,
    RFBTightDecoderStateWaitBasicPaletteColorNum,
    RFBTightDecoderStateWaitBasicPaletteData,
    RFBTightDecoderStateWaitZlibDataSize,
    RFBTightDecoderStateWaitZlibData,
    RFBTightDecoderStateWaitRawData,
    RFBTightDecoderStateWaitJpegDataSize,
    RFBTightDecoderStateWaitJpegData
};

@interface RFBTightDecoder : RFBDecoder
{
    CARD8 _control;
    CARD8 _filter;
    
    int _nbytesForDataSize;
    int _dataSize;
    
    NSMutableArray *_inflaters;
    
    int _paletteSize;
    NSMutableData *_palette;
    JpegDecompressor *_jpeg;
}

@property RFBTightDecoderState state;

@end
