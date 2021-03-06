//
//  UDPConnection.m
//  DinoLasers
//
//  Created by Paul Mans on 11/27/12.
//  Copyright (c) 2012 DinoLasers. All rights reserved.
//

#import "UDPConnection.h"
#import <ifaddrs.h>
#import <arpa/inet.h>


@interface UDPConnection () {

}

@property (readwrite, strong, nonatomic) __attribute__((NSObject)) dispatch_queue_t queue;

@end

@implementation UDPConnection
@synthesize udpSocket;
@synthesize socketHost;
@synthesize hostPort;
@synthesize localPort;
@synthesize queue=_queue;
@synthesize delegate;

- (id)init {
    if ((self = [super init])) {
        self.hostPort = DEFAULT_HOST_PORT;
        self.localPort = DEFAULT_LOCAL_PORT;
        self.socketHost = DEFAULT_HOST;
        
        // create a high priority dispatch queue so we don't send on the main thread
        self.queue = dispatch_queue_create("org.dinolasers.udpqueue", 0);
        dispatch_queue_t high = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        dispatch_set_target_queue(self.queue,high);
        
    }
    return self;
}

- (void)setupSocket {

	self.udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:self.queue];
	
	NSError *error = nil;
	
	if (![udpSocket bindToPort:self.localPort error:&error]) {
		NSLog(@"Error binding: %@", error);
		return;
	}
    
	if (![udpSocket beginReceiving:&error]) {
		NSLog(@"Error receiving: %@", error);
		return;
	}    
}

- (void)close {
    [self.udpSocket close];
}

#pragma mark - Sending data

- (void)sendData:(NSData *)data toHost:(NSString *)host port:(int)port withTimeout:(int)timeout tag:(long)tag {
    [self.udpSocket sendData:data toHost:host port:port withTimeout:timeout tag:tag];
}

- (void)sendMessage:(NSString *)message withTag:(long)tag {
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    [self sendData:data toHost:self.socketHost port:self.hostPort withTimeout:-1 tag:tag];
}

#pragma mark - GCDAsyncUdpSocketDelegate

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag {
	
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error {
	NSLog(@"Failed to send data with tag: %ld due to error: %@", tag, error);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext {
    
    NSString *host = nil;
    uint16_t port = 0;
    [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
    
	NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if (msg) {
        if (delegate) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate UDPConnection:self.delegate didReceiveMessage:msg fromHost:host onPort:port];
            });
        } else {
            NSLog(@"RECV: %@", msg);
        }
	} else {
		NSString *host = nil;
		uint16_t port = 0;
		[GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
		
		NSLog(@"RECV: Unknown message from: %@:%hu", host, port);
	}
}


// Get IP Address
+ (NSString *)getIPAddress {
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
    
}


@end
