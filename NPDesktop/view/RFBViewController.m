//
//  RFBViewController.m
//  NPDesktop
//
//  Created by leon@github on 3/15/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import "RFBViewController.h"
#import "RFBServerManager.h"
#import "Utility.h"

#define XK_MISCELLANY
#import "keysymdef.h"

@interface RFBViewController ()

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer;
- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer;
- (void)handleLongPress:(UILongPressGestureRecognizer *)recognizer;
- (void)handleSingleFingerDrag:(UIPanGestureRecognizer *)recognizer;

@end

@implementation RFBViewController

@synthesize delegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (IBAction)showKeyboard:(id)sender {
    
    [self.rfbView becomeFirstResponder];
}

- (IBAction)switchMode:(id)sender {
    
    UIButton *button = sender;
    
    if (self.scrollView.browsingMode) {
        [button setImage:[UIImage imageNamed:@"mouse"] forState:UIControlStateNormal];
    } else {
        [button setImage:[UIImage imageNamed:@"hand"] forState:UIControlStateNormal];
    }
    
    self.scrollView.browsingMode = !self.scrollView.browsingMode;
}

- (IBAction)stopViewer:(id)sender
{
    if (_connection) {
        [_connection close];
    } else {
        [delegate viewController:self didFinishDisplay:_sid];
    }
}

- (id)initWithServerId:(int)sid
{
    if ((self = [super initWithNibName:@"RFBViewController" bundle:nil])) {
        _sid = sid;
        RFBServerData *svr = [[RFBServerManager sharedInstance] serverWithId:sid];
        _connection = [[RFBConnection alloc] initWithServerData:svr];
    }
    
    return self;
}

- (id)initWithServer:(RFBServerData *)server
{
    if ((self = [super initWithNibName:@"RFBViewController" bundle:nil])) {
        _sid = server.serverId;
        _connection = [[RFBConnection alloc] initWithServerData:server];
        _connection.delegate = self;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UITapGestureRecognizer *str = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(handleSingleTap:)];
    UITapGestureRecognizer *dtr = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(handleDoubleTap:)];
    UIPanGestureRecognizer *spr = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(handleSingleFingerDrag:)];
    UILongPressGestureRecognizer *lpr = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                      action:@selector(handleLongPress:)];
    str.numberOfTapsRequired = 1;
    dtr.numberOfTapsRequired = 2;
    
    [str requireGestureRecognizerToFail:dtr];
    
    [self.rfbView addGestureRecognizer:str];
    [self.rfbView addGestureRecognizer:dtr];
    [self.rfbView addGestureRecognizer:spr];
    [self.rfbView addGestureRecognizer:lpr];
    
    [self.rfbView setDelegate:self];
    [self.scrollView setDelegate:self];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [_connection connect];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma -
#pragma mark UISCrollViewDelegate methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.rfbView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    DLogInfo(@"scrollViewDidZoom: scale=%f", scrollView.zoomScale);
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale
{
    CGPoint center = self.rfbView.center;
    center.y = self.scrollView.center.y;
    self.rfbView.center = center;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    DLogInfo(@"scrollViewWillBeginZooming: scale=%f", scrollView.zoomScale);
}

#pragma -
#pragma mark gesture recognizer target methods

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer
{
    // Big gift from UIScrollView, the touch location has already
    // been converted according to the zoom scale for the content
    // view, hence we do not need to convert in the methods below.
    
    CGPoint pos = [recognizer locationInView:self.rfbView];
    CARD8 buttonMask = 0x00;
    
    buttonMask |= 0x01;  // left mouse down
    [_connection sendPointerEvent:buttonMask position:pos];
    
    buttonMask = 0x00;   // left mouse up
    [_connection sendPointerEvent:buttonMask position:pos];    
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer
{
    CGPoint pos = [recognizer locationInView:self.rfbView];
    CARD8 buttonMask = 0x00;
    
    for (int i = 0; i < 2; i++) {
        
        buttonMask |= 0x01;  // left mouse down
        [_connection sendPointerEvent:buttonMask position:pos];
        
        buttonMask = 0x00;   // left mouse up
        [_connection sendPointerEvent:buttonMask position:pos];
    }
}

- (void)handleSingleFingerDrag:(UIPanGestureRecognizer *)recognizer
{
    CGPoint pos = [recognizer locationInView:self.rfbView];
    CARD8 buttonMask = 0x01;  // left mouse down
    
    [_connection sendPointerEvent:buttonMask position:pos];
    
    if (([recognizer state] == UIGestureRecognizerStateEnded) || ([recognizer state] == UIGestureRecognizerStateCancelled)) {
        buttonMask = 0x00;    // left mouse up
        [_connection sendPointerEvent:buttonMask position:pos];
    }
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)recognizer
{
    CGPoint pos = [recognizer locationInView:self.rfbView];
    
    CARD8 buttonMask = 0x04; // right mouse down
    [_connection sendPointerEvent:buttonMask position:pos];
    
    buttonMask = 0x00; // right mouse up
    [_connection sendPointerEvent:buttonMask position:pos];
}

#pragma -
#pragma mark RFBConnectionDelegate

- (void)connection:(RFBConnection *)conn didReceiveServerInit:(rfbServerInitMsg)msg
{
    CGSize size = CGSizeMake(msg.framebufferWidth, msg.framebufferHeight);
    RFBFrameBuffer *fb = [[RFBFrameBuffer alloc] initWithSize:size pixelFormat:msg.format];
    
    RFBViewController * __weak weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        CGFloat scale = weakSelf.rfbView.bounds.size.width / fb.size.width;
        if (scale > 1.0f) {
            [weakSelf.scrollView setMaximumZoomScale:scale];
        } else {
            [weakSelf.scrollView setMinimumZoomScale:scale];
        }
        
        [weakSelf.scrollView setContentSize:CGSizeMake(fb.size.width, fb.size.height)];
        [weakSelf.rfbView setFramebuffer:fb];
        [weakSelf.rfbView setFrame:CGRectMake(0.f, 0.f, fb.size.width, fb.size.height)];
    });
    
    if (![conn compareLocalFormatWithRemote:msg.format]) {
        [conn sendSetPixelFormat:fb.pixelFormat];
    }
    
    // use client side format
    self.rfbView.framebuffer.pixelFormat = conn.pixelFormat;
    
    // send prefered encoding list
    [conn sendSetEncodings];
    
    // send framebuffer update request
    [conn sendFrameBufferUpdateRequest:CGRectMake(0.f, 0.f, fb.size.width, fb.size.height) incremental:NO];
    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        NSTimer *timer = [NSTimer timerWithTimeInterval:0.1
//                                                 target:self
//                                               selector:@selector(handleFrameBufferUpdateTimerOut)
//                                               userInfo:nil
//                                                repeats:YES];
//        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
//        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
//    });
}

