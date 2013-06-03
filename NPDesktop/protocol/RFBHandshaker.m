//
//  RFBHandshaker.m
//  NPDesktop
//
//  Created by leon@github on 3/26/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import "RFBHandshaker.h"
#import "RFBInitializer.h"
#import "Utility.h"
#import "vncauth.h"
#import "RFBServerData.h"

@interface RFBHandshaker()

- (void)failWithErrorString:(NSString *)string code:(NSUInteger)code connection:(RFBConnection *)connection;

- (NSUInteger)processProtocolVersion:(NSData *)data from:(RFBConnection *)connection;
- (NSUInteger)processSecurityTypeNumber:(NSData *)data from:(RFBConnection *)connection;
- (NSUInteger)processSecurityTypeList:(NSData *)data from:(RFBConnection *)connection;
- (NSUInteger)processSecurityType:(NSData *)data from:(RFBConnection *)connection;
- (NSUInteger)processAuthChallenge:(NSData *)data from:(RFBConnection *)connection;
- (NSUInteger)processSecurityResult:(NSData *)data from:(RFBConnection *)connection;
- (NSUInteger)processReasonLength:(NSData *)data from:(RFBConnection *)connection;
- (NSUInteger)processReasonString:(NSData *)data from:(RFBConnection *)connection;

@end

@implementation RFBHandshaker

@synthesize state;

- (id)init
{
    if ((self = [super init])) {
        state = RFBHandshakerStateIdle;
        _securityTypeNumber = 0;
    }
    
    return self;
}

- (BOOL)start:(RFBConnection *)connection
{
    self.nbytesWaiting = sz_rfbProtocolVersionMsg;
    self.state = RFBHandshakerStateWaitProtocolVersion;
    [connection setHandler:self];
    
    return YES;
}

- (NSUInteger)processMessage:(NSData *)data from:(RFBConnection *)connection
{
    NSUInteger ret = 0;
    
    switch (state) {
        case RFBHandshakerStateWaitProtocolVersion:
            ret = [self processProtocolVersion:data from:connection];
            break;
        case RFBHandshakerStateWaitSecurityTypeNumber:
            ret = [self processSecurityTypeNumber:data from:connection];
            break;
        case RFBHandshakerStateWaitSecurityTypeList:
            ret = [self processSecurityTypeList:data from:connection];
            break;
        case RFBHandshakerStateWaitSecurityType:
            ret = [self processSecurityType:data from:connection];
            break;
        case RFBHandshakerStateWaitReasonLength:
            ret = [self processReasonLength:data from:connection];
            break;
        case RFBHandshakerStateWaitReasonString:
            ret = [self processReasonString:data from:connection];
            break;
        case RFBHandshakerStateWaitSecurityResult:
            ret = [self processSecurityResult:data from:connection];
            break;
        case RFBHandshakerStateWaitChallenge:
            ret = [self processAuthChallenge:data from:connection];
            break;
            
        default:
            DLogError(@"unknown state");
            break;
    }
    
    return ret;
}

#pragma mark - private methods

- (void)failWithErrorString:(NSString *)string code:(NSUInteger)code connection:(RFBConnection *)connection
{
    NSDictionary *info = [NSDictionary dictionaryWithObject:string forKey:NSLocalizedDescriptionKey];
    NSError *error = [NSError errorWithDomain:RFBConnectionErrorDomain code:code userInfo:info];
    [connection.delegate connection:connection shouldCloseWithError:error];
}

- (NSUInteger)processProtocolVersion:(NSData *)data from:(RFBConnection *)connection
{
    if (data.length < sz_rfbProtocolVersionMsg) {
        return 0;
    }
    
    // C string of server version: 12 bytes, e.g. "RFB 003.003\n"
    rfbProtocolVersionMsg pv;
    [data getBytes:pv length:sz_rfbProtocolVersionMsg];
    pv[sz_rfbProtocolVersionMsg] = '\0';
    
    DLogInfo(@"protocol version: %s", pv);
    
    NSUInteger majorVer;
    NSUInteger minorVer;
    
    if (sscanf(pv, rfbProtocolVersionFormat, &majorVer, &minorVer) != 2) {
        [self failWithErrorString:@"failed to get VNC version"
                             code:RFBConnectionProtocolError
                       connection:connection];
        
    } else {
        if ((majorVer == 3) && (minorVer >= 8)) {
            minorVer = 8;
        } else if ((majorVer == 3) && (minorVer == 7)) {
            minorVer = 7;
        } else {
            majorVer = 3;
            minorVer = 3;
        }
        
        connection.rfbMajorVersion = MIN(rfbProtocolMajorVersion, majorVer);
        connection.rfbMinorVersion = MIN(rfbProtocolMinorVersion, minorVer);
        
        // Negotiation is done. Send ProtocolVersion message to server.
        [connection sendProtocolVersion];
        
        if (connection.rfbMinorVersion == 3) {
            self.nbytesWaiting = sizeof(CARD32);
            self.state = RFBHandshakerStateWaitSecurityType;
        } else {
            self.nbytesWaiting = sizeof(CARD8);
            self.state = RFBHandshakerStateWaitSecurityTypeNumber;
        }
    }
    
    return sz_rfbProtocolVersionMsg;
}

