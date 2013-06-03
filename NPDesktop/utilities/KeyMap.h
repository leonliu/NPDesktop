//
//  KeyMap.h
//  NPDesktop
//
//  Created by leon@github on 4/11/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KeyMap : NSObject

// we don't bother covering all the X11 key symbols for the time being.
+ (uint32_t)unicharToKeySym:(unichar)ch;

@end
