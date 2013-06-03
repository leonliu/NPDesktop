//
//  QualityLevelPseudoDecoder.m
//  NPDesktop
//
//  Created by leon@github on 4/3/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import "QualityLevelPseudoDecoder.h"

@implementation QualityLevelPseudoDecoder

- (id)init
{
    return [self initWithQualityLevel:6];
}

- (id)initWithQualityLevel:(int)quality
{
    if ((self = [super init])) {
        _rectangle.x = 0;
        _rectangle.y = 0;
        _rectangle.w = 0;
        _rectangle.h = 0;
        
        _encoding = [self qualityToEncoding:quality];
    }
    
    return self;
}

- (BOOL)isPseudo
{
    return YES;
}

- (int)qualityToEncoding:(int)quality
{
    switch (quality) {
        case 0:
            return rfbEncodingQualityLevel0;
        case 1:
            return rfbEncodingQualityLevel1;
        case 2:
            return rfbEncodingQualityLevel2;
        case 3:
            return rfbEncodingQualityLevel3;
        case 4:
            return rfbEncodingQualityLevel4;
        case 5:
            return rfbEncodingQualityLevel5;
        case 6:
            return rfbEncodingQualityLevel6;
        case 7:
            return rfbEncodingQualityLevel7;
        case 8:
            return rfbEncodingQualityLevel8;
        case 9:
            return rfbEncodingQualityLevel9;
            
        default:
            DLogError(@"invalid JPEG quality level");
            break;
    }
    
    return -1;
}

@end
