//
//  TelinkBle+SigMeshDelegate.m
//  TelinkBle
//
//  Created by Thanh Tùng on 09/10/2021.
//  Copyright © 2021 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TelinkBle+SigMessageDelegate.h"

@implementation TelinkBle (SigMessageDelegate)

- (NSString* _Nullable)getUUIDFromMeshAddress:(UInt16)meshAddress
{
    for (SigNodeModel* node in SigDataSource.share.curNodes)
    {
        if (node.address == meshAddress) {
            return node.UUID;
        }
    }
    return nil;
}

- (void)didReceiveMessage:(SigMeshMessage *)message sentFromSource:(UInt16)source toDestination:(UInt16)destination
{
    if ([message isKindOfClass:[SigTelinkOnlineStatusMessage class]])
    {
        SigTelinkOnlineStatusMessage* msg = (SigTelinkOnlineStatusMessage*) message;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self sendEventWithName:EVENT_DEVICE_STATUS body:@{
                @"uuid": [self getUUIDFromMeshAddress:source],
                @"meshAddress": [NSNumber numberWithUnsignedShort:source],
                @"online": [NSNumber numberWithBool:msg.state],
            }];
        });
    }
    
    if ([message isKindOfClass:[SigLightHSLStatus class]])
    {
        SigLightHSLStatus* msg = (SigLightHSLStatus*) message;
        double hue        = (double) msg.HSLHue        / 0xFFFF * 360;
        double saturation = (double) msg.HSLSaturation / 0xFFFF * 100;
        double lightness  = (double) msg.HSLLightness  / 0xFFFF * 100;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self sendEventWithName:EVENT_DEVICE_STATUS body:@{
                @"uuid": [self getUUIDFromMeshAddress:source],
                @"meshAddress": [NSNumber numberWithUnsignedShort:source],
                @"hsl": @{
                    @"hue": [NSNumber numberWithDouble:hue],
                    @"saturation": [NSNumber numberWithDouble:saturation],
                    @"lightness": [NSNumber numberWithDouble:lightness],
                },
            }];
        });
        return;
    }
    
    UInt32 opCode = message.opCode;
    NSData* params = message.parameters;
    NSString* uuid = [self getUUIDFromMeshAddress:source];
    
    switch (opCode) {
        case 0x8260: {
            NSInteger brightness;
            NSInteger temperature;
            [params getBytes:&brightness range:NSMakeRange(0, 2)];
            [params getBytes:&temperature range:NSMakeRange(2, 2)];
            if (uuid) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self sendEventWithName:EVENT_DEVICE_STATUS body:@{
                        @"status": [NSNumber numberWithBool:(brightness > 0)],
                        @"brightness": [NSNumber numberWithUnsignedInt:[LibTools lightnessToLum:brightness]],
                        @"temperature": [NSNumber numberWithUnsignedInt:[LibTools tempToTemp100:temperature]],
                        @"meshAddress": [NSNumber numberWithUnsignedShort:source],
                        @"uuid": uuid,
                    }];
                });
            }
            return;
            break;
        }
            
            
        case 0x52:
        case 0xE31102:{
            if (uuid) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self sendEventWithName:EVENT_TYPE_NOTIFICATION_MESSAGE_UNKNOWN body:@{
                        @"destination": [NSNumber numberWithUnsignedShort:destination],
                        @"source": [NSNumber numberWithUnsignedShort:source],
                        @"params": [LibTools convertDataToHexStr:params],
                        @"opcode": [NSNumber numberWithUnsignedShort:opCode],
                    }];
                });
            }
            return;
            break;
        }
            
        default: {
            break;
        }
            
    }
}

- (void)didSendMessage:(SigMeshMessage *)message fromLocalElement:(SigElementModel *)localElement toDestination:(UInt16)destination
{
    NSLog(@"Sent message to %d with opcode %d", destination, message.opCode);
}

- (void)failedToSendMessage:(SigMeshMessage *)message fromLocalElement:(SigElementModel *)localElement toDestination:(UInt16)destination error:(NSError *)error
{
    NSLog(@"Failed to send message to %d with opcode %d", destination, message.opCode);
}

- (void)didReceiveSigProxyConfigurationMessage:(SigProxyConfigurationMessage *)message sentFromSource:(UInt16)source toDestination:(UInt16)destination
{
    NSLog(@"Received SigProxyConfigurationMessage with opcode %d", message.opCode);
}

@end
