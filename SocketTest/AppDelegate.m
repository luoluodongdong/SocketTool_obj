//
//  AppDelegate.m
//  SocketTest
//
//  Created by 曹伟东 on 2019/4/6.
//  Copyright © 2019 曹伟东. All rights reserved.
//

#import "AppDelegate.h"
#define READ_TIMEOUT 3
#define WRITE_TIMEOUT 3
#define SERVER_USERDATA 1000
#define CLIENT_USERDATA 2000

@interface AppDelegate ()
{
    NSMutableArray *socketArray;
    NSLock *_lock;
    NSString *_logString;
    NSString *_mode;
    BOOL _READ_TIMOUT_FLAG;
}
@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    [_modeBtn removeAllItems];
    [_modeBtn addItemsWithTitles:@[@"Server",@"Client"]];
    [_modeBtn selectItemAtIndex:0];
    //default mode:Server
    _mode =@"SERVER";
    [_connectBtn setEnabled:NO];
    //[_cmdTF setEnabled:NO];
    //[_sendBtn setEnabled:NO];
    
    _serversocket=nil;
    _clientsocket=nil;
    _READ_TIMOUT_FLAG=NO;
    //NSURL *url=[[NSURL alloc] initWithString:@"tcp:\\192.168.1.12:5555"];
    //BOOL status=[_socket acceptOnUrl:url error:nil];
    //BOOL status=[_socket acceptOnPort:5555 error:nil];
    //NSError *err;
    //BOOL status =[_socket acceptOnInterface:@"127.0.0.1" port:5555 error:&err];
    
    //NSLog(@"server status:%hhd error:%@",status,err);
    
    //stop listening
    //[_socket disconnect];
    _logString=@"";
}
-(IBAction)StartServerBtnAction:(id)sender{
    if ([[_startSerBtn title] isEqualToString:@"StartServer"]) {
        NSString *ip=[_ipTF stringValue];
        int port=[_portTF intValue];
        NSError *err;
        // 服务器socket实例化  在0x1234端口监听数据
        socketArray=[[NSMutableArray alloc] initWithCapacity:1];
        //_socket.delegate=self;
        _serversocket=[[GCDAsyncSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        [_serversocket setDelegate:self];
        //_socket.userData=123;
        BOOL status =[_serversocket acceptOnInterface:ip port:port error:&err];
        NSString *msg=[NSString stringWithFormat:@"server status:%hhd error:%@",status,err];
        [self logUpdate:msg];
        if(status){
            [_startSerBtn setTitle:@"StopServer"];
        }
    }else{
        [_startSerBtn setTitle:@"StartServer"];
        for (int i=0; i<[socketArray count]; i++) {
            GCDAsyncSocket *client=[socketArray objectAtIndex:i];
            [client disconnect];
            [client setDelegate:nil];
            
        }
        [_serversocket setDelegate:nil];
        [_serversocket disconnect];
        
        //[_serversocket release];
        [self logUpdate:@"Server stop listening"];
    }
    
}

-(IBAction)SendBtnAction:(id)sender{
    NSString *cmd=[_cmdTF stringValue];
    NSData *data=[cmd dataUsingEncoding:NSUTF8StringEncoding];
    NSString *msg=[NSString stringWithFormat:@"[TX]%@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
    [self logUpdate:msg];
    _READ_TIMOUT_FLAG=YES;
    if ([_mode isEqualToString:@"CLIENT"]) {
        [_clientsocket writeData:data withTimeout:WRITE_TIMEOUT tag:300];
        // 继续读取socket数据
        [_clientsocket readDataWithTimeout:-1 tag:300];
    }
    else{
        if([socketArray count] == 0){
            [self logUpdate:@"No client connected,please check!"];
            return;
        }
        for (int i=0; i<[socketArray count]; i++) {
            GCDAsyncSocket *client=[socketArray objectAtIndex:i];
            [client writeData:data withTimeout:WRITE_TIMEOUT tag:300];
            // 继续读取socket数据
            [client readDataWithTimeout:-1 tag:300];
        }
        
    }
    
}
-(void)CheckReadDataTimeOut{
    float timeout=READ_TIMEOUT+0.2;
    float count_t=0.0;
    while (count_t<=timeout) {
        [NSThread sleepForTimeInterval:0.05];
        count_t +=0.05;
        if(!_READ_TIMOUT_FLAG) return;
    }
    [self logUpdate:@"[RX][ERROR]Read data TIMEOUT!"];
}
-(IBAction)ConnectBtnAction:(id)sender{
    if ([[_connectBtn title] isEqualToString:@"ConnectServer"]) {
        //_socket.delegate=self;
        _clientsocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()]; //  !!!! 用GCD的形式
        [_clientsocket setDelegate:self];
        NSError *err = nil;
        NSString *ip=[_ipTF stringValue];
        int port=[_portTF intValue];
        int t = [_clientsocket connectToHost:ip onPort:port error:&err];
        NSString *msg=[NSString stringWithFormat:@"connect status:%d error:%@",t,err];
        [self logUpdate:msg];
        if(t){
            [_connectBtn setTitle:@"DisconnectServer"];
        }
        
    }else {
        [_clientsocket setDelegate:nil];
        [_clientsocket disconnect];
        _clientsocket=nil;
        [_connectBtn setTitle:@"ConnectServer"];
        [self logUpdate:@"Disconnect done."];
        //[_socket readDataWithTimeout:-1 tag:0];
        //return 1;
        
    }
}
-(IBAction)ModeChooseBtnAction:(id)sender{
    if ([_modeBtn indexOfSelectedItem] == 0) { //mode:Server
        _mode=@"SERVER";
        [_startSerBtn setEnabled:YES];
        [_connectBtn setEnabled:NO];
        //[_cmdTF setEnabled:NO];
        //[_sendBtn setEnabled:NO];
    }else{
        _mode=@"CLIENT";
        [_startSerBtn setEnabled:NO];
        [_connectBtn setEnabled:YES];
        //[_cmdTF setEnabled:YES];
        //[_sendBtn setEnabled:YES];
    }
}
// 有新的socket向服务器链接自动回调
-(void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    [socketArray addObject:newSocket];
    NSString *msg=[NSString stringWithFormat:@"Accept new client:%@ \nip:%@",newSocket,[newSocket connectedHost]];
    [self logUpdate:msg];
    NSLog(@"%@ %@",socketArray,[socketArray[0] connectedHost]);
    //NSLog(@"accept new client");
    //[clientTableView reloadData];
    
    // 如果下面的方法不写 只能接收一次socket链接
     
    [newSocket readDataWithTimeout:-1 tag:300];
     
}
// 网络连接成功后  自动回调
-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    if ([_mode isEqualToString:@"CLIENT"]) {
        //_socket = sock;
        NSString *msg=[NSString stringWithFormat:@"已连接到Server:ip:%@ port:%d",host,port];
        [self logUpdate:msg];
        // 继续读取socket数据
        [sock readDataWithTimeout:-1 tag:300];
        return;
    }
    NSString *msg=[NSString stringWithFormat:@"已连接到用户:ip:%@ port:%d",host,port];
    [self logUpdate:msg];
    //[sock readDataWithTimeout:-1 tag:300];
    //NSLog(@"已连接到用户:ip:%@",host);
}
-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    if([_mode isEqualToString:@"CLIENT"]){
        _READ_TIMOUT_FLAG=NO;
        NSString *message=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSString *msg=[NSString stringWithFormat:@"[RX]:%@",message];
        [self logUpdate:msg];
        // 继续读取socket数据
        [_clientsocket readDataWithTimeout:-1 tag:300];
        return;
    }
    NSString *message=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString *msg=[NSString stringWithFormat:@"收到%@发来的消息:%@",[sock connectedHost],message];
    [self logUpdate:msg];
    // 相当与向服务起索取  在线用户数据
    // 将连上服务器的所有ip地址 组成一个字符串 将字符串回写到客户端
    if ([message isEqualToString:@"GetClientList"]) {
        NSMutableString *clientList=[[NSMutableString alloc] initWithCapacity:0];
        int i=0;
        // 每一个客户端连接服务器成功后 socketArray保存客户端的套接字
        // [newSocket connectedHost] 获取套接字对应的IP地址
        for (GCDAsyncSocket *newSocket in socketArray) {
            // 以字符串形式分割ip地址  192..,192...,
            if (i!=0) {
                [clientList appendFormat:@",%@",[newSocket connectedHost]];
            }
            else{
                [clientList appendFormat:@"%@",[newSocket connectedHost]];
            }
            i++;
        }
        // 将服务端所有的ip连接成一个字符串对象
        NSData *newData=[clientList dataUsingEncoding:NSUTF8StringEncoding];
        // 将在线的所有用户  以字符串的形式一次性发给客户端
        // 哪个客户端发起数据请求sock就表示谁
        [sock writeData:newData withTimeout:-1 tag:300];
    }
    else if([message isEqualToString:@"Hello"]){
        // 将数据回写给发送数据的用户
        //NSString *msg=[NSString stringWithFormat:@"send >>>> %@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
        NSData *newData=[@"World!" dataUsingEncoding:NSUTF8StringEncoding];
        [self logUpdate:@"send >>>>World!"];
        [sock writeData:newData withTimeout:-1 tag:300];
    }
    else{
        NSData *newData=[@"Bad request!" dataUsingEncoding:NSUTF8StringEncoding];
        [self logUpdate:@"send >>>>Bad request!"];
        [sock writeData:newData withTimeout:-1 tag:300];
    }
    // 继续读取socket数据
    [sock readDataWithTimeout:-1 tag:300];
    
}

