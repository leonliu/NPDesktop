//
//  RFBHandshaker.h
//  NPDesktop
//
//  Created by leon@github on 3/26/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import "RFBHandler.h"

typedef NS_ENUM(NSUInteger, RFBHandshakerState) {
    RFBHandshakerStateIdle,
    RFBHandshakerStateWaitProtocolVersion,
    RFBHandshakerStateWaitSecurityTypeNumber,
    RFBHandshakerStateWaitSecurityTypeList,
    RFBHandshakerStateWaitSecurityType,  // used for version 3.3
    RFBHandshakerStateWaitReasonLength,
    RFBHandshakerStateWaitReasonString,
    RFBHandshakerStateWaitSecurityResult,
    RFBHandshakerStateWaitChallenge
};

@interface RFBHandshaker : RFBHandler
{
    int _securityTypeNumber;
    CARD32 _reasonStrLen;
}

@property RFBHandshakerState state;

@end
