//
//  KeyMap.m
//  NPDesktop
//
//  Created by leon@github on 4/11/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#define XK_MISCELLANY

#import "KeyMap.h"
#import "keysymdef.h"

@implementation KeyMap

+ (uint32_t)unicharToKeySym:(unichar)ch
{
    uint32_t ret;
    
    // Latin-1 characters
    if (((ch >= 32) && (ch <= 126)) || ((ch >= 160) && (ch <= 255))) {
        ret = ch;
    } else if (ch == 0x20ac) {  // Euro sign
        ret = ch;
    } else if (ch == 0x08) {    // backspace
        ret = XK_BackSpace;
    } else if (ch == 0x0a) {    // linefeed
        ret = XK_Linefeed;
    } else if (ch == 0x0d) {    // carriage return
        ret = XK_Return;
    } else if (ch == 0x0f) {    // delete
        ret = XK_Delete;
    }else {
        
        // Only support standard virtual keyboard for iOS. All most all
        // key inputs are within ASCII table except the Euro sign.
        // For any input that are out of this range, pass the symbol as
        // unicode with special flag. Note that this method is only valid
        // for 0x100 - 0x10ffff unicode value range.
        ret = ch | 0x01000000;
    }
    
    return ret;
}

@end