//
//
// Version 3.7 onwards, the server lists the security types which it supports.
//
//    No. of bytes            |    Type   |    Description
//  --------------------------+-----------+---------------------------
//    1                       | U8        | number-of-security-types
//  --------------------------+-----------+---------------------------
//   number-of-security-types | U8 array  | security-types
//  --------------------------+-----------+---------------------------
//
//  If the server listed at least one valid security type supported by the
//  client, the client sends back a single byte indicating which security
//  type is to be used on the connection.
//
//  If number-of-security-types is zero, then for some reason the connection
//  failed. This is followed by a string describing the reason.
//
// Version 3.3, the server decides the security type and sends a single word.
//
//    No. of bytes            |    Type   |    Description
//  --------------------------+-----------+---------------------------
//    4                       | U32       | security-type
//  --------------------------+-----------+---------------------------
//

- (NSUInteger)processSecurityTypeNumber:(NSData *)data from:(RFBConnection *)connection
{
    if (data.length < sizeof(CARD8)) {
        return 0;
    }
    
    _securityTypeNumber = *(CARD8 *)[data bytes];
    
    if (_securityTypeNumber == 0) {  // connection failed, read reason length
        self.nbytesWaiting = sizeof(CARD32);
        self.state = RFBHandshakerStateWaitReasonLength;
    } else { // read security types
        self.nbytesWaiting = _securityTypeNumber * sizeof(CARD8);
        self.state = RFBHandshakerStateWaitSecurityTypeList;
    }
    
    return sizeof(CARD8);
}

- (NSUInteger)processSecurityTypeList:(NSData *)data from:(RFBConnection *)connection
{
    if (data.length < self.nbytesWaiting) {
        DLogInfo(@"\ndata length=%d, bytes wanted=%ld", data.length, self.nbytesWaiting);
        return 0;
    }
    
    NSUInteger ret = self.nbytesWaiting;
    
    // Server lists the security types it supports, client chooses the first one
    CARD8 *secTypes = (CARD8 *)[data bytes];
    CARD8 secType = rfbSecTypeInvalid;
    
    for (int i = 0; i < _securityTypeNumber; i++) {
        
        DLogInfo(@"security type: %@", [Utility rfbSecurityTypeToString:secTypes[i]]);
        
        if ((secTypes[i] == rfbSecTypeNone) || (secTypes[i] == rfbSecTypeVncAuth)) {
            secType = secTypes[i];
            [connection sendSecurityType:secType];
            break;
        }
    }
    
    if (secType == rfbSecTypeNone) {
        if (connection.rfbMinorVersion >= 8) { // read security result            
            self.nbytesWaiting = sizeof(CARD32);
            self.state = RFBHandshakerStateWaitSecurityResult;
        } else { // go to initialization phase
            RFBInitializer *initializer = [[RFBInitializer alloc] init];
            [initializer start:connection];
        }
    } else if (secType == rfbSecTypeVncAuth) { // read auth challenge
        self.nbytesWaiting = CHALLENGE_SIZE;
        self.state = RFBHandshakerStateWaitChallenge;
    } else { // invalid security type
        [self failWithErrorString:@"failed to decide security type!"
                             code:RFBConnectionSecurityTypeError
                       connection:connection];
    }
    
    return ret;
}

- (NSUInteger)processSecurityType:(NSData *)data from:(RFBConnection *)connection
{
    if (data.length < self.nbytesWaiting) {
        DLogInfo(@"\ndata length=%d, bytes wanted=%ld", data.length, self.nbytesWaiting);
        return 0;
    }
    
    NSUInteger ret = self.nbytesWaiting;
    
    // version 3.3, the server decides the security type and sends a single word.
    CARD32 stype = rfbSecTypeInvalid;
    [data getBytes:&stype length:sizeof(CARD32)];
    stype = ntohl(stype);
    
    if (stype == rfbSecTypeInvalid) { // connection failed
        self.nbytesWaiting = sizeof(CARD32);
        self.state = RFBHandshakerStateWaitReasonLength;
    } else if (stype == rfbSecTypeNone) {
        // No authentication is needed, go to initialization phase
        RFBInitializer *initializer = [[RFBInitializer alloc] init];
        [initializer start:connection];
    } else if (stype == rfbSecTypeVncAuth) {
        // VNC authentication, this followed by a challenge from server
        self.nbytesWaiting = CHALLENGE_SIZE;
        self.state = RFBHandshakerStateWaitChallenge;
    }
    
    return ret;
}

