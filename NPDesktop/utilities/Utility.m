//
//  Utility.m
//  NPDesktop
//
//  Created by leon@github on 3/8/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import "Utility.h"
#import "RFBConnection.h"

#define DEFAULT_CONFIG_PATH @"/config"

@implementation Utility

+ (BOOL)isSystemBigEndian
{
    union {
        unsigned char c[2];
        unsigned short s;
    } x;
    
    x.s = 0x1234;
    return (x.c[0] == 0x12);
}

+ (NSError *)rfbError:(NSString *)desc code:(NSUInteger)code
{
    NSDictionary *info = [NSDictionary dictionaryWithObject:desc forKey:NSLocalizedDescriptionKey];
    return [NSError errorWithDomain:RFBConnectionErrorDomain code:code userInfo:info];
}

+ (NSString *)applicationPath
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *supDir = [fm URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    if ([supDir count] == 0) {
        DLogError(@"Can not find application support directory!");
        return nil;
    }
    
    NSString *product = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    NSString *path = [[[supDir objectAtIndex:0] URLByAppendingPathComponent:product] path];
    NSError *error = nil;
    BOOL directory = YES;
    
    if (![fm fileExistsAtPath:path isDirectory:&directory]) {
        if (![fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error]) {
            DLogError(@"Failed to create application directory. Error: %@", error.description);
            return nil;
        }
    }
    
    return path;
}

