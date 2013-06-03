//
//  RFBInitializer.h
//  NPDesktop
//
//  Created by leon@github on 3/26/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import "RFBHandler.h"

typedef NS_ENUM(NSUInteger, RFBInitializerState) {
    RFBInitializerStateIdle,
    RFBInitializerStateWaitServerInit,
    RFBInitializerStateWaitDesktopName
};

@interface RFBInitializer : RFBHandler
{
    CARD32 _desktopNameLen;
}

@property RFBInitializerState state;

@end
