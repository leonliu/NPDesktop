//
//  RFBFbUpdateHandler.h
//  NPDesktop
//
//  Created by leon@github on 3/12/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RFBHandler.h"

typedef NS_ENUM(NSInteger, FbUpdateHandlerState) {
    FbUpdateHandlerStateIdle,
    FbUpdateHandlerStateWaitMessageHeader,
    FbUpdateHandlerStateWaitRectHeader
};

@interface RFBFbUpdateHandler : RFBHandler
{
    rfbFramebufferUpdateMsg _message;
    CARD16 _numRectReceived;
    
    NSMutableArray *_dirtyRects;
}

@property FbUpdateHandlerState state;

@end
