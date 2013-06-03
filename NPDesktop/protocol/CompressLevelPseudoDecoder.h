//
//  CompressLevelPseudoDecoder.h
//  NPDesktop
//
//  Created by leon@github on 4/3/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import "RFBDecoder.h"

/*
 * Pseudo decoder for Compression level
 */

@interface CompressLevelPseudoDecoder : RFBDecoder

- (id)initWithCompressionLevel:(int)compression;
- (int)compressionToEncoding:(int)compression;

@end
