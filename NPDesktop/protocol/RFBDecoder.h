//
//  RFBDecoder.h
//  NPDesktop
//
//  Created by leon@github on 3/27/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import "RFBHandler.h"
#import "rfbproto.h"

@interface RFBDecoder : RFBHandler
{
    uint32_t _encoding;
    rfbRectangle _rectangle;
}

@property (readonly) uint32_t encoding;
@property (readonly) BOOL isPseudo;
@property int priority;
@property rfbRectangle rectangle;  // valid for non-pseudo decoder

+ (BOOL)encodingIsPseudo:(int)enc;

@end