- (void)handleFrameBufferUpdateTimerOut
{
    RFBFrameBuffer *fb = self.rfbView.framebuffer;
    [_connection sendFrameBufferUpdateRequest:CGRectMake(0.f, 0.f, fb.size.width, fb.size.height) incremental:YES];
}

- (void)connection:(RFBConnection *)conn didReceiveDesktopName:(NSString *)name
{
    _desktopName = [NSString stringWithString:name];
    conn.serverData.name = _desktopName;
    [[RFBServerManager sharedInstance] saveServerList];
}

- (void)connection:(RFBConnection *)conn didReceiveFramebufferUpdate:(rfbFramebufferUpdateMsg)msg
{
    DLogInfo(@"framebufUpdate: nRects=%d", msg.nRects);
}

- (void)connection:(RFBConnection *)conn didReceiveDataForRect:(RFBRect *)aRect
{
    RFBViewController * __weak weakSelf = self;
        
    if (aRect.encoding == rfbEncodingRaw) {
        [weakSelf.rfbView.framebuffer fillRect:aRect.rect withData:aRect.data];
    } else if (aRect.encoding == rfbEncodingTight) {
        if (aRect.filter == rfbTightFilterCopy) {
            [weakSelf.rfbView.framebuffer fillRect:aRect.rect withTightData:aRect.data];
        } else if (aRect.filter == rfbTightFilterGradient) {
            [weakSelf.rfbView.framebuffer fillRect:aRect.rect withGradient:aRect.data];
        }
    }
}

- (void)connection:(RFBConnection *)conn didReceiveFillColor:(NSData *)cData forRect:(rfbRectangle)rect
{
    RFBViewController * __weak weakSelf = self;
    CARD8 *color = (CARD8 *)[cData bytes];
    [weakSelf.rfbView.framebuffer fillRect:CGRectMake(rect.x, rect.y, rect.w, rect.h) withColor:color];

}

- (void)connection:(RFBConnection *)conn didReceiveDataForRect:(RFBRect *)aRect withPalette:(NSData *)palette
{
    RFBViewController * __weak weakSelf = self;    
    [weakSelf.rfbView.framebuffer fillRect:aRect.rect withPalette:palette data:aRect.data];
}

- (void)connection:(RFBConnection *)conn didReceiveCopyRect:(rfbCopyRect)origin forRect:(rfbRectangle)rect
{
    RFBViewController * __weak weakSelf = self;
    [weakSelf.rfbView.framebuffer copyRect:CGRectMake(rect.x, rect.y, rect.w, rect.h)
                                    source:CGPointMake(origin.srcX, origin.srcY)];
}

- (void)connection:(RFBConnection *)conn shouldInvalidateRect:(CGRect)rect
{
    RFBViewController * __weak weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.rfbView setNeedsDisplayInRect:rect];
    });
}

- (void)connection:(RFBConnection *)conn didCompleteFramebufferUpdate:(int)nRects
{
    // refresh whole screen
    RFBViewController * __weak weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.rfbView setNeedsDisplay];
    });
    
    CGRect rect = CGRectMake(0.f, 0.f, self.rfbView.framebuffer.size.width, self.rfbView.framebuffer.size.height);
    [conn sendFrameBufferUpdateRequest:rect incremental:YES];
}

- (void)connection:(RFBConnection *)conn shouldCloseWithError:(NSError *)error
{
    if (conn == _connection) {
        [_connection close];
        
        dispatch_async(dispatch_get_main_queue(), ^{
           
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                            message:error.localizedDescription
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alert show];
        });
    }
}

- (void)connection:(RFBConnection *)conn didCloseWithError:(NSError *)error
{
    if (conn == _connection) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                                message:error.localizedDescription
                                                               delegate:self
                                                      cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate viewController:self didFinishDisplay:_sid];
            });
        }
    }
}

#pragma -
#pragma mark UIAlertViewDelegate method

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [delegate viewController:self didFinishDisplay:_sid];
}

#pragma -
#pragma mark KeyInputDelegate method

- (void)rfbView:(RFBView *)view didReceiveKeyInput:(int)key
{
    DLogInfo(@"keysym = %d", key);
    
    [_connection sendKeyEvent:key downflag:YES];
    
    // iOS system uses single code (0x0a) for return key input.
    // MS Windows uses two codes (0x0a and 0x0d) for return key input.
    if (key == XK_Linefeed) {
        [_connection sendKeyEvent:XK_Return downflag:YES];
    }
    
    [_connection sendKeyEvent:key downflag:NO];
}

@end
