//
//  TelinkBle.h
//  TelinkBle
//
//  Created by Thanh Tùng on 01/10/2021.
//  Copyright © 2021 Facebook. All rights reserved.
//

#ifndef TelinkBle_h
#define TelinkBle_h

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <TelinkSigMeshLib/TelinkSigMeshLib.h>

#define EVENT_MESH_NETWORK_CONNECTION       @"EVENT_MESH_NETWORK_CONNECTION"
#define EVENT_DEVICE_FOUND                  @"EVENT_DEVICE_FOUND"
#define EVENT_SCANNING_TIMEOUT              @"EVENT_SCANNING_TIMEOUT"
#define EVENT_NEW_DEVICE_ADDED              @"EVENT_NEW_DEVICE_ADDED"
#define EVENT_PROVISIONING_SUCCESS          @"EVENT_PROVISIONING_SUCCESS"
#define EVENT_PROVISIONING_FAILED           @"EVENT_PROVISIONING_FAILED"
#define EVENT_BINDING_SUCCESS               @"EVENT_BINDING_SUCCESS"
#define EVENT_BINDING_FAILED                @"EVENT_BINDING_FAILED"

#define EVENT_TYPE_OTA_PROGRESS             @"EVENT_TYPE_OTA_PROGRESS"
#define EVENT_TYPE_OTA_FAIL                 @"EVENT_TYPE_OTA_FAIL"
#define EVENT_TYPE_OTA_SUCCESS              @"EVENT_TYPE_OTA_SUCCESS"

#define EVENT_SET_GROUP_SUCCESS             @"EVENT_SET_GROUP_SUCCESS"
#define EVENT_SET_GROUP_FAILED              @"EVENT_SET_GROUP_FAILED"

#define EVENT_SET_SCENE_SUCCESS             @"EVENT_SET_SCENE_SUCCESS"
#define EVENT_SET_SCENE_FAILED              @"EVENT_SET_SCENE_FAILED"

#define EVENT_DEVICE_STATUS                 @"EVENT_DEVICE_STATUS"
#define EVENT_DEVICE_ONLINE                 @"EVENT_DEVICE_ONLINE"

#define EVENT_TYPE_NOTIFICATION_MESSAGE_UNKNOWN                 @"EVENT_TYPE_NOTIFICATION_MESSAGE_UNKNOWN"

#define EVENT_NODE_RESET_SUCCESS            @"EVENT_NODE_RESET_SUCCESS"
#define EVENT_NODE_RESET_FAILED             @"EVENT_NODE_RESET_FAILED"

#define ERROR_SHARE_IMAGE_FAILED            @"ERROR_SHARE_IMAGE_FAILED"

#define kShareWithBluetoothPointToPoint (YES)
#define kShowScenes                     (YES)
#define kShowDebug                      (NO)
#define kshowLog                        (YES)
#define kshowShare                      (YES)
#define kshowMeshInfo                   (YES)
#define kshowChooseAdd                  (YES)

#define kKeyBindType                        @"kKeyBindType"
#define kRemoteAddType                      @"kRemoteAddType"
#define kFastAddType                        @"kFastAddType"
#define kDLEType                            @"kDLEType"
#define kGetOnlineStatusType                @"kGetOnlineStatusType"
#define kAddStaticOOBDevcieByNoOOBEnable    @"kAddStaticOOBDevcieByNoOOBEnable"
#define KeyBindType                         @"kKeyBindType"
#define kDLEUnsegmentLength                 (229)

@interface TelinkBle : RCTEventEmitter<RCTBridgeModule, SigMessageDelegate>

@property(strong, nonatomic) NSMutableArray<AddDeviceModel *> *_Nonnull source;

- (NSDictionary* _Nullable)getJSModel:(SigScanRspModel* _Nonnull)scanModel;

@end

#endif /* TelinkBle_h */
