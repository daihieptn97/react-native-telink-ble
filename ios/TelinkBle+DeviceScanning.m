//
//  TelinkBle+DeviceScanning.m
//  TelinkBle
//
//  Created by Thanh Tùng on 09/10/2021.
//  Copyright © 2021 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TelinkBle+DeviceScanning.h"

typedef enum : NSUInteger {
    AddStateScan,
    AddStateProvisioning,
    AddStateProvisionFail,
    AddStateKeybinding,
    AddStateKeybound,
    AddStateUnbound,
} AddState;
@interface AddDeviceStateModel : NSObject
@property (nonatomic,strong) CBPeripheral *peripheral;
@property (nonatomic,assign) AddState state;
@end


@implementation TelinkBle (DeviceScanning)

NSString* currentUuid = nil;
NSString* currentCommand = nil;
UInt16 currentProvisionAddressOther;
AddDeviceStateModel *model;

- (void)startAddingAllDevices
{
    __weak typeof(self) weakSelf = self;
    [SigBearer.share stopMeshConnectWithComplete:^(BOOL successful) {
        TeLogVerbose(@"successful=%d",successful);

        if (successful) {
            TeLogInfo(@"addDevice_stop mesh success.");
            
            NSTimer *t = [NSTimer scheduledTimerWithTimeInterval: 5.0
                                  target: self
                                  selector:@selector(addDeviceFinish)
                                  userInfo: nil
                                  repeats:NO];
            
            [SDKLibCommand scanUnprovisionedDevicesWithResult:^(CBPeripheral * _Nonnull peripheral, NSDictionary<NSString *,id> * _Nonnull advertisementData, NSNumber * _Nonnull RSSI, BOOL unprovisioned) {
                if (unprovisioned) {
                    model = [[AddDeviceStateModel alloc] init];
                    model.peripheral = peripheral;
                    model.state = AddStateScan;
                                        
                    if (peripheral) {
                        TeLogInfo(@"addDevice_model %@.", model);
                        [t invalidate];
                        [self onAddDevice];
                    }
                }
            }];
        } else {
            [weakSelf addDeviceFinish];
        }
    }];
}

- (void) onAddDevice
{
    __weak typeof(self) weakSelf = self;
    NSData *key = [SigDataSource.share curNetKey];
    
    if (model) {
        [SigBearer.share stopMeshConnectWithComplete:^(BOOL successful) {
            TeLogVerbose(@"successful=%d",successful);

            if (successful) {
                TeLogInfo(@"addDevice_stop mesh success onAddDevice.");
                
                NSOperationQueue *oprationQueue = [[NSOperationQueue alloc] init];
                [oprationQueue addOperationWithBlock:^{
                    
                    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
                    CBPeripheral *peripheral = model.peripheral;
                    UInt16 provisionAddress = [SigDataSource.share provisionAddress];
                    if (provisionAddress == 0) {
                        TeLogDebug(@"warning: address has run out.");
                        return;
                    }
                    NSNumber *type = [[NSUserDefaults standardUserDefaults] valueForKey:kKeyBindType];
                    model.state = AddStateProvisioning;
                    
                    SigScanRspModel *rspModel = [SigDataSource.share getScanRspModelWithUUID:peripheral.identifier.UUIDString];
                    SigOOBModel *oobModel = [SigDataSource.share getSigOOBModelWithUUID:rspModel.advUuid];
                    ProvisionTpye provisionType = ProvisionTpye_NoOOB;
                    NSData *staticOOBData = nil;
                    if (oobModel && oobModel.OOBString && oobModel.OOBString.length == 32) {
                        provisionType = ProvisionTpye_StaticOOB;
                        staticOOBData = [LibTools nsstringToHex:oobModel.OOBString];
                    }
                    
                    __block UInt16 currentProvisionAddress = provisionAddress;
                    __block NSString *currentAddUUID = nil;
                    
                    [SDKLibCommand
                     startAddDeviceWithNextAddress:provisionAddress
                     networkKey:key
                     netkeyIndex:SigDataSource.share.curNetkeyModel.index
                     appkeyModel:SigDataSource.share.curAppkeyModel
                     peripheral:peripheral
                     provisionType:provisionType
                     staticOOBData:staticOOBData
                     keyBindType:type.integerValue
                     productID:0
                     cpsData:nil
                     provisionSuccess:^(NSString * _Nonnull identify, UInt16 address) {
                        model.state = AddStateKeybinding;
                        if (identify && address != 0) {
                            currentAddUUID = identify;
                            currentUuid = identify;
                            [weakSelf updateDeviceProvisionSuccess:identify address:address];
                            TeLogInfo(@"addDevice_provision success : %@->0X%X",identify,address);
                        }
                        
                    } provisionFail:^(NSError * _Nonnull error) {
                        model.state = AddStateProvisionFail;
                        
                        [weakSelf updateDeviceProvisionFail:SigBearer.share.getCurrentPeripheral.identifier.UUIDString];
                        TeLogInfo(@"addDevice_provision fail error:%@",error);
                        
                        model = nil;
                        
                        [self startAddingAllDevices];
                    
                        dispatch_semaphore_signal(semaphore);
                    } keyBindSuccess:^(NSString * _Nonnull identify, UInt16 address) {
                        model.state = AddStateKeybound;
                        
                        if (identify && address != 0) {
                            [weakSelf updateDeviceKeyBind:currentAddUUID address:currentProvisionAddress isSuccess:YES];
                            TeLogInfo(@"addDevice_bind success : %@->0X%X",identify,address);
                        }
                        
                        dispatch_semaphore_signal(semaphore);
                    } keyBindFail:^(NSError * _Nonnull error) {
                        model.state = AddStateUnbound;
                        
                        [weakSelf updateDeviceKeyBind:currentAddUUID address:currentProvisionAddress isSuccess:NO];
                        TeLogInfo(@"addDevice_bind fail error:%@",error);
                        
                        model = nil;
                        
                        [self startAddingAllDevices];
                        
                        dispatch_semaphore_signal(semaphore);
                    }];
                    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

                }];

            } else {
                TeLogInfo(@"addDevice_stop mesh fail.");
            }
        }];
    }
}

