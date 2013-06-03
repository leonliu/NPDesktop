//
//  RFBMessageHandler.m
//  NPDesktop
//
//  Created by leon@github on 3/12/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import "RFBMessageHandler.h"
#import "RFBFbUpdateHandler.h"
#import "Utility.h"

@implementation RFBMessageHandler

- (BOOL)start:(RFBConnection *)connection
{
    // read message type
    self.nbytesWaiting = sizeof(CARD8);
    
    [connection setHandler:self];
    
    return YES;
}

- (NSUInteger)processMessage:(NSData *)data from:(RFBConnection *)connection
{
    if (data.length < self.nbytesWaiting) {
        DLogInfo(@"\ndata length=%d, bytes wanted=%ld", data.length, self.nbytesWaiting);
        return 0;
    }

    NSUInteger ret = self.nbytesWaiting;
    
    CARD8 msgType = *((CARD8 *)[data bytes]);
    
    DLogInfo(@"received msg: %@", [Utility rfbServerMsgTypeToString:msgType]);
    
    switch (msgType) {
        case rfbFramebufferUpdate:
        {
            RFBFbUpdateHandler *handler = [[RFBFbUpdateHandler alloc] initWithParent:self];
            [handler start:connection];
        }
            break;
        case rfbSetColourMapEntries:
            break;
        case rfbBell:
            break;
        case rfbServerCutText:
            break;
        case rfbFileListData:
            break;
        case rfbFileDownloadData:
            break;
        case rfbFileUploadCancel:
            break;
        case rfbFileDownloadFailed:
            break;
        default:
            break;
    }
    
    // this is a bit tricky, we return 0 to leave the message type in the
    // buffer to get a complete message data in next handler.
    return ret;
}

- (void)child:(RFBHandler *)handler finishedJob:(NSDictionary *)job onConnection:(RFBConnection *)connection
{
    // start again, read next message type
    [self start:connection];
}

@end
