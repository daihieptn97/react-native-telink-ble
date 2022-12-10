//
//  TelinkBle+MeshSDK.m
//  TelinkBle
//
//  Created by Thanh Tùng on 02/10/2021.
//  Copyright © 2021 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TelinkSigMeshLib/TelinkSigMeshLib.h>
#import "TelinkBle+MeshSDK.h"

@implementation TelinkBle (MeshSDK)

+ (void)startMeshSDK
{
    // demo v2.8.0 adds a new quick add mode, the demo uses the normal add mode by default.
    NSNumber *type = [[NSUserDefaults standardUserDefaults] valueForKey:kKeyBindType];
    if (type == nil) {
        type = [NSNumber numberWithInteger:KeyBindTpye_Normal];
        [[NSUserDefaults standardUserDefaults] setValue:type forKey:kKeyBindType];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    // demo v2.8.0 adds remote addition mode, demo uses normal addition mode by default.
    NSNumber *remoteType = [[NSUserDefaults standardUserDefaults] valueForKey:kRemoteAddType];
    if (remoteType == nil) {
        remoteType = [NSNumber numberWithBool:NO];
        [[NSUserDefaults standardUserDefaults] setValue:remoteType forKey:kRemoteAddType];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    // demo v2.8.1 adds private customization getOnlinestatus, demo uses private customization to obtain status by default.
    NSNumber *onlineType = [[NSUserDefaults standardUserDefaults] valueForKey:kGetOnlineStatusType];
    if (onlineType == nil) {
        onlineType = [NSNumber numberWithBool:YES];
        [[NSUserDefaults standardUserDefaults] setValue:onlineType forKey:kGetOnlineStatusType];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    // demo v3.0.0 adds fast provision add mode, demo uses normal add mode by default.
    NSNumber *fastAddType = [[NSUserDefaults standardUserDefaults] valueForKey:kFastAddType];
    if (fastAddType == nil) {
        fastAddType = [NSNumber numberWithBool:NO];
        [[NSUserDefaults standardUserDefaults] setValue:fastAddType forKey:kFastAddType];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    // demo v3.2.2 adds the compatibility mode added by staticOOB devices, and the demo uses the compatibility mode by default.
    // (The compatibility mode is that staticOOB devices can be added through noOOB provision without OOB data;
    // the incompatible mode is that staticOOB devices must be added through staticOOB provision).
    NSNumber *addStaticOOBDevcieByNoOOBEnable = [[NSUserDefaults standardUserDefaults] valueForKey:kAddStaticOOBDevcieByNoOOBEnable];
    if (addStaticOOBDevcieByNoOOBEnable == nil) {
        addStaticOOBDevcieByNoOOBEnable = [NSNumber numberWithBool:YES];
        [[NSUserDefaults standardUserDefaults] setValue:addStaticOOBDevcieByNoOOBEnable forKey:kAddStaticOOBDevcieByNoOOBEnable];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    SigDataSource.share.addStaticOOBDevcieByNoOOBEnable = addStaticOOBDevcieByNoOOBEnable.boolValue;
    // demo v3.3.0 adds DLE mode, the demo turns off DLE mode by default. (Customized function)
    NSNumber *DLEType = [[NSUserDefaults standardUserDefaults] valueForKey:kDLEType];
    if (DLEType == nil) {
        DLEType = [NSNumber numberWithBool:NO];
        [[NSUserDefaults standardUserDefaults] setValue:DLEType forKey:kDLEType];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        if (DLEType.boolValue) {
            // (Optional) After turning on the DLE function, the SDK Access message is segmented only if the length is greater than 229 bytes.
            SigDataSource.share.defaultUnsegmentedMessageLowerTransportPDUMaxLength = kDLEUnsegmentLength;
        }
    }
    
    /**
     Initialize SDK
     */
    
    // 1. The address range allocated by a provisioner, the default is 0x400.
    SigDataSource.share.defaultAllocatedUnicastRangeHighAddress = kAllocatedUnicastRangeHighAddress;
    // 2. The sequenceNumber step size of the mesh network, the default is 128.
    //    SigDataSource.share.defaultSnoIncrement = kSnoIncrement;
    SigDataSource.share.defaultSnoIncrement = 16;
    // 3. Start the SDK.
    [SDKLibCommand startMeshSDK];
    // (Optional) The SDK group is bound to 5 modelIDs by default,
    // and the modelIDs bound to the group by default can be modified through the following interface
    SigDataSource.share.defaultGroupSubscriptionModels = [NSMutableArray arrayWithArray:@[
        @(kSigModel_GenericOnOffServer_ID),
        @(kSigModel_LightLightnessServer_ID),
        @(kSigModel_LightCTLServer_ID),
        @(kSigModel_LightCTLTemperatureServer_ID),
        @(kSigModel_LightCTLClient_ID),
        @(kSigModel_LightHSLServer_ID),
        @(kSigModel_LightHSLClient_ID),
        @(kSigModel_SceneServer_ID),
        @(kSigModel_SceneClient_ID),
    ]];
    
    SigMeshLib.share.transmissionTimerInteral = 0.500;
    // SigDataSource.share.needPublishTimeModel = NO;
#if DEBUG
    [SigLogger.share setSDKLogLevel:SigLogLevelDebug];
#else
    [SigLogger.share setSDKLogLevel:SigLogLevelWarning];
#endif
}

@end