- (void)updateDeviceProvisionSuccess:(NSString *)uuid address:(UInt16)address
{
    SigScanRspModel *scanModel = [SigDataSource.share getScanRspModelWithUUID:uuid];
    AddDeviceModel *model = [[AddDeviceModel alloc] init];
    if (scanModel == nil) {
        scanModel = [[SigScanRspModel alloc] init];
        scanModel.uuid = uuid;
    }
    model.scanRspModel = scanModel;
    model.scanRspModel.address = address;
    model.state = AddDeviceModelStateBinding;
    if (![self.source containsObject:model]) {
        [self.source addObject:model];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self sendEventWithName:EVENT_DEVICE_FOUND body:[self getJSModel:scanModel]];
    });
}

- (void)updateDeviceProvisionFail:(NSString *)uuid {
    SigScanRspModel *scanModel = [SigDataSource.share getScanRspModelWithUUID:uuid];
    AddDeviceModel *model = [[AddDeviceModel alloc] init];
    if (scanModel == nil) {
        scanModel = [[SigScanRspModel alloc] init];
        scanModel.uuid = uuid;
    }
    model.scanRspModel = scanModel;
    model.state = AddDeviceModelStateProvisionFail;
    if (![self.source containsObject:model]) {
        [self.source addObject:model];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self sendEventWithName:EVENT_PROVISIONING_FAILED body:[self getJSModel:scanModel]];
    });
}

- (void)updateDeviceKeyBind:(NSString *)uuid address:(UInt16)address isSuccess:(BOOL)isSuccess{
    NSArray *source = [NSArray arrayWithArray:self.source];
    for (AddDeviceModel *model in source) {
        if ([model.scanRspModel.uuid isEqualToString:uuid] || model.scanRspModel.address == address) {
            if (isSuccess) {
                model.state = AddDeviceModelStateBindSuccess;

            } else {
                model.state = AddDeviceModelStateBindFail;
            }
            break;
        }
    }
    TeLog("addDevice_bind u go here");
    SigScanRspModel *scanModel = [SigDataSource.share getScanRspModelWithUUID:uuid];
    AddDeviceModel *model = [[AddDeviceModel alloc] init];
    
    scanModel.uuid = uuid;
    
    model.scanRspModel = scanModel;
    model.scanRspModel.address = address;
    model.state = AddDeviceModelStateBinding;
    if (![self.source containsObject:model]) {
        [self.source addObject:model];
    }
    if (isSuccess) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self sendEventWithName:EVENT_BINDING_SUCCESS body:[self getJSModel:scanModel]];
        });
        model = nil;
        [self startAddingAllDevices];
        
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self sendEventWithName:EVENT_BINDING_FAILED body:[self getJSModel:scanModel]];
        });
    }
}

- (void)addDeviceFinish {
    dispatch_async(dispatch_get_main_queue(), ^{
        TeLogInfo(@"addDevice_finish.");
        [SigBearer.share startMeshConnectWithComplete:nil];
        [self sendEventWithName:EVENT_SCANNING_TIMEOUT body:nil];
    });
}

@end