/*重连
 
 实现代理方法
 
 -(void)onSocketDidDisconnect:(GCDAsyncSocket *)sock
 {
     NSLog(@"sorry the connect is failure %@",sock.userData);
     if (sock.userData == SocketOfflineByServer) {
         // 服务器掉线，重连
         [self socketConnectHost];
     }
     else if (sock.userData == SocketOfflineByUser) {
         // 如果由用户断开，不进行重连
         return;
     }
 
 }
 */
// 连接断开时  服务器自动回调
-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err
{
    if ([_mode isEqualToString:@"CLIENT"] ) {
        
        [self logUpdate:@"[ERROR]****Disconnect****"];
        _clientsocket=nil;
        return;
    }
    NSString *msg=[NSString stringWithFormat:@"Client:%@ disconnect!",sock];
    [self logUpdate:msg];
    [socketArray removeObject:sock];
    //NSLog(@"Client offline");
    //[clientTableView reloadData];
    
}

// 向用户发出的消息  自动回调
-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    if ([_mode isEqualToString:@"CLIENT"]) {
        return;
    }
    //NSLog(@"向用户%@发出消息",[sock connectedHost]);
    NSString *msg=[NSString stringWithFormat:@"已向用户%@发出消息",[sock connectedHost]];
    [self logUpdate:msg];
}
/*
//read data timeout callback
- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length{
    [self logUpdate:@"[RX]Read data timeout!"];
    [sock readDataWithTimeout:-1 tag:300];
    return 0.05;
}

- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutWriteWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length{

    [self logUpdate:@"[TX]Send data timeout!"];
    return -1;
}
 */
- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}
-(void)logUpdate:(NSString *)log{
    [_lock lock];
    NSDateFormatter *dateFormat=[[NSDateFormatter alloc] init];
    [dateFormat setDateStyle:NSDateFormatterMediumStyle];
    [dateFormat setDateStyle:NSDateFormatterShortStyle];
    [dateFormat setDateFormat:@"[yyyy-MM-dd HH:mm:ss.SSS]"];
    
    NSString *dateText=[NSString string];
    dateText=[dateFormat stringFromDate:[NSDate date]];
    //dateText=[dateText stringByAppendingString:@"\n"];
    //_logString = [_logString stringByAppendingString:@"\r\n==============================\r\n"];
    _logString = [_logString stringByAppendingString:dateText];
    _logString = [_logString stringByAppendingString:log];
    _logString = [_logString stringByAppendingString:@"\r\n"];
    
    [self performSelectorOnMainThread:@selector(addLogOnMainThread) withObject:nil waitUntilDone:YES];
    //if([self._logString length] >10000) self._logString=@"";
    NSLog(@"%@",log);
    [_lock unlock];
}
-(void)addLogOnMainThread{
    [_logView setString:_logString];
    [_logView scrollRangeToVisible:NSMakeRange([[_logView textStorage] length],0)];
    [_logView setNeedsDisplay: YES];
}
-(void)windowShouldClose:(id)sender{
    NSLog(@"window should close...");
    [NSApp terminate:self];
}

@end
