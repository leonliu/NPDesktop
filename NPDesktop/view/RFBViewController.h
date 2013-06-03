//
//  RFBViewController.h
//  NPDesktop
//
//  Created by leon@github on 3/15/13.
//  Copyright (c) 2013 leon@github. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RFBConnection.h"
#import "RFBScrollView.h"
#import "RFBView.h"
#import "RFBServerData.h"

@protocol RFBViewControllerDisplayDelegate;

@interface RFBViewController : UIViewController <RFBConnectionDelegate, UIAlertViewDelegate, KeyInputDelegate, UIScrollViewDelegate>
{
    NSString *_desktopName;
    int _sid;
    RFBConnection *_connection;
}

@property (strong, nonatomic) IBOutlet RFBView *rfbView;
@property (strong, nonatomic) IBOutlet RFBScrollView *scrollView;
@property (weak) id<RFBViewControllerDisplayDelegate> delegate;

- (IBAction)switchMode:(id)sender;
- (IBAction)stopViewer:(id)sender;
- (IBAction)showKeyboard:(id)sender;

- (id)initWithServerId:(int)sid;
- (id)initWithServer:(RFBServerData *)server;

@end


@protocol RFBViewControllerDisplayDelegate <NSObject>

- (void)viewController:(RFBViewController *)rvc didFinishDisplay:(int)sid;

@end