//
//  RFBDecoderStore.h
//  NPDesktop
//
//  Created by leon@github on 3/27/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RFBDecoder.h"

@interface RFBDecoderStore : NSObject
{
    NSMutableArray *_decoders;
}

@property int preferedEncoding;
@property BOOL allowCopyRect;

+ (RFBDecoderStore *)sharedInstance;

- (NSArray *)decoderIds;
- (RFBDecoder *)decoderWithId:(int)decId;
- (BOOL)addDecoder:(RFBDecoder *)decoder withPriority:(int)pr;
- (BOOL)removeDecoderWithId:(int)decId;
- (void)removeAllDecoders;

@end
