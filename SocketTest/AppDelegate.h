//
//  AppDelegate.h
//  SocketTest
//
//  Created by 曹伟东 on 2019/4/6.
//  Copyright © 2019 曹伟东. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GCDAsyncSocket.h"

@interface AppDelegate : NSObject <NSApplicationDelegate,GCDAsyncSocketDelegate>
{
    GCDAsyncSocket *_serversocket;
    GCDAsyncSocket *_clientsocket;
    IBOutlet NSButton *_connectBtn;
    IBOutlet NSPopUpButton *_modeBtn;
    IBOutlet NSTextView *_logView;
    IBOutlet NSButton *_startSerBtn;
    IBOutlet NSButton *_sendBtn;
    IBOutlet NSTextField *_ipTF;
    IBOutlet NSTextField *_portTF;
    IBOutlet NSTextField *_cmdTF;
}

-(IBAction)StartServerBtnAction:(id)sender;
-(IBAction)SendBtnAction:(id)sender;
-(IBAction)ConnectBtnAction:(id)sender;
-(IBAction)ModeChooseBtnAction:(id)sender;

@end

