//
//  MQTTClientTests.m
//  MQTTClientTests
//
//  Created by Christoph Krey on 13.01.14.
//  Copyright © 2014-2018 Christoph Krey. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MQTTLog.h"
#import "MQTTTestHelpers.h"

@interface MQTTClientOnlyTests : MQTTTestHelpers
@end

@implementation MQTTClientOnlyTests

- (void)tearDown {
    [self.session closeWithReturnCode:MQTTSuccess
                sessionExpiryInterval:nil
                         reasonString:nil
                       userProperties:nil
                    disconnectHandler:nil];
    self.session.delegate = nil;
    self.session = nil;

    [super tearDown];
}

- (void)test_connect_host_not_found {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSMutableDictionary *parameters = [self.brokers[broker] mutableCopy];
        
        parameters[@"host"] = @"abc";
        self.session = [MQTTTestHelpers session:parameters];
        self.session.delegate = self;
        self.event = -1;
        [self.session connectWithConnectHandler:nil];
        while (self.event == -1) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventConnected, @"MQTTSessionEventConnected %@", self.error);
        XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventConnectionRefused, @"MQTTSessionEventConnectionRefused %@", self.error);
        XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventProtocolError, @"MQTTSessionEventProtocolError %@", self.error);
    }
}


- (void)test_connect_1889 {
    for (NSString *broker in self.brokers.allKeys) {
        DDLogVerbose(@"testing broker %@", broker);
        NSMutableDictionary *parameters = [self.brokers[broker] mutableCopy];
        
        parameters[@"port"] = @1889;

        self.session = [MQTTTestHelpers session:parameters];
        self.session.delegate = self;
        self.event = -1;
        [self.session connectWithConnectHandler:nil];
        while (self.event == -1) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventConnected, @"MQTTSessionEventConnected %@", self.error);
        XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventConnectionRefused, @"MQTTSessionEventConnectionRefused %@", self.error);
        XCTAssertNotEqual(self.event, (NSInteger)MQTTSessionEventProtocolError, @"MQTTSessionEventProtocolErrorr %@", self.error);
    }
}

@end
