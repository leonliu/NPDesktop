//
//  RFBRect.m
//  NPDesktop
//
//  Created by leon@github on 3/26/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import "RFBRect.h"

@implementation RFBRect

@synthesize rect;
@synthesize data;
@synthesize encoding;
@synthesize filter;

- (id)initWithData:(NSData *)aData rect:(rfbRectangle)aRect
{
    if ((self = [super init])) {
        data = aData;
        rect = CGRectMake(aRect.x, aRect.y, aRect.w, aRect.h);
    }
    
    return self;
}

@end
