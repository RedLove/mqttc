//
//  MQTTTestWebsockets.m
//  MQTTClient
//
//  Created by Christoph Krey on 05.12.15.
//  Copyright © 2015-2019 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MQTTLog.h"
#import "MQTTTestHelpers.h"
#import <SocketRocket/SRWebSocket.h>
#import "MQTTWebsocketTransport.h"

@interface MQTTTestWebsockets : MQTTTestHelpers <SRWebSocketDelegate>
@property (strong, nonatomic) SRWebSocket *websocket;
@property (nonatomic) BOOL next;
@property (nonatomic) BOOL abort;
@end

@implementation MQTTTestWebsockets

- (void)testWSTRANSPORT {
    if ([self.parameters[@"websocket"] boolValue]) {

        MQTTWebsocketTransport *wsTransport = [[MQTTWebsocketTransport alloc] init];
        wsTransport.host = self.parameters[@"host"];
        wsTransport.port = [self.parameters[@"port"] intValue];
        wsTransport.tls = [self.parameters[@"tls"] boolValue];

        self.session = [[MQTTSession alloc] init];
        self.session.transport = wsTransport;

        self.session.delegate = self;

        self.event = -1;
        self.timedout = FALSE;
        [self performSelector:@selector(timedout:)
                   withObject:nil
                   afterDelay:[self.parameters[@"timeout"] intValue]];

        [self.session connectWithConnectHandler:nil];

        while (!self.timedout && self.event == -1) {
            DDLogVerbose(@"waiting for connection");
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        [NSObject cancelPreviousPerformRequestsWithTarget:self];


        XCTAssert(!self.timedout, @"timeout");
        XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);


        self.event = -1;
        self.timedout = FALSE;
        [self performSelector:@selector(timedout:)
                   withObject:nil
                   afterDelay:[self.parameters[@"timeout"] intValue]];

        [self.session closeWithReturnCode:0
                    sessionExpiryInterval:nil
                             reasonString:nil
                           userProperties:nil
                        disconnectHandler:nil];

        while (!self.timedout && self.event == -1) {
            DDLogVerbose(@"waiting for disconnect");
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        [NSObject cancelPreviousPerformRequestsWithTarget:self];

        XCTAssert(!self.timedout, @"timeout");
    }
}

- (void)testWSConnect {
    if ([self.parameters[@"websocket"] boolValue]) {
        
        if (!self.parameters[@"serverCER"] && !self.parameters[@"clientp12"]) {
            
            MQTTWebsocketTransport *wsTransport = [[MQTTWebsocketTransport alloc] init];
            wsTransport.host = self.parameters[@"host"];
            wsTransport.port = [self.parameters[@"port"] intValue];
            wsTransport.tls = [self.parameters[@"tls"] boolValue];
            
            self.session = [[MQTTSession alloc] init];
            self.session.transport = wsTransport;
            [self connect:self.session parameters:self.parameters];
            [self shutdown:self.parameters];
        }
    }
}

- (void)testWSSubscribe {
        if ([self.parameters[@"websocket"] boolValue]) {
            
            if (!self.parameters[@"serverCER"] && !self.parameters[@"clientp12"]) {
                
                MQTTWebsocketTransport *wsTransport = [[MQTTWebsocketTransport alloc] init];
                wsTransport.host = self.parameters[@"host"];
                wsTransport.port = [self.parameters[@"port"] intValue];
                wsTransport.tls = [self.parameters[@"tls"] boolValue];
                
                self.session = [[MQTTSession alloc] init];
                self.session.transport = wsTransport;
                self.session.userName = self.parameters[@"user"];
                self.session.password = self.parameters[@"pass"];
                [self connect:self.session parameters:self.parameters];
                XCTAssert(!self.timedout, @"timeout");
                XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
                
                self.timedout = FALSE;
                [self performSelector:@selector(timedout:)
                           withObject:nil
                           afterDelay:[self.parameters[@"timeout"] intValue]];

                [self.session subscribeToTopicV5:@"$SYS/#"
                                         atLevel:MQTTQosLevelAtLeastOnce
                                         noLocal:false
                               retainAsPublished:false
                                  retainHandling:MQTTSendRetained
                          subscriptionIdentifier:0
                                  userProperties:nil
                                subscribeHandler:nil];

                [self.session subscribeToTopicV5:@"#"
                                         atLevel:MQTTQosLevelAtLeastOnce
                                         noLocal:false
                               retainAsPublished:false
                                  retainHandling:MQTTSendRetained
                          subscriptionIdentifier:0
                                  userProperties:nil
                                subscribeHandler:nil];

                while (!self.timedout) {
                    DDLogVerbose(@"looping for messages");
                    [self.session publishDataV5:[[NSDate date].description dataUsingEncoding:NSUTF8StringEncoding]
                                        onTopic:@"MQTTClient"
                                         retain:false
                                            qos:MQTTQosLevelAtLeastOnce
                         payloadFormatIndicator:nil
                          messageExpiryInterval:nil
                                     topicAlias:nil
                                  responseTopic:nil
                                correlationData:nil
                                 userProperties:nil
                                    contentType:nil
                                 publishHandler:nil];

                    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
                }
                
                [NSObject cancelPreviousPerformRequestsWithTarget:self];
                XCTAssert(self.timedout, @"timeout");
                
                
                [self shutdown:self.parameters];
            }
        }
}


- (void)testWSSubscribeLong {
        if ([self.parameters[@"websocket"] boolValue]) {
            
            if (!self.parameters[@"serverCER"] && !self.parameters[@"clientp12"]) {
                
                MQTTWebsocketTransport *wsTransport = [[MQTTWebsocketTransport alloc] init];
                wsTransport.host = self.parameters[@"host"];
                wsTransport.port = [self.parameters[@"port"] intValue];
                wsTransport.tls = [self.parameters[@"tls"] boolValue];
                
                self.session = [[MQTTSession alloc] init];
                self.session.transport = wsTransport;
                self.session.userName = self.parameters[@"user"];
                self.session.password = self.parameters[@"pass"];
                [self connect:self.session parameters:self.parameters];
                XCTAssert(!self.timedout, @"timeout");
                XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
                
                self.timedout = FALSE;
                [self performSelector:@selector(timedout:)
                           withObject:nil
                           afterDelay:[self.parameters[@"timeout"] intValue]];

                [self.session subscribeToTopicV5:@"MQTTClient"
                                         atLevel:MQTTQosLevelAtLeastOnce
                                         noLocal:false
                               retainAsPublished:false
                                  retainHandling:MQTTSendRetained
                          subscriptionIdentifier:0
                                  userProperties:nil
                                subscribeHandler:nil];

                NSString *payload = @"abcdefgh";
                
                while (!self.timedout && strlen([payload substringFromIndex:1].UTF8String) <= 1000) {
                    DDLogVerbose(@"looping for messages");
                    [self.session publishDataV5:[payload dataUsingEncoding:NSUTF8StringEncoding]
                                        onTopic:@"MQTTClient"
                                         retain:false
                                            qos:MQTTQosLevelAtLeastOnce
                         payloadFormatIndicator:nil
                          messageExpiryInterval:nil
                                     topicAlias:nil
                                  responseTopic:nil
                                correlationData:nil
                                 userProperties:nil
                                    contentType:nil
                                 publishHandler:nil];

                    payload = [payload stringByAppendingString:payload];
                    payload = [payload stringByAppendingString:payload];
                    
                    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
                }
                
                [NSObject cancelPreviousPerformRequestsWithTarget:self];
                
                [self shutdown:self.parameters];
            }
        }
}


- (void)webSocket:(SRWebSocket *)webSocket
didReceiveMessage:(id)message {
    NSData *data = (NSData *)message;
    DDLogVerbose(@"webSocket didReceiveMessage %ld", (unsigned long)data.length);
    self.next = true;
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket{
    DDLogVerbose(@"webSocketDidOpen");
}

- (void)webSocket:(SRWebSocket *)webSocket
 didFailWithError:(NSError *)error{
    DDLogVerbose(@"webSocket didFailWithError: %@", [error debugDescription]);
    self.abort = true;
}

- (void)webSocket:(SRWebSocket *)webSocket
 didCloseWithCode:(NSInteger)code
           reason:(NSString *)reason
         wasClean:(BOOL)wasClean {
    DDLogVerbose(@"webSocket didCloseWithCode: %ld %@ %d",
                 (long)code, reason, wasClean);
    self.next = true;
}

- (void)webSocket:(SRWebSocket *)webSocket
   didReceivePong:(NSData *)pongPayload {
    DDLogVerbose(@"webSocket didReceivePong: %@",
                 pongPayload);
}

- (void)connect:(MQTTSession *)session parameters:(NSDictionary *)parameters{
    self.session.delegate = self;
    self.session.userName = parameters[@"user"];
    self.session.password = parameters[@"pass"];
    
    self.event = -1;
    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:[parameters[@"timeout"] intValue]];
    
    [self.session connectWithConnectHandler:nil];
    
    while (!self.timedout && self.event == -1) {
        DDLogVerbose(@"waiting for connection");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    XCTAssert(!self.timedout, @"timeout");
    XCTAssertEqual(self.event, MQTTSessionEventConnected, @"Not Connected %ld %@", (long)self.event, self.error);
}

- (void)shutdown:(NSDictionary *)parameters {
    self.event = -1;
    self.timedout = FALSE;
    [self performSelector:@selector(timedout:)
               withObject:nil
               afterDelay:[parameters[@"timeout"] intValue]];
    
    [self.session closeWithReturnCode:0
                sessionExpiryInterval:nil
                         reasonString:nil
                       userProperties:nil
                    disconnectHandler:nil];
    
    while (!self.timedout && self.event == -1) {
        DDLogVerbose(@"waiting for disconnect");
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    XCTAssert(!self.timedout, @"timeout");

    self.session.delegate = nil;
    self.session = nil;
}



@end