- (NSUInteger)processAuthChallenge:(NSData *)data from:(RFBConnection *)connection
{
    if (data.length < self.nbytesWaiting) {
        DLogInfo(@"\ndata length=%d, bytes wanted=%ld", data.length, self.nbytesWaiting);
        return 0;
    }
    
    NSUInteger ret = self.nbytesWaiting;
    
    NSString *pwd = connection.serverData.password;
    if (!pwd || ([pwd length] == 0)) {
        [self failWithErrorString:@"password is required"
                             code:RFBConnectionAuthNeedPwdError
                       connection:connection];
    } else {
        CARD8 *bytes = (CARD8 *)[data bytes];
        vnc_encrypt_bytes(bytes, (char *)[pwd cStringUsingEncoding:NSUTF8StringEncoding]);
        
        DLogInfo(@"password: %@, encrypted: %s", pwd, bytes);
        
        [connection sendAuthResponse:[NSData dataWithBytes:bytes length:CHALLENGE_SIZE]];
        
        // read SecurityResult
        self.nbytesWaiting = sizeof(CARD32);
        self.state = RFBHandshakerStateWaitSecurityResult;
    }
    
    return ret;
}

- (NSUInteger)processSecurityResult:(NSData *)data from:(RFBConnection *)connection
{
    if (data.length < self.nbytesWaiting) {
        DLogInfo(@"\ndata length=%d, bytes wanted=%ld", data.length, self.nbytesWaiting);
        return 0;
    }
    
    NSUInteger ret = self.nbytesWaiting;
    
    CARD32 result = rfbAuthOK;
    [data getBytes:&result length:sizeof(CARD32)];
    result = ntohl(result);
    
    DLogInfo(@"Auth result: %@", [Utility rfbSecurityResultToString:result]);
    
    // result code 'rfbAuthTooMany' should never happen since we do not
    // specify the Tight security type.
    
    if (result == rfbAuthOK) { // go to initialization phase
        RFBInitializer *initializer = [[RFBInitializer alloc] init];
        [initializer start:connection];
    } else if (result == rfbAuthFailed) {
        if (connection.rfbMinorVersion >= 8) {
            self.nbytesWaiting = sizeof(CARD32);
            self.state = RFBHandshakerStateWaitReasonLength;
        } else {
            NSString *msg = @"Authentication failed!";
            NSError *error = [Utility rfbError:msg code:RFBConnectionAuthFailureError];
            [connection.delegate connection:connection shouldCloseWithError:error];
        }
    } else {
        NSString *desc = [NSString stringWithFormat:@"Authentication failed, unknown result %d.", result];
        [self failWithErrorString:desc code:RFBConnectionAuthFailureError connection:connection];
    }
    
    return ret;
}

- (NSUInteger)processReasonLength:(NSData *)data from:(RFBConnection *)connection
{
    if (data.length < self.nbytesWaiting) {
        DLogInfo(@"\ndata length=%d, bytes wanted=%ld", data.length, self.nbytesWaiting);
        return 0;
    }
    
    NSUInteger ret = self.nbytesWaiting;
    
    [data getBytes:&_reasonStrLen length:sizeof(CARD32)];
    _reasonStrLen = ntohl(_reasonStrLen);
    
    // read reason-string
    self.nbytesWaiting = _reasonStrLen * sizeof(CARD8);
    self.state = RFBHandshakerStateWaitReasonString;
    
    return ret;
}

- (NSUInteger)processReasonString:(NSData *)data from:(RFBConnection *)connection
{
    if (data.length < self.nbytesWaiting) {
        DLogInfo(@"\ndata length=%d, bytes wanted=%ld", data.length, self.nbytesWaiting);
        return 0;
    }
    
    NSUInteger ret = self.nbytesWaiting;
    
    NSData *strData = [data subdataWithRange:NSMakeRange(0, (_reasonStrLen * sizeof(CARD8)))];
    NSString *reason = [[NSString alloc] initWithData:strData
                                             encoding:NSUTF8StringEncoding];
    [self failWithErrorString:reason code:RFBConnectionAuthFailureError connection:connection];
    
    return ret;
}

@end
