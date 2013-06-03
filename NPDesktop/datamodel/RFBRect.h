//
//  RFBRect.h
//  NPDesktop
//
//  Created by leon@github on 3/26/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "rfbproto.h"

@interface RFBRect : NSObject

@property (readonly) CGRect rect;
@property (readonly) NSData *data;
@property int encoding;
@property int filter;

- (id)initWithData:(NSData *)aData rect:(rfbRectangle)aRect;

@end
