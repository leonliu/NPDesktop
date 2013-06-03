//
//  CompressLevelPseudoDecoder.m
//  NPDesktop
//
//  Created by leon@github on 4/3/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import "CompressLevelPseudoDecoder.h"

@implementation CompressLevelPseudoDecoder

- (id)init
{
    return [self initWithCompressionLevel:6];
}

- (id)initWithCompressionLevel:(int)compression
{
    if ((self = [super init])) {
        _rectangle.x = 0;
        _rectangle.y = 0;
        _rectangle.w = 0;
        _rectangle.h = 0;
        
        _encoding = [self compressionToEncoding:compression];
    }
    
    return self;
}

- (int)compressionToEncoding:(int)compression
{
    switch (compression) {
        case 0:
            return rfbEncodingCompressLevel0;
        case 1:
            return rfbEncodingCompressLevel1;
        case 2:
            return rfbEncodingCompressLevel2;
        case 3:
            return rfbEncodingCompressLevel3;
        case 4:
            return rfbEncodingCompressLevel4;
        case 5:
            return rfbEncodingCompressLevel5;
        case 6:
            return rfbEncodingCompressLevel6;
        case 7:
            return rfbEncodingCompressLevel7;
        case 8:
            return rfbEncodingCompressLevel8;
        case 9:
            return rfbEncodingCompressLevel9;
            
        default:
            break;
    }
    
    return -1;
}

@end
