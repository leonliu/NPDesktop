//
//  RFBView.h
//  NPDesktop
//
//  Created by leon@github on 3/4/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RFBFrameBuffer.h"
#import <QuartzCore/QuartzCore.h>

@protocol KeyInputDelegate;
@interface RFBView : UIView <UIKeyInput>


@property (nonatomic) RFBFrameBuffer *framebuffer;
@property (weak) id<KeyInputDelegate> delegate;

@end

@protocol KeyInputDelegate <NSObject>

- (void)rfbView:(RFBView *)view didReceiveKeyInput:(int)key;

@end

