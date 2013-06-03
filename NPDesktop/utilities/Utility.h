//
//  Utility.h
//  NPDesktop
//
//  Created by leon@github on 3/8/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "rfbproto.h"

@interface Utility : NSObject

// check the local system is big endian or not
+ (BOOL)isSystemBigEndian;

// convenient method to generate NSError with error description and code
+ (NSError *)rfbError:(NSString *)desc code:(NSUInteger)code;

// the application path
+ (NSString *)applicationPath;

// path for app configuration data path
+ (NSString *)configPath;

// meaningful string for RFB security type
+ (NSString *)rfbSecurityTypeToString:(int)stype;

// meaningful string for RFB encoding type
+ (NSString *)rfbEncodingTypeToString:(int)encoding;

// meaningful string for RFB pixel format
+ (NSString *)rfbPixelFormatToString:(rfbPixelFormat)format;

// meaningful string for RFB Authentication result
+ (NSString *)rfbSecurityResultToString:(int)result;

// meaningful string for RFB message type
+ (NSString *)rfbServerMsgTypeToString:(int)type;

+ (NSString *)rfbClientMsgTypeToString:(int)type;

// meaningful string for RFB rect header
+ (NSString *)rfbRectHeaderToString:(rfbFramebufferUpdateRectHeader)header;

// meaningful string for Tight subencoding type
+ (NSString *)rfbTightSubEncodingToString:(int)encoding;

// meaningful string for Tight filter type
+ (NSString *)rfbTightFilterToString:(int)filter;

@end
