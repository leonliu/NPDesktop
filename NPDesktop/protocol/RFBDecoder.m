//
//  RFBDecoder.m
//  NPDesktop
//
//  Created by leon@github on 3/27/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import "RFBDecoder.h"

@implementation RFBDecoder
@synthesize encoding = _encoding;
@synthesize priority;
@synthesize rectangle = _rectangle;

- (BOOL)isPseudo
{
    return [RFBDecoder encodingIsPseudo:_encoding];
}

+ (BOOL)encodingIsPseudo:(int)enc
{
    switch (enc) {
        case rfbEncodingRaw:
        case rfbEncodingCopyRect:
        case rfbEncodingRRE:
        case rfbEncodingCoRRE:
        case rfbEncodingHextile:
        case rfbEncodingZlib:
        case rfbEncodingTight:
        case rfbEncodingZlibHex:
        case rfbEncodingZRLE:
            return NO;
        case rfbEncodingCompressLevel0:
        case rfbEncodingCompressLevel1:
        case rfbEncodingCompressLevel2:
        case rfbEncodingCompressLevel3:
        case rfbEncodingCompressLevel4:
        case rfbEncodingCompressLevel5:
        case rfbEncodingCompressLevel6:
        case rfbEncodingCompressLevel7:
        case rfbEncodingCompressLevel8:
        case rfbEncodingCompressLevel9:
            
        case rfbEncodingQualityLevel0:
        case rfbEncodingQualityLevel1:
        case rfbEncodingQualityLevel2:
        case rfbEncodingQualityLevel3:
        case rfbEncodingQualityLevel4:
        case rfbEncodingQualityLevel5:
        case rfbEncodingQualityLevel6:
        case rfbEncodingQualityLevel7:
        case rfbEncodingQualityLevel8:
        case rfbEncodingQualityLevel9:
            
        case rfbEncodingXCursor:
        case rfbEncodingRichCursor:
        case rfbEncodingPointerPos:
        case rfbEncodingLastRect:
        case rfbEncodingNewFBSize:
        
            return YES;
        default:
            break;
    }
    
    return YES;
}

@end
