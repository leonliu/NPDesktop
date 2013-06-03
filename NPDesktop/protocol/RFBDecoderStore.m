//
//  RFBDecoderStore.m
//  NPDesktop
//
//  Created by leon@github on 3/27/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import "RFBDecoderStore.h"

static RFBDecoderStore * _instance = nil;

@implementation RFBDecoderStore
@synthesize preferedEncoding;
@synthesize allowCopyRect;

+ (RFBDecoderStore *)sharedInstance
{
    @synchronized(self) {
        
        if (!_instance) {
            _instance = [[self alloc] init];
        }
    }
    
    return _instance;
}

- (id)init
{
    if ((self = [super init])) {
        _decoders = [[NSMutableArray alloc] init];
        preferedEncoding = rfbEncodingTight;
        allowCopyRect = YES;
    }
    
    return self;
}

- (NSArray *)decoderIds
{
    RFBDecoderStore *__weak weakself = self;
    
    [_decoders sortUsingComparator:^NSComparisonResult(RFBDecoder *obj1, RFBDecoder *obj2) {
        
        if (obj1.encoding == weakself.preferedEncoding) {
            return NSOrderedAscending;
        }
        
        if (obj2.encoding == weakself.preferedEncoding) {
            return NSOrderedDescending;
        }
        
        if (obj1.priority > obj2.priority) {
            return NSOrderedAscending;
        }
        
        if (obj1.priority < obj2.priority) {
            return NSOrderedDescending;
        }
        
        return NSOrderedSame;
    }];
    
    int count = [_decoders count];
    NSMutableArray *decIds = [[NSMutableArray alloc] initWithCapacity:count];
    
    for (int i = 0; i < count; i++) {
        RFBDecoder *decoder = [_decoders objectAtIndex:i];
        if ((decoder.encoding != rfbEncodingCopyRect) || allowCopyRect) {
            [decIds addObject:[NSNumber numberWithInt:decoder.encoding]];
        }
    }
    
    if ([decIds count] == 0) {
        [decIds addObject:[NSNumber numberWithInt:rfbEncodingRaw]];
    }
    
    return decIds;
}

- (RFBDecoder *)decoderWithId:(int)decId
{
    RFBDecoder *ret = nil;
    for (RFBDecoder *decoder in _decoders) {
        if (decoder.encoding == decId) {
            ret = decoder;
            break;
        }
    }
    
    return ret;
}

- (BOOL)addDecoder:(RFBDecoder *)decoder withPriority:(int)pr
{
    for (RFBDecoder *iter in _decoders) {
        if (iter.encoding == decoder.encoding) {
            return NO;
        }
    }
    
    decoder.priority = pr;
    [_decoders addObject:decoder];
    return YES;
}

- (BOOL)removeDecoderWithId:(int)decId
{
    int count = [_decoders count];
    for (int i = 0; i < count; i++) {
        RFBDecoder *decoder = [_decoders objectAtIndex:i];
        if (decoder.encoding == decId) {
            [_decoders removeObjectAtIndex:i];
            return YES;
        }
    }
    
    return NO;
}

- (void)removeAllDecoders
{
    [_decoders removeAllObjects];
}

@end