+ (NSString *)configPath
{
    NSString *home = [self applicationPath];
    if (!home) {
        return nil;
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *path = [NSString stringWithFormat:@"%@%@", home, DEFAULT_CONFIG_PATH];
    NSError *error = nil;
    BOOL directory = YES;
    
    if (![fm fileExistsAtPath:path isDirectory:&directory]) {
        if (![fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error]) {
            DLogError(@"Failed to create configuration path. Error: %@", error.description);
            return nil;
        }
    }
    
    return path;
}

+ (NSString *)rfbSecurityTypeToString:(int)stype
{
    NSString *ret = @"unknown";
    switch (stype) {
        case rfbSecTypeInvalid:
            ret = @"rfbSecTypeInvalid";
            break;
        case rfbSecTypeNone:
            ret = @"rfbSecTypeNone";
            break;
        case rfbSecTypeTight:
            ret = @"rfbSecTypeTight";
            break;
        case rfbSecTypeVncAuth:
            ret = @"rfbSecTypeVncAuth";
            break;
            
        default:
            break;
    }
    
    return ret;
}

+ (NSString *)rfbEncodingTypeToString:(int)encoding
{
    NSString *ret = @"unknown";
    switch (encoding) {
        case rfbEncodingRaw:
            ret = @"rfbEncodingRaw";
            break;
        case rfbEncodingCopyRect:
            ret = @"rfbEncodingCopyRect";
            break;
        case rfbEncodingRRE:
            ret = @"rfbEncodingRRE";
            break;
        case rfbEncodingCoRRE:
            ret = @"rfbEncodingCoRRE";
            break;
        case rfbEncodingHextile:
            ret = @"rfbEncodingHextile";
            break;
        case rfbEncodingZlib:
            ret = @"rfbEncodingZlib";
            break;
        case rfbEncodingTight:
            ret = @"rfbEncodingTight";
            break;
        case rfbEncodingZlibHex:
            ret = @"rfbEncodingZlibHex";
            break;
        case rfbEncodingZRLE:
            ret = @"rfbEncodingZRLE";
            break;
        case rfbEncodingCompressLevel0:
            ret = @"rfbEncodingCompressLevel0";
            break;
        case rfbEncodingCompressLevel1:
            ret = @"rfbEncodingCompressLevel1";
            break;
        case rfbEncodingCompressLevel2:
            ret = @"rfbEncodingCompressLevel2";
            break;
        case rfbEncodingCompressLevel3:
            ret = @"rfbEncodingCompressLevel3";
            break;
        case rfbEncodingCompressLevel4:
            ret = @"rfbEncodingCompressLevel4";
            break;
        case rfbEncodingCompressLevel5:
            ret = @"rfbEncodingCompressLevel5";
            break;
        case rfbEncodingCompressLevel6:
            ret = @"rfbEncodingCompressLevel6";
            break;
        case rfbEncodingCompressLevel7:
            ret = @"rfbEncodingCompressLevel7";
            break;
        case rfbEncodingCompressLevel8:
            ret = @"rfbEncodingCompressLevel8";
            break;
        case rfbEncodingCompressLevel9:
            ret = @"rfbEncodingCompressLevel9";
            break;
        case rfbEncodingQualityLevel0:
            ret = @"rfbEncodingQualityLevel0";
            break;
        case rfbEncodingQualityLevel1:
            ret = @"rfbEncodingQualityLevel1";
            break;
        case rfbEncodingQualityLevel2:
            ret = @"rfbEncodingQualityLevel2";
            break;
        case rfbEncodingQualityLevel3:
            ret = @"rfbEncodingQualityLevel3";
            break;
        case rfbEncodingQualityLevel4:
            ret = @"rfbEncodingQualityLevel4";
            break;
        case rfbEncodingQualityLevel5:
            ret = @"rfbEncodingQualityLevel5";
            break;
        case rfbEncodingQualityLevel6:
            ret = @"rfbEncodingQualityLevel6";
            break;
        case rfbEncodingQualityLevel7:
            ret = @"rfbEncodingQualityLevel7";
            break;
        case rfbEncodingQualityLevel8:
            ret = @"rfbEncodingQualityLevel8";
            break;
        case rfbEncodingQualityLevel9:
            ret = @"rfbEncodingQualityLevel9";
            break;            
        case rfbEncodingXCursor:
            ret = @"rfbEncodingXCursor";
            break;
        case rfbEncodingRichCursor:
            ret = @"rfbEncodingRichCursor";
            break;
        case rfbEncodingPointerPos:
            ret = @"rfbEncodingPointerPos";
            break;
        case rfbEncodingLastRect:
            ret = @"rfbEncodingLastRect";
            break;
        case rfbEncodingNewFBSize:
            ret = @"rfbEncodingNewFBSize";
            break;
        default:
            break;
    }
    return ret;
}

+ (NSString *)rfbPixelFormatToString:(rfbPixelFormat)format
{
    NSString *ret = [NSString stringWithFormat:@"\n rfbPixelFormat: "
                     "\n bitsPerPixel = %d"
                     "\n depth        = %d"
                     "\n bigEndian    = %d"
                     "\n trueColor    = %d"
                     "\n redMax       = %d"
                     "\n greenMax     = %d"
                     "\n blueMax      = %d"
                     "\n redShift     = %d"
                     "\n greenShift   = %d"
                     "\n blueShift    = %d",
                     format.bitsPerPixel,
                     format.depth,
                     format.bigEndian,
                     format.trueColour,
                     format.redMax,
                     format.greenMax,
                     format.blueMax,
                     format.redShift,
                     format.greenShift,
                     format.blueShift];
    
    return ret;
}

+ (NSString *)rfbSecurityResultToString:(int)result
{
    NSString *ret = @"unknown";
    switch (result) {
        case rfbAuthOK:
            ret = @"rfbAuthOK";
            break;
        case rfbAuthFailed:
            ret = @"rfbAuthFailed";
            break;
        case rfbAuthTooMany:
            ret = @"rfbAuthTooMany";
            break;
            
        default:
            break;
    }
    
    return ret;
}

+ (NSString *)rfbServerMsgTypeToString:(int)type
{
    NSString *ret = @"unknown";
    switch (type) {
        case rfbFramebufferUpdate:
            ret = @"rfbFramebufferUpdate";
            break;
        case rfbSetColourMapEntries:
            ret = @"rfbSetColourMapEntries";
            break;
        case rfbBell:
            ret = @"rfbBell";
            break;
        case rfbServerCutText:
            ret = @"rfbServerCutText";
            break;
        case rfbFileListData:
            ret = @"rfbFileListData";
            break;
        case rfbFileDownloadData:
            ret = @"rfbFileDownloadData";
            break;
        case rfbFileUploadCancel:
            ret = @"rfbFileUploadCancel";
            break;
        case rfbFileDownloadFailed:
            ret = @"rfbFileDownloadFailed";
            break;
            
        default:
            break;
    }
    
    return ret;
}

+ (NSString *)rfbClientMsgTypeToString:(int)type
{
    NSString *ret = @"unknown";
    switch (type) {
        case rfbSetPixelFormat:
            ret = @"rfbSetPixelFormat";
            break;
        case rfbFixColourMapEntries:
            ret = @"rfbFixColourMapEntries";
            break;
        case rfbSetEncodings:
            ret = @"rfbSetEncodings";
            break;
        case rfbFramebufferUpdateRequest:
            ret = @"rfbFramebufferUpdateRequest";
            break;
        case rfbKeyEvent:
            ret = @"rfbKeyEvent";
            break;
        case rfbPointerEvent:
            ret = @"rfbPointerEvent";
            break;
        case rfbClientCutText:
            ret = @"rfbClientCutText";
            break;
        case rfbFileListRequest:
            ret = @"rfbFileListRequest";
            break;
        case rfbFileDownloadRequest:
            ret = @"rfbFileDownloadRequest";
            break;
        case rfbFileUploadRequest:
            ret = @"rfbFileUploadRequest";
            break;
        case rfbFileUploadData:
            ret = @"rfbFileUploadData";
            break;
        case rfbFileDownloadCancel:
            ret = @"rfbFileDownloadCancel";
            break;
        case rfbFileUploadFailed:
            ret = @"rfbFileUploadFailed";
            break;
        case rfbFileCreateDirRequest:
            ret = @"rfbFileCreateDirRequest";
            break;
            
        default:
            break;
    }
    
    return ret;
}

+ (NSString *)rfbRectHeaderToString:(rfbFramebufferUpdateRectHeader)header
{
    NSString *ret = [NSString stringWithFormat:@"\n rfbFramebufferUpdateRectHeader: "
                     "\n x = %d"
                     "\n y = %d"
                     "\n w = %d"
                     "\n h = %d"
                     "\n encoding = %@",
                     header.r.x,
                     header.r.y,
                     header.r.w,
                     header.r.h,
                     [self rfbEncodingTypeToString:header.encoding]];
    
    return ret;
}

+ (NSString *)rfbTightSubEncodingToString:(int)encoding
{
    NSString *ret = @"unknown";
    
    if (encoding == rfbTightFill) {
        ret = @"rfbTightFill";
    } else if (encoding == rfbTightJpeg) {
        ret = @"rfbTightJpeg";
    } else {
        ret = @"rfbTightBasic";
    }
    
    return ret;
}

+ (NSString *)rfbTightFilterToString:(int)filter
{
    NSString *ret = @"unknown";
    
    if (filter == rfbTightFilterCopy) {
        ret = @"rfbTightFilterCopy";
    } else if (filter == rfbTightFilterGradient) {
        ret = @"rfbTightFilterGradient";
    } else if (filter == rfbTightFilterPalette) {
        ret = @"rfbTightFilterPalette";
    }
    
    return ret;
}

@end
