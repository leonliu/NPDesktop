//
//  QualityLevelPseudoDecoder.h
//  NPDesktop
//
//  Created by leon@github on 4/3/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RFBDecoder.h"

/*
 * Pseudo decoder for JPEG quality level
 */

@interface QualityLevelPseudoDecoder : RFBDecoder

- (id)initWithQualityLevel:(int)quality;
- (int)qualityToEncoding:(int)quality;

@end
