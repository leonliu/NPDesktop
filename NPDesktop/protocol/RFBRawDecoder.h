//
//  RFBRawDecoder.h
//  NPDesktop
//
//  Created by leon@github on 3/13/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import "RFBDecoder.h"

@interface RFBRawDecoder : RFBDecoder
{
    NSUInteger _bytesReceived;  // for debugging
}

@end
