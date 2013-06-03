//
//  RFBView.m
//  NPDesktop
//
//  Created by leon@github on 3/4/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import "RFBView.h"
#import "KeyMap.h"

@implementation RFBView

@synthesize framebuffer;
@synthesize delegate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // initialization
    }
    return self;
}

- (id)init
{
    if ((self = [super init])) {
        // initialization
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        // initialization
    }
    
    return self;
}

- (void)drawRect:(CGRect)rect
{
    if (framebuffer) {
        
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        CGContextSaveGState(ctx);
        DLogInfo(@"\ndrawRect: scale=%f, \nframe: x=%f, y=%f, w=%f, h=%f",
                 _scale,
                 self.frame.origin.x,
                 self.frame.origin.y,
                 self.frame.size.width,
                 self.frame.size.height);
        
        [framebuffer drawFullInRect:CGRectMake(0.f, 0.f, framebuffer.size.width, framebuffer.size.height) context:ctx];
        
        CGContextRestoreGState(ctx);
    }
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

#pragma -
#pragma mark UIKeyInput methods

- (BOOL)hasText
{
    NSLog(@"hasText");
    return NO;
}

- (void)insertText:(NSString *)text
{
    if (text) {
        DLogInfo(@"input: %@, unicode: %d", text, [text characterAtIndex:0]);
        uint32_t keysym = [KeyMap unicharToKeySym:[text characterAtIndex:0]];
        if (delegate) {
            [delegate rfbView:self didReceiveKeyInput:keysym];
        }
    }
}

- (void)deleteBackward
{
    uint32_t keysym = [KeyMap unicharToKeySym:0x08];
    if (delegate) {
        [delegate rfbView:self didReceiveKeyInput:keysym];
    }
}

@end
