//
//  RFBScrollView.m
//  NPDesktop
//
//  Created by leon@github on 3/29/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import "RFBScrollView.h"

@implementation RFBScrollView

@synthesize browsingMode;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        browsingMode = YES;
    }
    return self;
}

- (BOOL)touchesShouldBegin:(NSSet *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view
{
    BOOL ret = NO;
    if (!browsingMode) {
        ret = YES;
    }
    DLogInfo(@"should begin? %d", ret);
    return ret;
}

- (BOOL)touchesShouldCancelInContentView:(UIView *)view
{
    BOOL ret = NO;
    if (browsingMode) {
        ret = YES;
    }
    
    DLogInfo(@"should cancel? %d", ret);
    return ret;
}

@end
